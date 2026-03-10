import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Auth & User Profile ---

  User? get currentUser => _auth.currentUser;

  Future<void> createUserProfile({
    required String uid,
    required String role,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set({
      'role': role,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      ...data,
    });
  }

  // --- Mother Pillar: Help Requests ---

  Future<void> submitMotherRequest({
    required List<String> reasons,
    required bool needsCounseling,
    required bool isAnonymous,
    required String region,
  }) async {
    // Basic Risk Calculation (Logic can be expanded)
    String riskLevel = 'Low';
    if (reasons.length > 2 || region == 'Hadapsar') {
      riskLevel = 'High';
    } else if (reasons.isNotEmpty) {
      riskLevel = 'Medium';
    }

    await _db.collection('mother_requests').add({
      'reasons': reasons,
      'needsCounseling': needsCounseling,
      'isAnonymous': isAnonymous,
      'region': region,
      'riskLevel': riskLevel,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Parent Pillar: Adoption Applications ---

  Future<void> submitAdoptionApplication({
    required String familyName,
    required String region,
    required double annualIncome,
    required Map<String, String> documentPaths,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    // Upload documents first
    Map<String, String> documentUrls = {};
    for (var entry in documentPaths.entries) {
      final url = await uploadDocument(entry.value, entry.key);
      documentUrls[entry.key] = url;
    }

    await _db.collection('adoptive_families').doc(uid).set({
      'userId': uid,
      'familyName': familyName,
      'region': region,
      'annualIncome': annualIncome,
      'incomeLevel': annualIncome > 1000000
          ? 'High'
          : (annualIncome > 500000 ? 'Medium' : 'Low'),
      'homeVerified': false,
      'backgroundCheck': 'Pending',
      'adoptionStatus': 'Under Review',
      'documents': documentUrls,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Counselor Assignments & Availability ---

  /// Assign a counselor to a support request
  Future<String> assignCounselorToRequest({
    required String counselorName,
    required String counselorEmail,
    required String requestId,
    required String userId,
    required String requestType, // 'mother' or 'parent'
  }) async {
    final assignmentRef = _db.collection('counselor_assignments').doc();

    await assignmentRef.set({
      'assignmentId': assignmentRef.id,
      'counselorName': counselorName,
      'counselorEmail': counselorEmail,
      'requestId': requestId,
      'userId': userId,
      'requestType': requestType,
      'status': 'Active',
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return assignmentRef.id;
  }

  /// Get counselor assigned to a specific request
  Future<Map<String, dynamic>?> getAssignedCounselor(String requestId) async {
    final snapshot = await _db
        .collection('counselor_assignments')
        .where('requestId', isEqualTo: requestId)
        .where('status', isEqualTo: 'Active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  /// Get all assignments for a user (mother or parent)
  Stream<QuerySnapshot> watchUserAssignments(String userId) {
    return _db
        .collection('counselor_assignments')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Active')
        .snapshots();
  }

  /// Get all assignments for a counselor
  Stream<QuerySnapshot> watchCounselorAssignments(String counselorEmail) {
    return _db
        .collection('counselor_assignments')
        .where('counselorEmail', isEqualTo: counselorEmail)
        .where('status', isEqualTo: 'Active')
        .snapshots();
  }

  /// Update counselor availability status (Available, Full, On Leave)
  Future<void> updateCounselorStatus({
    required String counselorEmail,
    required String status, // 'available', 'full', 'on_leave'
  }) async {
    await _db.collection('counselor_status').doc(counselorEmail).set({
      'counselorEmail': counselorEmail,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get counselor status
  Future<String?> getCounselorStatus(String counselorEmail) async {
    final doc = await _db
        .collection('counselor_status')
        .doc(counselorEmail)
        .get();
    return doc.data()?['status'] as String?;
  }

  /// Stream of counselor status updates
  Stream<QuerySnapshot> watchCounselorStatuses() {
    return _db.collection('counselor_status').snapshots();
  }

  /// Get available counselors by specialty
  Future<List<Map<String, dynamic>>> getAvailableCounselors({
    String? specialty,
    String? requestType, // 'mother' or 'parent'
  }) async {
    Query query = _db
        .collection('counselor_status')
        .where('status', isEqualTo: 'available');

    final snapshot = await query.get();
    return snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  /// Count active assignments for a counselor
  Future<int> getCounselorActiveAssignmentCount(String counselorEmail) async {
    final snapshot = await _db
        .collection('counselor_assignments')
        .where('counselorEmail', isEqualTo: counselorEmail)
        .where('status', isEqualTo: 'Active')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Unassign a counselor from a request
  Future<void> unassignCounselor(String assignmentId) async {
    await _db.collection('counselor_assignments').doc(assignmentId).update({
      'status': 'Inactive',
      'unassignedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- NGO/Agency Pillar ---

  Future<List<Map<String, dynamic>>> getNGOs({String? serviceFilter}) async {
    Query query = _db.collection('ngos');
    if (serviceFilter != null && serviceFilter != 'All') {
      query = query.where('services', arrayContains: serviceFilter);
    }
    final snap = await query.get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  // --- Admin Pillar: Monitoring & Analytics ---

  Stream<QuerySnapshot> watchAllRequests() {
    return _db
        .collection('mother_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getVerificationQueue() {
    return _db.collection('adoptive_families').snapshots();
  }

  Future<void> updateVerificationStatus(String docId, String status) async {
    await _db.collection('adoptive_families').doc(docId).update({
      'adoptionStatus': status,
      'backgroundCheck': status == 'Verified'
          ? 'Completed'
          : (status == 'Rejected' ? 'Rejected' : 'Pending'),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Storage Helper ---

  Future<String> uploadDocument(String filePath, String docType) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$docType.jpg';
    final ref = _storage.ref().child('documents/$docType/$fileName');
    await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
  }

  // --- Automation: Data Seeding ---

  Future<void> seedInitialData() async {
    // 1. Seed NGOs
    final ngos = [
      {
        'id': 'ngo1',
        'name': 'Pune Mother & Child Welfare',
        'region': 'Pune Central',
        'services': ['Legal', 'Medical', 'Counseling', 'Shelter'],
        'lat': 18.5204,
        'lng': 73.8567,
        'rating': 4.8,
        'capacity': 50,
      },
      {
        'id': 'ngo2',
        'name': 'Hope Guardians Foundation',
        'region': 'Hadapsar',
        'services': ['Counseling', 'Education'],
        'lat': 18.5089,
        'lng': 73.9259,
        'rating': 4.5,
        'capacity': 30,
      },
    ];

    for (var ngo in ngos) {
      await _db.collection('ngos').add(ngo);
    }

    // 2. Seed Mother Requests for Analytics
    final regions = ['Hadapsar', 'Pune Central', 'Aundh', 'Pimpri'];
    final reasonsBase = [
      'Financial Distress',
      'Lack of Support',
      'Social Stigma',
      'Medical Reasons',
      'Career Conflicts',
    ];

    for (int i = 0; i < 20; i++) {
      final region = regions[i % regions.length];
      final reasons = [reasonsBase[i % reasonsBase.length]];
      if (i % 3 == 0) reasons.add(reasonsBase[(i + 1) % reasonsBase.length]);

      await submitMotherRequest(
        reasons: reasons,
        needsCounseling: i % 2 == 0,
        isAnonymous: i % 4 == 0,
        region: region,
      );
    }

    // 3. Seed Adoptive Families
    final families = ['Sharma', 'Deshmukh', 'Patil', 'Iyer', 'Bannerjee'];
    for (int i = 0; i < families.length; i++) {
      await _db.collection('adoptive_families').add({
        'familyName': '${families[i]} Family',
        'region': regions[i % regions.length],
        'annualIncome': (8 + i) * 100000.0,
        'backgroundCheck': i == 0 ? 'Pending' : 'Completed',
        'adoptionStatus': i == 0 ? 'Under Review' : 'Verified',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
