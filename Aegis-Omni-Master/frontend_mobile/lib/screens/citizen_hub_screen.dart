import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'sentinel_application_screen.dart';
import 'hazard_map_screen.dart';

class CitizenHubScreen extends StatefulWidget {
  const CitizenHubScreen({super.key});

  @override
  State<CitizenHubScreen> createState() => _CitizenHubScreenState();
}

class _CitizenHubScreenState extends State<CitizenHubScreen> {
  double _coreTemperature = 44.2;
  double _radiationLevel = 0.12;
  int _activeRoadBlockages = 0;
  String _networkState = 'CONNECTING...';
  bool _isAlertActive = false;
  Timer? _pollingTimer;

  // Fixed: use kIsWeb for proper platform detection instead of dart.vm.product
  String _getBackendUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://10.0.2.2:8000'; // Android emulator loopback to host machine
  }

  @override
  void initState() {
    super.initState();
    _startLiveSync();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startLiveSync() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final url = Uri.parse('${_getBackendUrl()}/api/status');
      try {
        final response =
            await http.get(url).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body); // Fixed: .text → .body
          final swarmState = data['state'];
          setState(() {
            _networkState = 'SYNCED';
            _isAlertActive = swarmState['status'] == 'CRITICAL_ALERT';
            _activeRoadBlockages = _isAlertActive ? 3 : 0;
            _coreTemperature = _isAlertActive ? 48.9 : 44.2;
          });
        }
      } catch (e) {
        setState(() {
          _networkState = 'OFFLINE BRIDGE';
          _isAlertActive = false;
          _activeRoadBlockages = 0;
        });
      }
    });
  }

  void _openEmergencyReportPanel() {
    final TextEditingController reportController = TextEditingController();
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(color: Color(0xFF27272A), width: 1.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TRANSMIT CRISIS SIGNAL',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.grey, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reportController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            "Enter localized slang (e.g., 'G-10 pani bohot bharr gya ha rasta bnd ha')...",
                        hintStyle: TextStyle(
                            color:
                                const Color(0xFF52525B).withOpacity(0.7)),
                        fillColor: const Color(0xFF141417),
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF27272A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSending
                            ? null
                            : () async {
                                if (reportController.text.trim().isEmpty)
                                  return;
                                setModalState(() => isSending = true);
                                HapticFeedback.heavyImpact();
                                try {
                                  final postUrl = Uri.parse(
                                      '${_getBackendUrl()}/api/crisis/report');
                                  await http.post(
                                    postUrl,
                                    headers: {
                                      'Content-Type': 'application/json'
                                    },
                                    body: jsonEncode({
                                      'reporter_id': 'Citizen_Alpha_Node',
                                      'location_zone': 'G-10',
                                      'social_signal': reportController.text,
                                    }),
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  debugPrint('Transmission network failure.');
                                } finally {
                                  setModalState(() => isSending = false);
                                }
                              },
                        child: isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'INITIALIZE INTEL TRANSMISSION',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTelemetryCard({
    required String title,
    required String value,
    required String unit,
    required String sector,
    required String statusText,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141419), Color(0xFF08080A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isAlertActive && statusColor == Colors.redAccent
              ? Colors.redAccent.withOpacity(0.4)
              : const Color(0xFF24242A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 11,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 12, color: Color(0xFF52525B)),
              const SizedBox(width: 4),
              Text(
                sector,
                style: const TextStyle(
                  color: Color(0xFF52525B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color networkColor = _networkState == 'SYNCED'
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AEGIS-AI',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'PUBLIC SITUATIONAL NETWORK',
                            style: TextStyle(
                              color: Color(0xFF52525B),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF27272A)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: networkColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _networkState,
                              style: TextStyle(
                                color: networkColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildTelemetryCard(
                          title: 'CORE TEMPERATURE MATRIX',
                          value: _coreTemperature.toString(),
                          unit: '°C',
                          sector: 'SECTOR G-11/2 PEAK ANOMALY',
                          statusText: _isAlertActive
                              ? 'THERMAL SPIKE'
                              : 'HEATWAVE RISK',
                          statusColor: _isAlertActive
                              ? Colors.redAccent
                              : Colors.orangeAccent,
                          icon: Icons.thermostat_rounded,
                        ),
                        _buildTelemetryCard(
                          title: 'RADIATION DENSITY SENSOR',
                          value: _radiationLevel.toString(),
                          unit: 'μSv/h',
                          sector: 'INDUSTRIAL SECTOR I-9 RADIUS',
                          statusText: 'SYSTEM BASELINE',
                          statusColor: const Color(0xFF10B981), // Fixed: Colors.emeraldAccent doesn't exist
                          icon: Icons.g_mobiledata_rounded,
                        ),
                        _buildTelemetryCard(
                          title: 'CRISIS ROAD BLOCKAGES',
                          value: '0$_activeRoadBlockages',
                          unit: 'SECTORS',
                          sector: 'G-10 ARTERIAL INTERSECTION',
                          statusText: _isAlertActive
                              ? 'CRITICAL ALERT'
                              : 'ALL ZONES CLEAR',
                          // Fixed: removed duplicate statusColor with Colors.zincGreyColors (doesn't exist)
                          statusColor: _isAlertActive
                              ? Colors.redAccent
                              : Colors.grey,
                          icon: Icons.edit_road_rounded,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SentinelApplicationScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF121218),
                                  Color(0xFF050507),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: const [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BECOME A REPORTER',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Join the active sentinel network. Ease the data ingestion verification burden of our AI agents directly.',
                                        style: TextStyle(
                                          color: Color(0xFFA1A1AA),
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
