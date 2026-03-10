import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
// import 'firebase_options.dart'; // Ensure this exists if using Firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Uncomment and configure after Firebase is setup
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

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
