import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _initializeAppCheckSafely();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Add other providers here
      ],
      child: const NavJeevanApp(),
    ),
  );
}

Future<void> _initializeAppCheckSafely() async {
  try {
    if (kDebugMode) {
      debugPrint('Firebase App Check skipped in debug mode.');
      return;
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } on MissingPluginException catch (error) {
    debugPrint('Firebase App Check plugin not registered: $error');
  } on PlatformException catch (error) {
    debugPrint('Firebase App Check platform error: ${error.message}');
  } catch (error) {
    debugPrint('Firebase App Check initialization skipped: $error');
  }
}

