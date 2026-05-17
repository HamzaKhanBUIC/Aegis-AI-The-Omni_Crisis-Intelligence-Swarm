import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/dark_ops_theme.dart';

class HeatmapWidget extends StatelessWidget {
  const HeatmapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(24.8607, 67.0011), // Karachi Coordinates
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  // Using a dark CartoDB map style to fit the Dark Ops theme
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: const LatLng(24.8138, 67.0315), // DHA Phase 6 area
                      width: 80,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          color: DarkOpsTheme.errorRed.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: DarkOpsTheme.errorRed, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.water_drop, color: DarkOpsTheme.errorRed, size: 30),
                        ),
                      ),
                    ),
                    Marker(
                      point: const LatLng(24.8607, 67.0011), // Agent Location
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: DarkOpsTheme.accent.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.smart_toy, color: DarkOpsTheme.accent, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DarkOpsTheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A35)),
                ),
                child: const Text(
                  'SECTOR: KARACHI SOUTH',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
