import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  String? _userRole;
  bool _isLoading = false;

  User? get user => _user;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;
    if (_user != null) {
      try {
        final doc = await _db.collection('users').doc(_user!.uid).get();
        _userRole = doc.data()?['role'] as String?;
        _userRole ??= _inferRoleFromEmail(_user!.email);
      } catch (_) {
        _userRole = _inferRoleFromEmail(_user!.email);
      }
    } else {
      _userRole = null;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await loginWithEmail(email: email, password: password);
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? profile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email.trim(),
        'role': role,
        'profile': profile ?? <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _userRole = role;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithRoleIdentifier({
    required String identifier,
    required String password,
    required String expectedRole,
  }) async {
    final normalizedEmail = _normalizeIdentifierToEmail(identifier);
    await loginWithEmail(email: normalizedEmail, password: password);

    final role = await _resolveRoleAndBackfill(expectedRole: expectedRole);
    if (role != expectedRole) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'invalid-role',
        message: 'Account does not have $expectedRole access.',
      );
    }
  }

  Future<void> loginWithPhonePin({
    required String phone,
    required String pin,
    required String expectedRole,
  }) async {
    final email = _phoneToEmail(phone, expectedRole);
    final password = _pinToPassword(pin);
    await loginWithEmail(email: email, password: password);

    final role = await _resolveRoleAndBackfill(expectedRole: expectedRole);
    if (role != expectedRole) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'invalid-role',
        message: 'Account does not have $expectedRole access.',
      );
    }
  }

  Future<void> registerWithPhonePin({
    required String phone,
    required String pin,
    required String role,
    Map<String, dynamic>? profile,
  }) async {
    final email = _phoneToEmail(phone, role);
    final password = _pinToPassword(pin);
    await registerWithEmail(
      email: email,
      password: password,
      role: role,
      profile: {'phone': phone.trim(), ...?profile},
    );
  }

  Future<void> signInWithGoogle({
    required String expectedRole,
    Map<String, dynamic>? profile,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;
      final userDoc = _db.collection('users').doc(uid);
      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        final existingRole = snapshot.data()?['role'] as String?;
        if (existingRole != null && existingRole != expectedRole) {
          await _auth.signOut();
          await _googleSignIn.signOut();
          throw FirebaseAuthException(
            code: 'invalid-role',
            message: 'Google account already linked to role: $existingRole',
          );
        }
      }

      await userDoc.set({
        'email': userCredential.user!.email,
        'displayName': userCredential.user!.displayName,
        'photoUrl': userCredential.user!.photoURL,
        'role': expectedRole,
        'profile': profile ?? <String, dynamic>{},
        'updatedAt': FieldValue.serverTimestamp(),
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _userRole = expectedRole;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _normalizeIdentifierToEmail(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('@')) {
      return normalized;
    }
    return '$normalized@navjeevan.app';
  }

  String _phoneToEmail(String phone, String role) {
    final normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$role.$normalized@navjeevan.app';
  }

  String _pinToPassword(String pin) {
    return 'nvj-$pin-secure';
  }

  Future<String?> _resolveRoleAndBackfill({String? expectedRole}) async {
    final current = _auth.currentUser;
    if (current == null) return null;

    final userDocRef = _db.collection('users').doc(current.uid);

    String? resolvedRole = _userRole;
    if (resolvedRole == null) {
      try {
        final snapshot = await userDocRef.get();
        resolvedRole = snapshot.data()?['role'] as String?;
      } catch (_) {}
    }

    resolvedRole ??= _inferRoleFromEmail(current.email);
    resolvedRole ??= expectedRole;

    if (resolvedRole != null) {
      _userRole = resolvedRole;
      try {
        await userDocRef.set({
          'email': current.email,
          'displayName': current.displayName,
          'photoUrl': current.photoURL,
          'role': resolvedRole,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    return resolvedRole;
  }

  String? _inferRoleFromEmail(String? email) {
    if (email == null) {
      return null;
    }
    final normalized = email.toLowerCase();
    if (normalized.contains('admin')) {
      return 'admin';
    }
    if (normalized.contains('agency') || normalized.contains('ngo')) {
      return 'agency';
    }
    if (normalized.contains('parent')) {
      return 'parent';
    }
    if (normalized.contains('mother')) {
      return 'mother';
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Helper for demo/testing
  void setGuestRole(String role) {
    _userRole = role;
    notifyListeners();
  }
}
