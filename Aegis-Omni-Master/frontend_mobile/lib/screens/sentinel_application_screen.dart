import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ──────────────────────────────────────────────────────────────────────────────
// SENTINEL SIGNAL INTAKE SCREEN
// Citizen-facing crisis telemetry injection form.
// Writes to Firestore: sentinel_applications
// When status = 'approved', the Tactical Dashboard will animate a responder.
// ──────────────────────────────────────────────────────────────────────────────

class SentinelApplicationScreen extends StatefulWidget {
  const SentinelApplicationScreen({super.key});

  @override
  State<SentinelApplicationScreen> createState() =>
      _SentinelApplicationScreenState();
}

class _SentinelApplicationScreenState extends State<SentinelApplicationScreen>
    with SingleTickerProviderStateMixin {
  // ── Form Key & Controllers ─────────────────────────────────────────────────
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  // ── Incident Type Dropdown ─────────────────────────────────────────────────
  static const List<String> _incidentTypes = [
    'Flood Zone',
    'Power Grid Failure',
    'Traffic Gridlock',
  ];
  String _selectedIncidentType = 'Flood Zone';

  // ── Status Toggle ──────────────────────────────────────────────────────────
  // 'approved' triggers the tactical map animation immediately.
  bool _statusApproved = false;

  // ── UI State ───────────────────────────────────────────────────────────────
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _submittedDocId;

  // ── Pulse Animation (success glow) ────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  // ── Karachi Coordinate Bounds ──────────────────────────────────────────────
  static const double _latMin = 24.70;
  static const double _latMax = 25.10;
  static const double _lngMin = 66.80;
  static const double _lngMax = 67.30;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.25, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pre-seed with a default Karachi coordinate so demo is one-tap ready.
    _latController.text = '24.8922';
    _lngController.text = '67.0747';
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Coordinate Validator ───────────────────────────────────────────────────
  String? _validateLat(String? value) {
    if (value == null || value.trim().isEmpty) return 'Latitude required';
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Must be a decimal number';
    if (parsed < _latMin || parsed > _latMax) {
      return 'Out of Karachi bounds ($_latMin–$_latMax)';
    }
    return null;
  }

  String? _validateLng(String? value) {
    if (value == null || value.trim().isEmpty) return 'Longitude required';
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Must be a decimal number';
    if (parsed < _lngMin || parsed > _lngMax) {
      return 'Out of Karachi bounds ($_lngMin–$_lngMax)';
    }
    return null;
  }

  // ── Firestore Write ────────────────────────────────────────────────────────
  Future<void> _submitCrisisSignal() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    try {
      final String statusValue = _statusApproved ? 'approved' : 'pending';
      final double lat = double.parse(_latController.text.trim());
      final double lng = double.parse(_lngController.text.trim());

      final docRef = await FirebaseFirestore.instance
          .collection('sentinel_applications')
          .add({
        'incident_type': _selectedIncidentType,
        'latitude': lat,
        'longitude': lng,
        'status': statusValue,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
        _submittedDocId = docRef.id;
      });

      _pulseController.repeat(reverse: true);
    } catch (e) {
      debugPrint('[AEGIS-INTAKE] Firestore write error: $e');
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '[ERR] Transmission failed: ${e.toString().substring(0, 60)}...',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  // ── Root Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF00E5FF), size: 18),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'CRISIS SIGNAL INTAKE',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 2.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFF00E5FF).withOpacity(0.15),
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: _isSubmitted
                ? _buildSuccessState()
                : _buildFormBody(),
          ),
        ),
      ),
    );
  }

  // ── Form Body ──────────────────────────────────────────────────────────────
  Widget _buildFormBody() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Block ─────────────────────────────────────────────────
          _buildSectionHeader(
            icon: Icons.satellite_alt_rounded,
            label: 'TELEMETRY INJECTION TERMINAL',
          ),
          const SizedBox(height: 6),
          const Text(
            'Inject a crisis signal directly into the Aegis-Omni swarm. '
            'Set status to APPROVED to trigger a live responder animation on the Tactical Map.',
            style: TextStyle(
              color: Color(0xFF71717A),
              fontSize: 12,
              height: 1.55,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 32),

          // ── Incident Type ─────────────────────────────────────────────────
          _buildFieldLabel('INCIDENT TYPE'),
          const SizedBox(height: 8),
          _buildDropdown(),
          const SizedBox(height: 24),

          // ── Coordinates ───────────────────────────────────────────────────
          _buildFieldLabel('LATITUDE  (Karachi bounds: $_latMin – $_latMax)'),
          const SizedBox(height: 8),
          _buildCoordField(
            controller: _latController,
            hint: 'e.g. 24.8922',
            validator: _validateLat,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('LONGITUDE  (Karachi bounds: $_lngMin – $_lngMax)'),
          const SizedBox(height: 8),
          _buildCoordField(
            controller: _lngController,
            hint: 'e.g. 67.0747',
            validator: _validateLng,
          ),
          const SizedBox(height: 32),

          // ── Status Toggle ─────────────────────────────────────────────────
          _buildStatusToggle(),
          const SizedBox(height: 40),

          // ── Submit Button ─────────────────────────────────────────────────
          _buildSubmitButton(),
          const SizedBox(height: 16),

          // ── Schema Hint ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF27272A).withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '// FIRESTORE PAYLOAD SCHEMA',
                  style: TextStyle(
                    color: Color(0xFF3F3F46),
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '{ incident_type, latitude, longitude, status, timestamp }',
                  style: TextStyle(
                    color: const Color(0xFF00E5FF).withOpacity(0.45),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Incident Type Dropdown ─────────────────────────────────────────────────
  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedIncidentType,
          isExpanded: true,
          dropdownColor: const Color(0xFF111114),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF00E5FF)),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
          items: _incidentTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(
                    _incidentIcon(type),
                    size: 16,
                    color: _incidentColor(type),
                  ),
                  const SizedBox(width: 10),
                  Text(type),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedIncidentType = val);
          },
        ),
      ),
    );
  }

  // ── Coordinate Input Field ─────────────────────────────────────────────────
  Widget _buildCoordField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]')),
      ],
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xFF52525B).withOpacity(0.7),
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        prefixIcon: const Icon(Icons.my_location_rounded,
            color: Color(0xFF00E5FF), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F0F12),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFFF3B30), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFF3B30),
          fontFamily: 'monospace',
          fontSize: 10,
        ),
      ),
    );
  }

  // ── Status Toggle ──────────────────────────────────────────────────────────
  Widget _buildStatusToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _statusApproved
            ? const Color(0xFF00E5FF).withOpacity(0.06)
            : const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _statusApproved
              ? const Color(0xFF00E5FF).withOpacity(0.5)
              : const Color(0xFF27272A),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DEPLOYMENT STATUS',
                style: TextStyle(
                  color: Color(0xFFA1A1AA),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _statusApproved
                      ? '⚡ APPROVED — Responder will animate on map'
                      : '⏳ PENDING — Queued, no map trigger',
                  key: ValueKey(_statusApproved),
                  style: TextStyle(
                    color: _statusApproved
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF71717A),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Switch(
            value: _statusApproved,
            activeColor: const Color(0xFF00E5FF),
            activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.25),
            inactiveThumbColor: const Color(0xFF52525B),
            inactiveTrackColor: const Color(0xFF27272A),
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _statusApproved = val);
            },
          ),
        ],
      ),
    );
  }

  // ── Submit Button ──────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: _statusApproved
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _statusApproved
                ? const Color(0xFF00E5FF).withOpacity(0.12)
                : const Color(0xFF1C1C1E),
            foregroundColor: const Color(0xFF00E5FF),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
            ),
            elevation: 0,
          ),
          onPressed: _isSubmitting ? null : _submitCrisisSignal,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00E5FF),
                  ),
                )
              : const Text(
                  'SUBMIT CRISIS SIGNAL',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Success State ──────────────────────────────────────────────────────────
  Widget _buildSuccessState() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(_glowAnimation.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF)
                    .withOpacity(_glowAnimation.value * 0.12),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF66)
                          .withOpacity(_glowAnimation.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SIGNAL TRANSMITTED',
                    style: TextStyle(
                      color: Color(0xFF00FF66),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF1F1F23), height: 1),
              const SizedBox(height: 24),

              // Submitted data summary
              _buildSummaryRow('INCIDENT TYPE', _selectedIncidentType),
              const SizedBox(height: 12),
              _buildSummaryRow('LATITUDE', _latController.text),
              const SizedBox(height: 12),
              _buildSummaryRow('LONGITUDE', _lngController.text),
              const SizedBox(height: 12),
              _buildSummaryRow(
                'STATUS',
                _statusApproved ? 'APPROVED ⚡' : 'PENDING ⏳',
                valueColor: _statusApproved
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFFFFB300),
              ),
              if (_submittedDocId != null) ...[
                const SizedBox(height: 12),
                _buildSummaryRow('DOC ID', _submittedDocId!,
                    valueColor: const Color(0xFF52525B)),
              ],
              const SizedBox(height: 32),

              // CTA back to map
              if (_statusApproved)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF00E5FF).withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.radar_rounded,
                          color: Color(0xFF00E5FF), size: 16),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Switch to TACTICAL CORE tab to watch responder animate in real-time.',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Re-inject button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Color(0xFF27272A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _pulseController.stop();
                    setState(() {
                      _isSubmitted = false;
                      _submittedDocId = null;
                    });
                  },
                  child: const Text(
                    'INJECT ANOTHER SIGNAL',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF71717A),
        fontSize: 10,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSummaryRow(String key, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            key,
            style: const TextStyle(
              color: Color(0xFF52525B),
              fontSize: 10,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  IconData _incidentIcon(String type) {
    switch (type) {
      case 'Flood Zone':
        return Icons.water_damage_rounded;
      case 'Power Grid Failure':
        return Icons.bolt_rounded;
      case 'Traffic Gridlock':
        return Icons.traffic_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _incidentColor(String type) {
    switch (type) {
      case 'Flood Zone':
        return const Color(0xFF00B4D8);
      case 'Power Grid Failure':
        return const Color(0xFFFFB300);
      case 'Traffic Gridlock':
        return const Color(0xFFFF3B30);
      default:
        return Colors.white54;
    }
  }
}
