import 'package:flutter/material.dart';
import 'citizen_home.dart';
import 'dashboard.dart';
import 'crisis_submission_screen.dart';
import 'citizen_chatbot_screen.dart';

class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  // Default to 1 to auto-load the Tactical Dashboard for judges
  int _currentSelectionIndex = 1;

  // Enforced Navigation Map
  final List<Widget> _combatScreens = [
    const CitizenHome(),             // Tab 0: Citizen Intel Portal
    const DashboardScreen(),         // Tab 1: Aegis-Omni Tactical Map Core
    const CrisisSubmissionScreen(),  // Tab 2: Signal Ingress Form
    const CitizenChatbotScreen(),    // Tab 3: AI Assistant & Live Feed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: IndexedStack(
        index: _currentSelectionIndex,
        children: _combatScreens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF00E5FF).withOpacity(0.2),
              width: 1.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentSelectionIndex,
          type: BottomNavigationBarType.fixed, // Added to prevent weird shifting with 4 items
          onTap: (index) {
            setState(() {
              _currentSelectionIndex = index;
            });
          },
          backgroundColor: const Color(0xFF0B0B0C),
          selectedItemColor: const Color(0xFF00E5FF),  // Active Cyan HUD Accent
          unselectedItemColor: Colors.white38,          // Muted De-emphasized Text
          selectedLabelStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.security, size: 22),
              activeIcon: Icon(Icons.security, color: Color(0xFF00E5FF)),
              label: 'PORTAL',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar, size: 22),
              activeIcon: Icon(Icons.radar, size: 22, color: Color(0xFF00E5FF)),
              label: 'CORE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_alert, size: 22),
              activeIcon: Icon(Icons.add_alert, size: 22, color: Color(0xFF00E5FF)),
              label: 'REPORT',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy, size: 22),
              activeIcon: Icon(Icons.smart_toy, size: 22, color: Color(0xFF00E5FF)),
              label: 'ASSISTANT',
            ),
          ],
        ),
      ),
    );
  }
}
