import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/main_navigation_holder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not fully configured yet. Loading UI anyway... $e');
  }
  // Firestore rules only accept citizen reports from a signed-in user, so each
  // install gets an anonymous uid (enable Anonymous in Firebase Auth).
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Anonymous sign-in failed; report submission will be denied. $e');
  }
  runApp(const ProviderScope(child: AegisOmniApp()));
}

class AegisOmniApp extends StatelessWidget {
  const AegisOmniApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aegis-AI Citizen Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Colors.amber),
      ),
      home: const MainNavigationHolder(),
    );
  }
}
