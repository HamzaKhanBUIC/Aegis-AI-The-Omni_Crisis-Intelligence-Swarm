import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Data Models ---
class HazardPin {
  final String id;
  final String zone;
  final String type;
  final String severity;
  final String metric;
  final Color color;
  final IconData icon;

  const HazardPin({
    required this.id,
    required this.zone,
    required this.type,
    required this.severity,
    required this.metric,
    required this.color,
    required this.icon,
  });
}

final List<HazardPin> _mockHazards = [
  HazardPin(
    id: 'H-001',
    zone: 'G-10 Markaz',
    type: 'Urban Flood',
    severity: 'CRITICAL',
    metric: 'Water depth ~45cm',
    color: const Color(0xFFEF4444),
    icon: Icons.water_rounded,
  ),
  HazardPin(
    id: 'H-002',
    zone: 'F-7 Sector',
    type: 'Extreme Heat',
    severity: 'ELEVATED',
    metric: 'Temp: 44.2°C',
    color: const Color(0xFFF59E0B),
    icon: Icons.thermostat_rounded,
  ),
  HazardPin(
    id: 'H-003',
    zone: 'I-8 Industrial',
    type: 'Road Blockage',
    severity: 'ELEVATED',
    metric: '3 arterials blocked',
    color: const Color(0xFFF59E0B),
    icon: Icons.traffic_rounded,
  ),
  HazardPin(
    id: 'H-004',
    zone: 'Blue Area',
    type: 'Radiation',
    severity: 'NORMAL',
    metric: '0.12 μSv/h',
    color: const Color(0xFF10B981),
    icon: Icons.radar_rounded,
  ),
];

class CitizenMapScreen extends StatefulWidget {
  const CitizenMapScreen({Key? key}) : super(key: key);

  @override
  State<CitizenMapScreen> createState() => _CitizenMapScreenState();
}

class _CitizenMapScreenState extends State<CitizenMapScreen>
    with SingleTickerProviderStateMixin {
  HazardPin? _selectedPin;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSystemStatusBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildMapCanvas(),
                    _buildHazardList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AEGIS-AI',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                  letterSpacing: 4,
                ),
              ),
              Text(
                'CITIZEN SITUATIONAL AWARENESS HUB',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.white24,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Opacity(
              opacity: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF10B981).withOpacity(0.07),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusBar() {
    final stats = [
      ('ACTIVE ALERTS', '4', const Color(0xFFEF4444)),
      ('ZONES ONLINE', '1,402', const Color(0xFF10B981)),
      ('AI CONFIDENCE', '96%', const Color(0xFFF59E0B)),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((s) => Column(
          children: [
            Text(s.$1, style: GoogleFonts.inter(fontSize: 8, color: Colors.white24, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(s.$2, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: s.$3)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildMapCanvas() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Tactical Grid Backdrop
            CustomPaint(
              painter: _GridPainter(),
              child: Container(),
            ),
            // Coordinate Label
            Positioned(
              top: 12,
              left: 12,
              child: Text(
                '33.6844° N  73.0479° E  //  ISLAMABAD GRID',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  color: Colors.white12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            // Hazard Pins (positioned visually on the mock map)
            _buildMapPin(_mockHazards[0], left: 80, top: 100),
            _buildMapPin(_mockHazards[1], left: 180, top: 60),
            _buildMapPin(_mockHazards[2], left: 240, top: 150),
            _buildMapPin(_mockHazards[3], left: 130, top: 200),
            // Selected Pin Detail Card
            if (_selectedPin != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: _buildPinDetailCard(_selectedPin!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin(HazardPin pin, {required double left, required double top}) {
    final isSelected = _selectedPin?.id == pin.id;
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => setState(() => _selectedPin = isSelected ? null : pin),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (pin.severity == 'CRITICAL')
                  Container(
                    width: 36 * _pulseAnimation.value,
                    height: 36 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pin.color.withOpacity(0.15),
                    ),
                  ),
                Container(
                  width: isSelected ? 36 : 28,
                  height: isSelected ? 36 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pin.color.withOpacity(0.15),
                    border: Border.all(
                      color: pin.color.withOpacity(isSelected ? 1.0 : 0.6),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(pin.icon, size: isSelected ? 18 : 14, color: pin.color),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPinDetailCard(HazardPin pin) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pin.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pin.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(pin.icon, color: pin.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pin.zone, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(pin.type, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                Text(pin.metric, style: GoogleFonts.inter(color: pin.color, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pin.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: pin.color.withOpacity(0.3)),
            ),
            child: Text(
              pin.severity,
              style: GoogleFonts.inter(fontSize: 9, color: pin.color, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE THREAT VECTORS',
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white24, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          ..._mockHazards.map((h) => _buildHazardCard(h)),
        ],
      ),
    );
  }

  Widget _buildHazardCard(HazardPin pin) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPin = _selectedPin?.id == pin.id ? null : pin),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedPin?.id == pin.id
                ? pin.color.withOpacity(0.5)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pin.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(pin.icon, color: pin.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pin.type,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(pin.zone,
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pin.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: pin.color.withOpacity(0.3)),
                  ),
                  child: Text(pin.severity,
                      style: GoogleFonts.inter(fontSize: 9, color: pin.color, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
                const SizedBox(height: 4),
                Text(pin.metric,
                    style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the tactical dot grid on the map canvas
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
