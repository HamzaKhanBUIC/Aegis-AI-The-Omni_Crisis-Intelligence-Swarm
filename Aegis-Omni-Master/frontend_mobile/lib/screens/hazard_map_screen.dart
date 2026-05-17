import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';

class HazardMapScreen extends StatefulWidget {
  const HazardMapScreen({super.key});

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _regionController;

  int _selectedPinIndex = 0;
  bool _isLiveAlertActive = false;
  String _mapSystemStatus = 'INITIALIZING GEO-RADAR...';
  Timer? _networkSyncTimer;

  // Fixed: radiation node now has a 'severity' key — info card accesses it on all pins
  final List<Map<String, dynamic>> _dynamicHazards = [
    {
      'title': 'TEMPERATURE ANOMALY',
      'metric': '44.2°C Peak Risk',
      'desc': 'Core sector G-11 reporting extreme thermal metrics. Grid transformers operating at max tolerance.',
      'type': 'HEAT',
      'severity': 'HIGH // LEVEL 4',
      'color': Colors.orangeAccent,
      'icon': Icons.wb_sunny_outlined,
      'x': 0.72,
      'y': 0.25,
      'isActive': true,
      'hasPolygon': false,
    },
    {
      'title': 'RADIATION DETECTOR NODE',
      'metric': '0.12 μSv/h Secure',
      'desc': 'Industrial Sector I-9 atmospheric diagnostics normal. Background levels baseline secure.',
      'type': 'RAD',
      'severity': 'BASELINE // LEVEL 1', // Fixed: was missing — would crash info card
      'color': const Color(0xFF10B981), // Fixed: Colors.emeraldAccent doesn't exist
      'icon': Icons.g_mobiledata_rounded,
      'x': 0.50,
      'y': 0.68,
      'isActive': true,
      'hasPolygon': false,
    },
    {
      'title': 'CRITICAL ROAD BLOCKAGE',
      'metric': 'Shahrah-e-Faisal Artery',
      'desc': 'Severe water accumulation near Nursery intersection. Flow rate stalled. Alternate routes via University Road strictly advised.',
      'type': 'FLOOD_BLOCK',
      'severity': 'CRITICAL // LEVEL 5',
      'color': Colors.redAccent,
      'icon': Icons.block_rounded,
      'x': 0.45,
      'y': 0.38,
      'isActive': false,
      'hasPolygon': false,
    },
    {
      'title': 'CLIMATIC REGIONAL ADVISORY',
      'metric': 'Clifton Coastal Boundary',
      'desc': 'Atmospheric thermal inversion layer detected. Extreme wet-bulb temperatures active. Public hydration protocols advised.',
      'type': 'CLIMATIC_HEAT',
      'severity': 'REGIONAL EFFECT',
      'color': Colors.purpleAccent,
      'icon': Icons.thunderstorm_outlined,
      'x': 0.28,
      'y': 0.72,
      'isActive': false,
      'hasPolygon': true,
    },
  ];

  // Fixed: use kIsWeb for proper platform detection
  String _getBackendUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://10.0.2.2:8000';
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _regionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _startMapNetworkSync();
  }

  @override
  void dispose() {
    _networkSyncTimer?.cancel();
    _pulseController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _startMapNetworkSync() {
    _networkSyncTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      final url = Uri.parse('${_getBackendUrl()}/api/status');
      try {
        final response =
            await http.get(url).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body); // Fixed: .text → .body
          final String swarmStatus = data['state']['status'] as String;

          setState(() {
            if (swarmStatus == 'CRITICAL_ALERT') {
              _isLiveAlertActive = true;
              _mapSystemStatus = 'SWARM ALERT INGESTION ACTIVE';
              _dynamicHazards[2]['isActive'] = true;
              _dynamicHazards[3]['isActive'] = true;
            } else {
              _isLiveAlertActive = false;
              _mapSystemStatus = 'GEOMATRIX SCANNING // SECURE';
              _dynamicHazards[2]['isActive'] = false;
              _dynamicHazards[3]['isActive'] = false;
              if (_selectedPinIndex > 1) _selectedPinIndex = 0;
            }
          });
        }
      } catch (e) {
        setState(() {
          _mapSystemStatus = 'OFFLINE LINK BASELINE DISPLAY';
          _isLiveAlertActive = false;
          _dynamicHazards[2]['isActive'] = false;
          _dynamicHazards[3]['isActive'] = false;
        });
      }
    });
  }

  void _onPinSelected(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedPinIndex = index);
    _regionController.reset();
    _regionController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final List<Map<String, dynamic>> activePins = _dynamicHazards
        .where((e) => e['isActive'] == true)
        .toList();

    // Guard against index going out of range after alert clears
    if (_selectedPinIndex >= activePins.length) {
      _selectedPinIndex = 0;
    }

    final currentPin =
        activePins.isNotEmpty ? activePins[_selectedPinIndex] : _dynamicHazards[0];

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // 1. VECTOR MAP CANVAS
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_pulseController, _regionController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: KarachiMapPainter(
                    pulseValue: _pulseController.value,
                    regionOpacity: _regionController.value,
                    showCliftonPolygon: _isLiveAlertActive &&
                        currentPin['hasPolygon'] == true,
                  ),
                );
              },
            ),
          ),

          // 2. DISTRICT LABELS
          _buildMapLabel('GULSHAN GEOGRID',
              size.width * 0.65, size.height * 0.18),
          _buildMapLabel(
              'SADDAR CORE', size.width * 0.18, size.height * 0.48),
          _buildMapLabel('SHAHRAH-E-FAISAL',
              size.width * 0.50, size.height * 0.45),
          _buildMapLabel('CLIFTON WATERFRONT',
              size.width * 0.15, size.height * 0.68),

          // 3. SYSTEM STATUS BADGE
          Positioned(
            top: 50,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0C),
                border: Border.all(
                  color: _isLiveAlertActive
                      ? Colors.redAccent.withOpacity(0.3)
                      : const Color(0xFF27272A),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _mapSystemStatus,
                style: TextStyle(
                  color: _isLiveAlertActive
                      ? Colors.redAccent
                      : Colors.amber,
                  fontSize: 10,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 4. ACTIVE HAZARD PINS
          ...List.generate(activePins.length, (index) {
            final pin = activePins[index];
            final double leftPos =
                size.width * (pin['x'] as double);
            final double topPos =
                (size.height - 240) * (pin['y'] as double);
            final bool isSelected = _selectedPinIndex == index;
            final Color pinColor = pin['color'] as Color;

            return Positioned(
              left: leftPos - 22,
              top: topPos - 22,
              child: GestureDetector(
                onTap: () => _onPinSelected(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: isSelected
                                ? 28 + (_pulseController.value * 12)
                                : 16,
                            height: isSelected
                                ? 28 + (_pulseController.value * 12)
                                : 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: pinColor.withOpacity(isSelected
                                    ? 0.35 -
                                        (_pulseController.value * 0.25)
                                    : 0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: isSelected ? 14 : 10,
                            height: isSelected ? 14 : 10,
                            decoration: BoxDecoration(
                              color: pinColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: pinColor,
                                  blurRadius: isSelected ? 14 : 6,
                                  spreadRadius: isSelected ? 3 : 0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          }),

          // 5. GLASSMORPHIC INFO CARD
          if (activePins.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0C0F).withOpacity(0.82),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (currentPin['color'] as Color)
                            .withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                    currentPin['icon'] as IconData,
                                    color: currentPin['color'] as Color,
                                    size: 14),
                                const SizedBox(width: 8),
                                Text(
                                  currentPin['title'] as String,
                                  style: TextStyle(
                                    color:
                                        currentPin['color'] as Color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Courier',
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF27272A)),
                              ),
                              child: Text(
                                currentPin['severity'] as String,
                                style: const TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          currentPin['metric'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentPin['desc'] as String,
                          style: const TextStyle(
                            color: Color(0xFFE4E4E7),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Icon(Icons.satellite_alt_rounded,
                                size: 12, color: Color(0xFF52525B)),
                            SizedBox(width: 6),
                            Text(
                              'LIVE DIGITAL TWIN CONNECTIVITY ENGINE // NODE ACTIVE',
                              style: TextStyle(
                                color: Color(0xFF52525B),
                                fontSize: 9,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapLabel(String text, double x, double y) {
    return Positioned(
      left: x,
      top: y,
      child: IgnorePointer(
        child: Text(
          text,
          style: TextStyle(
            color: const Color(0xFF1F1F24).withOpacity(0.4),
            fontSize: 9,
            fontFamily: 'Courier',
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}

// ── Karachi Vector Painter ────────────────────────────────────────────────────
class KarachiMapPainter extends CustomPainter {
  final double pulseValue;
  final double regionOpacity;
  final bool showCliftonPolygon;

  const KarachiMapPainter({
    required this.pulseValue,
    required this.regionOpacity,
    required this.showCliftonPolygon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double heightBound = size.height - 240;

    // Grid
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF08080A)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, heightBound), gridPaint);
    }
    for (double j = 0; j < heightBound; j += 40) {
      canvas.drawLine(
          Offset(0, j), Offset(size.width, j), gridPaint);
    }

    // Coastline
    final Path coastlinePath = Path()
      ..moveTo(0, heightBound * 0.60)
      ..quadraticBezierTo(
          size.width * 0.25, heightBound * 0.65,
          size.width * 0.35, heightBound * 0.85)
      ..lineTo(size.width * 0.40, heightBound);
    canvas.drawPath(
      coastlinePath,
      Paint()
        ..color = const Color(0xFF111625)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Arterials
    final Path roadsPath = Path()
      ..moveTo(0, heightBound * 0.42)
      ..lineTo(size.width * 0.50, heightBound * 0.35)
      ..lineTo(size.width, heightBound * 0.15)
      ..moveTo(size.width * 0.10, heightBound * 0.55)
      ..quadraticBezierTo(
          size.width * 0.45, heightBound * 0.42,
          size.width, heightBound * 0.40);
    canvas.drawPath(
      roadsPath,
      Paint()
        ..color = const Color(0xFF121215)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Clifton climatic heat dome polygon
    if (showCliftonPolygon) {
      final Path poly = Path()
        ..moveTo(size.width * 0.10, heightBound * 0.60)
        ..lineTo(size.width * 0.45, heightBound * 0.58)
        ..lineTo(size.width * 0.55, heightBound * 0.82)
        ..lineTo(size.width * 0.20, heightBound * 0.90)
        ..close();

      canvas.drawPath(
        poly,
        Paint()
          ..color = Colors.purpleAccent
              .withOpacity(0.06 * regionOpacity)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        poly,
        Paint()
          ..color = Colors.purpleAccent
              .withOpacity(0.28 * regionOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant KarachiMapPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.regionOpacity != regionOpacity ||
      oldDelegate.showCliftonPolygon != showCliftonPolygon;
}
