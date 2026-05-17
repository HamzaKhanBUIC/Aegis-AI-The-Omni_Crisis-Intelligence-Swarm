import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _karachiBaseline = const LatLng(24.8607, 67.0011);

  // Tactical Base Stations for Responders in Karachi
  final LatLng _hqBaseStation = const LatLng(24.8716, 67.0589);

  // Simulation State Tracking
  List<Marker> _activeMarkers = [];
  List<Polyline> _activePolylines = [];
  Map<String, AnimationController> _activeAnimations = {};

  @override
  void dispose() {
    for (var controller in _activeAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Linear Interpolation for Smooth Responder Movement
  void _animateResponder(String docId, LatLng targetLocation) {
    if (_activeAnimations.containsKey(docId)) return; // Already animating this unit

    final animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _activeAnimations[docId] = animationController;

    final Tween<double> latTween = Tween(
      begin: _hqBaseStation.latitude,
      end: targetLocation.latitude,
    );
    final Tween<double> lngTween = Tween(
      begin: _hqBaseStation.longitude,
      end: targetLocation.longitude,
    );

    animationController.addListener(() {
      setState(() {
        // Update polyline path from base to current animated position
        LatLng currentPos = LatLng(
          latTween.transform(animationController.value),
          lngTween.transform(animationController.value),
        );

        // Update routing visual lines
        _updateTrackingLayers(docId, currentPos, targetLocation);
      });
    });

    animationController.forward().then((_) {
      // Animation complete: Maintain marker at destination, clear animation cache
      _activeAnimations.remove(docId);
    });
  }

  void _updateTrackingLayers(String id, LatLng currentPos, LatLng target) {
    // Remove old state for this specific ID to avoid duplicates
    _activeMarkers.removeWhere((m) => m.key == ValueKey('unit_$id'));
    // Since Polyline in flutter_map v6 doesn't have keys, we handle it by recreating the list if needed
    // or simply clearing it since this is a simulation view
    _activePolylines.clear(); 

    // Inject Active Responder Marker (Neon Cyan)
    _activeMarkers.add(
      Marker(
        key: ValueKey('unit_$id'),
        point: currentPos,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.emergency,
          color: Color(0xFF00E5FF),
          size: 28,
        ),
      ),
    );

    // Inject Threat Target Marker (Crimson / Amber Alert)
    _activeMarkers.add(
      Marker(
        key: ValueKey('threat_$id'),
        point: target,
        width: 45,
        height: 45,
        child: const Icon(
          Icons.gpp_maybe,
          color: Color(0xFFFF3B30),
          size: 32,
        ),
      ),
    );

    // Draw glowing tactical path polyline
    _activePolylines.add(
      Polyline(
        points: [currentPos, target],
        strokeWidth: 3.5,
        color: const Color(0xFF00E5FF).withOpacity(0.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: Stack(
        children: [
          // LAYER 1: Cyber-Warfare Dark Tactical Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _karachiBaseline,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.aegisomni.app',
              ),
              PolylineLayer(polylines: _activePolylines),
              MarkerLayer(markers: _activeMarkers),
            ],
          ),

          // LAYER 2: Real-Time Firestore Signal Stream & HUD Overlay
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sentinel_applications')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;
                int activeThreats = 0;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String status = data['status'] ?? 'pending';
                  final double? lat = data['latitude']?.toDouble();
                  final double? lng = data['longitude']?.toDouble();

                  if (status == 'approved' && lat != null && lng != null) {
                    activeThreats++;
                    // Trigger the animation runner seamlessly inside frame loop
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _animateResponder(doc.id, LatLng(lat, lng));
                    });
                  }
                }

                return Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AEGIS-OMNI SWARM DISPATCH",
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Incoming Stream Units: ${docs.length}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: const Color(0xFFFF3B30)),
                            ),
                            child: Text(
                              "ACTIVE: $activeThreats",
                              style: const TextStyle(
                                color: Color(0xFFFF3B30),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }

              // Fallback/Loading HUD State
              return const Positioned(
                top: 60,
                left: 20,
                child:
                    CircularProgressIndicator(color: Color(0xFF00E5FF)),
              );
            },
          ),

          // LAYER 3: Sovereign Multi-Agent Live Ticker Terminal
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0C).withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFFB300).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB300),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "ORCHESTRATION NERVOUS FEED",
                        style: TextStyle(
                          color: Color(0xFFFFB300),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  const Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        "[SYSTEM] Listening to 'sentinel_applications'...\n[SWARM] Ready to transition routes dynamically on payload 'approved' state.",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
