import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'citizen_map_screen.dart';
import 'sentinel_portal_screen.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({Key? key}) : super(key: key);

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    CitizenMapScreen(),
    SentinelPortalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFF59E0B),
          unselectedItemColor: Colors.white24,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.radar_rounded, size: 22),
              label: 'CITY RADAR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined, size: 22),
              label: 'SENTINEL',
            ),
          ],
        ),
      ),
    );
  }
}
