import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Real-Time Firebase Stream Provider for Live Telemetry
final telemetryProvider = StreamProvider<String>((ref) {
  return FirebaseFirestore.instance
      .collection('live_telemetry')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docChanges.isNotEmpty) {
          final change = snapshot.docChanges.last;
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            final agent = data['agent'] ?? 'Unknown';
            final msg = data['message'] ?? '';
            final level = data['level'] ?? 'INFO';
            
            final timestamp = data['timestamp'] as Timestamp?;
            final timeString = timestamp != null 
                ? DateFormat('HH:mm:ss').format(timestamp.toDate()) 
                : '00:00:00';
                
            return "[$timeString] $level: $agent: $msg";
          }
        }
        return "";
      });
});

class LogNotifier extends StateNotifier<List<String>> {
  LogNotifier() : super([]);
  void addLog(String log) => state = [...state, log];
}

final logProvider = StateNotifierProvider<LogNotifier, List<String>>((ref) => LogNotifier());

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final ScrollController _scrollController = ScrollController();
  bool _showAnalytics = false;
  
  // Fake animation for the chart
  late Timer _timer;
  List<FlSpot> _chartData = [
    const FlSpot(0, 85),
    const FlSpot(1, 88),
    const FlSpot(2, 86),
    const FlSpot(3, 92),
    const FlSpot(4, 95),
    const FlSpot(5, 90),
    const FlSpot(6, 98),
  ];
  double _time = 6;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _time++;
        // Oscillate between 85 and 98
        double nextVal = 85 + (13 * (0.5 + 0.5 * (0.5 + 0.5 * _time).clamp(0, 1))); 
        // Simple mock oscillation
        if (_time % 3 == 0) nextVal = 98;
        if (_time % 5 == 0) nextVal = 85;
        if (_time % 2 == 0) nextVal = 92;
        
        _chartData.add(FlSpot(_time, nextVal));
        if (_chartData.length > 10) _chartData.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<String>>(telemetryProvider, (previous, next) {
      next.whenData((log) {
        if (log.isNotEmpty) {
          ref.read(logProvider.notifier).addLog(log);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent + 50,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    });

    final logs = ref.watch(logProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Pitch Black
      body: Column(
        children: [
          // Sleek App Bar
          _buildSleekAppBar(),
          
          // Main Content Layout
          Expanded(
            child: _showAnalytics ? _buildAnalyticsView() : _buildTacticalView(logs),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalView(List<String> logs) {
    return Row(
      children: [
        // Left Panel: Tactical Map
        Expanded(
          flex: 3,
          child: _buildCyberGlassPanel(
            child: _buildTacticalMap(logs),
          ),
        ),
        
        // Right Panel: Swarm Intelligence Feed
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Top: Action Matrix
              _buildActionMatrixPanel(logs),
              // Middle: Chart
              Expanded(
                flex: 2,
                child: _buildCyberGlassPanel(
                  child: _buildLiveChart(),
                ),
              ),
              // Bottom: Telemetry
              Expanded(
                flex: 3,
                child: _buildCyberGlassPanel(
                  child: _buildTelemetryList(logs),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSleekAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        border: Border(bottom: BorderSide(color: Color(0xFF1F1F2E), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'AEGIS-OMNI // AEGIS-MODE',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00E5FF),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showAnalytics = false),
                icon: Icon(Icons.radar, color: !_showAnalytics ? const Color(0xFF00E5FF) : Colors.white54),
                label: Text('TACTICAL', style: TextStyle(color: !_showAnalytics ? const Color(0xFF00E5FF) : Colors.white54)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => setState(() => _showAnalytics = true),
                icon: Icon(Icons.analytics, color: _showAnalytics ? const Color(0xFF00E5FF) : Colors.white54),
                label: Text('ANALYTICS', style: TextStyle(color: _showAnalytics ? const Color(0xFF00E5FF) : Colors.white54)),
              ),
              const SizedBox(width: 24),
              _buildVitalIndicator('NETWORK', true),
              const SizedBox(width: 24),
              _buildVitalIndicator('ACTIVE CRISIS', true, isWarning: true),
              const SizedBox(width: 24),
              _buildVitalIndicator('SWARM SYNC', true),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVitalIndicator(String label, bool active, {bool isWarning = false}) {
    Color dotColor = isWarning ? const Color(0xFFFF3366) : const Color(0xFF00FF66);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? dotColor : Colors.grey,
            shape: BoxShape.circle,
            boxShadow: [
              if (active)
                BoxShadow(
                  color: dotColor.withOpacity(0.8),
                  blurRadius: 6,
                  spreadRadius: 2,
                )
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.firaCode(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCyberGlassPanel({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  Widget _buildTacticalMap(List<String> logs) {
    final hasOverride = logs.any((log) => log.contains("AUTHORITY OVERRIDE"));
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(24.8607, 67.0011), // Karachi
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        PolygonLayer(
          polygons: [
            Polygon(
              points: const [
                LatLng(24.8300, 67.0200),
                LatLng(24.8100, 67.0500),
                LatLng(24.7900, 67.0300),
                LatLng(24.8100, 67.0000),
              ],
              color: const Color(0xFFFF3366).withOpacity(0.3),
              isFilled: true,
              borderColor: const Color(0xFFFF3366),
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: const LatLng(24.8607, 67.0011),
              width: 32,
              height: 32,
              child: hasOverride
                  ? const Icon(Icons.security, color: Colors.amber, size: 32)
                  : Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionMatrixPanel(List<String> logs) {
    // Determine status from recent logs
    final logText = logs.join(" ");
    final powerOffline = logText.contains("PREVENTATIVE_SHUTDOWN") || logText.contains("Grid offline") || logText.contains("Power");
    final trafficRerouted = logText.contains("REROUTE_EMERGENCY_VEHICLES") || logText.contains("Traffic");
    final hospitalStandby = logText.contains("HOSPITAL_CAPACITY_ALERT") || logText.contains("Hospital");
    final fundsDeployed = logText.contains("DISBURSE_BACKUPLOAN") || logText.contains("Relief funds") || logText.contains("BACKUPLOAN");

    return _buildCyberGlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '> ACTION MATRIX STATUS',
              style: GoogleFonts.firaCode(
                color: const Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIcon(Icons.bolt, powerOffline ? const Color(0xFFFF3366) : Colors.grey.withOpacity(0.3), powerOffline, "GRID"),
                _buildStatusIcon(Icons.directions_car, trafficRerouted ? const Color(0xFF00FF66) : Colors.grey.withOpacity(0.3), trafficRerouted, "TRAFFIC"),
                _buildStatusIcon(Icons.local_hospital, hospitalStandby ? Colors.amber : Colors.grey.withOpacity(0.3), hospitalStandby, "HEALTH"),
                _buildStatusIcon(Icons.account_balance_wallet, fundsDeployed ? const Color(0xFF00FF66) : Colors.grey.withOpacity(0.3), fundsDeployed, "FUNDS"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(IconData icon, Color color, bool isActive, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: color, width: 2),
            boxShadow: isActive
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)]
                : [],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.firaCode(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '> SWARM CONFIDENCE LEVEL',
            style: GoogleFonts.firaCode(
              color: const Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 80,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData,
                    isCurved: true,
                    color: const Color(0xFF00E5FF),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E5FF).withOpacity(0.3),
                          const Color(0xFF00E5FF).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryList(List<String> logs) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '> LIVE TELEMETRY FEED',
            style: GoogleFonts.firaCode(
              color: const Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                Color textColor = const Color(0xFF00E5FF); // Default Info
                if (log.contains("CRITICAL")) textColor = const Color(0xFFFF3366);
                if (log.contains("BACKUPLOAN")) textColor = const Color(0xFF00FF66);
                if (log.contains("AUTHORITY OVERRIDE")) textColor = Colors.amber;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    log,
                    style: GoogleFonts.firaCode(
                      color: textColor,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return Row(
      children: [
        // Left Panel: Historical Heatmap
        Expanded(
          flex: 2,
          child: _buildCyberGlassPanel(
            child: _buildHistoricalHeatmap(),
          ),
        ),
        
        // Right Panel: Analytics Charts
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(
                child: _buildCyberGlassPanel(
                  child: _buildImpactBarChart(),
                ),
              ),
              Expanded(
                child: _buildCyberGlassPanel(
                  child: _buildResourcePieChart(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalHeatmap() {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(24.8607, 67.0011),
            initialZoom: 11.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            CircleLayer(
              circles: [
                CircleMarker(point: const LatLng(24.8900, 67.0200), color: Colors.red.withOpacity(0.4), radius: 60, useRadiusInMeter: false),
                CircleMarker(point: const LatLng(24.8500, 67.0500), color: Colors.orange.withOpacity(0.4), radius: 45, useRadiusInMeter: false),
                CircleMarker(point: const LatLng(24.8200, 67.0100), color: Colors.yellow.withOpacity(0.4), radius: 30, useRadiusInMeter: false),
                CircleMarker(point: const LatLng(24.9100, 67.0800), color: Colors.red.withOpacity(0.3), radius: 50, useRadiusInMeter: false),
              ],
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              'HISTORICAL CRISIS ZONES (6 MONTHS)',
              style: GoogleFonts.firaCode(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactBarChart() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('> CRISES RESOLVED (YTD)', style: GoogleFonts.firaCode(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 120,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 10);
                        String text;
                        switch (value.toInt()) {
                          case 0: text = 'JAN'; break;
                          case 1: text = 'FEB'; break;
                          case 2: text = 'MAR'; break;
                          case 3: text = 'APR'; break;
                          case 4: text = 'MAY'; break;
                          case 5: text = 'JUN'; break;
                          default: text = ''; break;
                        }
                        return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 40, color: const Color(0xFF00E5FF), width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 65, color: const Color(0xFF00E5FF), width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 30, color: const Color(0xFF00E5FF), width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 85, color: const Color(0xFF00E5FF), width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 110, color: Colors.amber, width: 16, borderRadius: BorderRadius.circular(4))]), // Current month highlighted
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 0, color: const Color(0xFF00E5FF), width: 16, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcePieChart() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('> RESOURCE ALLOCATION', style: GoogleFonts.firaCode(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(color: const Color(0xFFFF3366), value: 35, title: 'POWER', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(color: const Color(0xFF00FF66), value: 25, title: 'FUNDS', radius: 45, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                  PieChartSectionData(color: const Color(0xFF00E5FF), value: 20, title: 'TRAFFIC', radius: 35, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                  PieChartSectionData(color: Colors.amber, value: 20, title: 'HEALTH', radius: 35, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
