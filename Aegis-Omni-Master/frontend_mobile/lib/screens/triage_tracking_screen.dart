import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class TriageTrackingScreen extends StatelessWidget {
  final String docId;

  const TriageTrackingScreen({Key? key, required this.docId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('crisis_reports').doc(docId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState("Comm-Link Interrupted: ${snapshot.error}");
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const _LoadingState();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String status = data['status'] ?? 'UNKNOWN';
        
        // Defensive parsing for nested Map (Check both field names used by backend)
        final dynamic rawClassification = data['ai_classification'] ?? data['current_classification'];
        final String action = (rawClassification is Map) 
            ? (rawClassification['action']?.toString() ?? 'PENDING') 
            : 'PENDING';
            
        // Defensive parsing for List (Check both field names used by backend)
        final dynamic rawDispatches = data['ai_dispatches'] ?? data['resource_dispatches'];
        final List<dynamic> dispatches = (rawDispatches is List) ? rawDispatches : [];

        // Determine UI State based on Backend Signals
        // Rejection check MUST come before the 'PROCESSED' check
        if (action == "REJECTED" || status == "REJECTED") {
          return const _RejectedView();
        }

        if (action == "APPROVED" || status == "APPROVED") {
          return _ApprovedView(dispatches: dispatches);
        }

        if (status == "PROCESSED") {
          // Default to approved if processed and not rejected
          return _ApprovedView(dispatches: dispatches);
        }

        return const _RadarTriageView();
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          message,
          style: GoogleFonts.shareTechMono(color: Colors.red),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.amber),
      ),
    );
  }
}

/// --- PENDING STATE: RADAR VIEW ---
class _RadarTriageView extends StatefulWidget {
  const _RadarTriageView();

  @override
  State<_RadarTriageView> createState() => _RadarTriageViewState();
}

class _RadarTriageViewState extends State<_RadarTriageView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.amber.withOpacity(0.05), Colors.black],
            radius: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: RadarPainter(_controller.value),
                      size: const Size(300, 300),
                    );
                  },
                ),
                Text(
                  "TRIAGE",
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "Aegis Multi-Agent Swarm is validating signals via Zero-Trust Verification...",
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFF00E5FF).withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "ZERO-TRUST VERIFICATION IN PROGRESS",
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFF00E5FF).withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double angle;
  RadarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), bgPaint);
    }

    // Draw crosshairs
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), bgPaint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), bgPaint);

    // Draw the tactical sweep using drawArc for precision
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.6),
          const Color(0xFF00E5FF).withOpacity(0.0),
        ],
        stops: const [0.0, 0.25],
        transform: GradientRotation(angle * 2 * math.pi - (math.pi / 2)),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle * 2 * math.pi - (math.pi / 2),
      math.pi / 2, // 90 degree sweep
      true,
      sweepPaint,
    );

    // Draw the leading "scanning line"
    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final lineAngle = angle * 2 * math.pi - (math.pi / 2);
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(lineAngle),
        center.dy + radius * math.sin(lineAngle),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}

/// --- APPROVED STATE: EMERALD VIEW ---
class _ApprovedView extends StatelessWidget {
  final List<dynamic> dispatches;
  const _ApprovedView({required this.dispatches});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001A08), // Dark Emerald Background
      appBar: AppBar(
        title: Text("VERIFIED THREAT", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF00C853).withOpacity(0.1), Colors.black],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00C853), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "STATUS: APPROVED",
                            style: GoogleFonts.shareTechMono(
                              color: const Color(0xFF00C853),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "Emergency machinery has been authorized.",
                            style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: dispatches.length,
                itemBuilder: (context, index) {
                  final dispatch = dispatches[index] as Map<String, dynamic>? ?? {};
                  final type = dispatch['unit_type'] ?? 'Standard Response';
                  final eta = dispatch['eta'] ?? 'TBD';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.engineering, color: Color(0xFF00C853)),
                      title: Text(
                        type.toString().toUpperCase(),
                        style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          eta.toString(),
                          style: GoogleFonts.robotoMono(color: const Color(0xFF00C853), fontSize: 12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- REJECTED STATE: CRIMSON VIEW ---
class _RejectedView extends StatelessWidget {
  const _RejectedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade900, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 64),
                    const SizedBox(height: 24),
                    Text(
                      "Alert Dismissed",
                      style: GoogleFonts.orbitron(
                        color: Colors.red.shade700,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Signal validation failed via Zero-Trust verification matrix.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.amber.shade200,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "RETURN TO HUB",
                  style: GoogleFonts.orbitron(color: Colors.grey, letterSpacing: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
