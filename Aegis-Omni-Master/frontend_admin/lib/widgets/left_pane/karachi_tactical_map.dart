// ══════════════════════════════════════════════════════════════════════════════
// LEFT PANE — LIVE KARACHI TACTICAL MAP
// Displays real-time Firestore markers + animated routing vectors
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/aegis_admin_theme.dart';

class KarachiTacticalMap extends ConsumerStatefulWidget {
  const KarachiTacticalMap({super.key});

  @override
  ConsumerState<KarachiTacticalMap> createState() => _KarachiTacticalMapState();
}

class _KarachiTacticalMapState extends ConsumerState<KarachiTacticalMap>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const LatLng _karachiCenter = LatLng(24.8607, 67.0011);
  static const LatLng _hqBase = LatLng(24.8716, 67.0589);

  final Map<String, AnimationController> _animControllers = {};
  final Map<String, Animation<double>> _latAnims = {};
  final Map<String, Animation<double>> _lngAnims = {};

  @override
  void dispose() {
    for (final c in _animControllers.values) c.dispose();
    super.dispose();
  }

  void _ensureAnimation(String id, LatLng target) {
    if (_animControllers.containsKey(id)) return;

    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    _animControllers[id] = ctrl;
    _latAnims[id] = Tween<double>(
      begin: _hqBase.latitude,
      end: target.latitude,
    ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    _lngAnims[id] = Tween<double>(
      begin: _hqBase.longitude,
      end: target.longitude,
    ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));

    ctrl.addListener(() => setState(() {}));
    ctrl.forward();
  }

  List<Marker> _buildMarkers(List<CrisisReport> docs) {
    final List<Marker> markers = [];

    // HQ base station marker
    markers.add(Marker(
      key: const ValueKey('hq_base'),
      point: _hqBase,
      width: 52,
      height: 52,
      child: _buildHQMarker(),
    ));

    for (final doc in docs) {
      final target = LatLng(doc.latitude, doc.longitude);
      final action = doc.currentClassification['action'];

      if (action == 'APPROVED') {
        _ensureAnimation(doc.id, target);

        final lat = _latAnims[doc.id]?.value ?? _hqBase.latitude;
        final lng = _lngAnims[doc.id]?.value ?? _hqBase.longitude;
        final currentPos = LatLng(lat, lng);

        // Responder unit marker (Cyan)
        markers.add(Marker(
          key: ValueKey('unit_${doc.id}'),
          point: currentPos,
          width: 44,
          height: 44,
          child: _buildResponderMarker(doc.text),
        ));

        // Threat/incident target marker
        markers.add(Marker(
          key: ValueKey('threat_${doc.id}'),
          point: target,
          width: 48,
          height: 48,
          child: _buildThreatMarker(doc),
        ));
      } else if (action == 'REJECTED') {
        // Rejected markers: Flash crimson and dim
        markers.add(Marker(
          key: ValueKey('rejected_${doc.id}'),
          point: target,
          width: 40,
          height: 40,
          child: _buildRejectedMarker(),
        ));
      } else if (doc.status == 'PENDING') {
        // Pending markers: Pulsing Amber
        markers.add(Marker(
          key: ValueKey('pending_${doc.id}'),
          point: target,
          width: 42,
          height: 42,
          child: const _PulsingPendingMarker(),
        ));
      }
    }
    return markers;
  }

  List<Polyline> _buildPolylines(List<CrisisReport> docs) {
    final List<Polyline> lines = [];
    for (final doc in docs) {
      final action = doc.currentClassification['action'];
      if (action == 'APPROVED' && _latAnims.containsKey(doc.id)) {
        final lat = _latAnims[doc.id]!.value;
        final lng = _lngAnims[doc.id]!.value;
        final target = LatLng(doc.latitude, doc.longitude);
        lines.add(Polyline(
          points: [LatLng(lat, lng), target],
          strokeWidth: 2.5,
          color: AegisAdminTheme.cyan.withOpacity(0.7),
        ));
        // HQ to current unit dotted trail
        lines.add(Polyline(
          points: [_hqBase, LatLng(lat, lng)],
          strokeWidth: 1.2,
          color: AegisAdminTheme.amber.withOpacity(0.35),
        ));
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final asyncDocs = ref.watch(crisisReportStreamProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: AegisAdminTheme.borderCyan.withOpacity(0.6),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildMapHeader(asyncDocs),
          Expanded(
            child: Stack(
              children: [
                // ── CartoDB Dark Map ─────────────────────────────────────────
                asyncDocs.when(
                  data: (docs) => FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: _karachiCenter,
                      initialZoom: 11.5,
                      minZoom: 9,
                      maxZoom: 16,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                        userAgentPackageName: 'com.aegisomni.admin',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                      PolylineLayer(polylines: _buildPolylines(docs)),
                      MarkerLayer(markers: _buildMarkers(docs)),
                    ],
                  ),
                  loading: () => FlutterMap(
                    options: const MapOptions(
                        initialCenter: _karachiCenter, initialZoom: 11.5),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                        userAgentPackageName: 'com.aegisomni.admin',
                      ),
                    ],
                  ),
                  error: (e, _) => _buildErrorState(e.toString()),
                ),

                // ── Zoom Controls ────────────────────────────────────────────
                Positioned(
                  right: 12,
                  bottom: 80,
                  child: _buildZoomControls(),
                ),

                // ── Legend overlay ───────────────────────────────────────────
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _buildMapLegend(asyncDocs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Map Header ───────────────────────────────────────────────────────────────
  Widget _buildMapHeader(AsyncValue<List<CrisisReport>> asyncDocs) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AegisAdminTheme.canvas,
        border: Border(
          bottom: BorderSide(
              color: AegisAdminTheme.cyan.withOpacity(0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: AegisAdminTheme.cyan, size: 16),
          const SizedBox(width: 8),
          Text(
            'KARACHI TACTICAL GRID',
            style: AegisAdminTheme.mono(
                size: 11,
                color: AegisAdminTheme.cyan,
                weight: FontWeight.bold,
                letterSpacing: 1.8),
          ),
          const Spacer(),
          asyncDocs.when(
            data: (docs) {
              final active =
                  docs.where((d) => d.currentClassification['action'] == 'APPROVED').length;
              return Row(children: [
                _StatusChip(
                    label: '${docs.length} TOTAL', color: AegisAdminTheme.textMuted),
                const SizedBox(width: 8),
                _StatusChip(
                    label: '$active DEPLOYED', color: AegisAdminTheme.cyan),
              ]);
            },
            loading: () => const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: AegisAdminTheme.cyan),
            ),
            error: (_, __) => Text('ERR',
                style: AegisAdminTheme.mono(color: AegisAdminTheme.danger)),
          ),
        ],
      ),
    );
  }

  // ── Markers ───────────────────────────────────────────────────────────────────
  Widget _buildHQMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AegisAdminTheme.amber.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AegisAdminTheme.amber, width: 2),
      ),
      child:
          const Icon(Icons.security, color: AegisAdminTheme.amber, size: 22),
    );
  }

  Widget _buildResponderMarker(String text) {
    final color = AegisAdminTheme.cyan;
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
      ),
      child: const Icon(Icons.emergency_share_rounded, color: Colors.cyanAccent, size: 20),
    );
  }

  Widget _buildThreatMarker(CrisisReport doc) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AegisAdminTheme.danger.withOpacity(0.18),
            shape: BoxShape.circle,
            border:
                Border.all(color: AegisAdminTheme.danger.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: AegisAdminTheme.danger.withOpacity(0.3), blurRadius: 10)
            ],
          ),
          child: Icon(_incidentIcon(doc.text),
              color: AegisAdminTheme.danger, size: 18),
        ),
      ],
    );
  }

  Widget _buildRejectedMarker() {
    return _FlashingRejectedMarker();
  }

  // ── Zoom Controls ─────────────────────────────────────────────────────────────
  Widget _buildZoomControls() {
    return Column(
      children: [
        _MapButton(
          icon: Icons.add,
          onTap: () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom + 1,
          ),
        ),
        const SizedBox(height: 6),
        _MapButton(
          icon: Icons.remove,
          onTap: () => _mapController.move(
            _mapController.camera.center,
            _mapController.camera.zoom - 1,
          ),
        ),
        const SizedBox(height: 6),
        _MapButton(
          icon: Icons.my_location_rounded,
          onTap: () => _mapController.move(_karachiCenter, 11.5),
        ),
      ],
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────────
  Widget _buildMapLegend(AsyncValue<List<CrisisReport>> asyncDocs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AegisAdminTheme.canvas.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AegisAdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendRow(color: AegisAdminTheme.amber, label: 'HQ BASE STATION'),
          const SizedBox(height: 4),
          _LegendRow(color: AegisAdminTheme.cyan, label: 'RESPONDER UNIT'),
          const SizedBox(height: 4),
          _LegendRow(color: AegisAdminTheme.danger, label: 'INCIDENT TARGET'),
          const SizedBox(height: 4),
          _LegendRow(
              color: AegisAdminTheme.amber, label: 'PENDING (TRIAGE)'),
          const SizedBox(height: 4),
          _LegendRow(
              color: AegisAdminTheme.danger.withOpacity(0.4), label: 'ZERO-TRUST REJECTED'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: AegisAdminTheme.danger, size: 36),
          const SizedBox(height: 12),
          Text('FIRESTORE STREAM ERROR',
              style: AegisAdminTheme.mono(
                  color: AegisAdminTheme.danger, weight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(msg,
              style: AegisAdminTheme.mono(color: AegisAdminTheme.textMuted)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  IconData _incidentIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('flood') || lower.contains('water')) return Icons.water_damage_rounded;
    if (lower.contains('power') || lower.contains('electricity')) return Icons.bolt_rounded;
    if (lower.contains('traffic')) return Icons.traffic_rounded;
    return Icons.warning_amber_rounded;
  }
}

// ── Sub-Widgets ───────────────────────────────────────────────────────────────

class _PulsingPendingMarker extends StatefulWidget {
  const _PulsingPendingMarker();

  @override
  State<_PulsingPendingMarker> createState() => _PulsingPendingMarkerState();
}

class _PulsingPendingMarkerState extends State<_PulsingPendingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: AegisAdminTheme.amber.withOpacity(0.2 * _anim.value),
          shape: BoxShape.circle,
          border: Border.all(color: AegisAdminTheme.amber.withOpacity(_anim.value), width: 2),
          boxShadow: [
            BoxShadow(color: AegisAdminTheme.amber.withOpacity(0.5 * _anim.value), blurRadius: 10 * _anim.value),
          ],
        ),
        child: Icon(Icons.radar, color: AegisAdminTheme.amber, size: 16 * _anim.value),
      ),
    );
  }
}

class _FlashingRejectedMarker extends StatefulWidget {
  const _FlashingRejectedMarker();

  @override
  State<_FlashingRejectedMarker> createState() => _FlashingRejectedMarkerState();
}

class _FlashingRejectedMarkerState extends State<_FlashingRejectedMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final opacity = 1.0 - (_ctrl.value * 0.7); // Dim to 0.3
        final color = Color.lerp(AegisAdminTheme.danger, AegisAdminTheme.danger.withOpacity(0.3), _ctrl.value);
        return Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              color: color!.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: const Icon(Icons.close_rounded, color: AegisAdminTheme.danger, size: 18),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: AegisAdminTheme.mono(size: 9, color: color, weight: FontWeight.bold)),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AegisAdminTheme.slate,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AegisAdminTheme.border),
        ),
        child: Icon(icon, color: AegisAdminTheme.textSecond, size: 16),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AegisAdminTheme.mono(size: 9, color: AegisAdminTheme.textMuted)),
      ],
    );
  }
}
