// ══════════════════════════════════════════════════════════════════════════════
// AEGIS-OMNI ADMIN WEB — ENTRY POINT
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/command_center_screen.dart';
import 'theme/aegis_admin_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[AEGIS-ADMIN] Firebase init error: $e');
  }
  runApp(const ProviderScope(child: AegisAdminApp()));
}

class AegisAdminApp extends StatelessWidget {
  const AegisAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aegis-Omni | Admin Command Center',
      debugShowCheckedModeBanner: false,
      theme: AegisAdminTheme.theme,
      home: const CommandCenterScreen(),
    );
  }
}
