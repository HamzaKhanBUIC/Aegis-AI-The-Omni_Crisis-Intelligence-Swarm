import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'triage_tracking_screen.dart';

class CrisisSubmissionScreen extends StatefulWidget {
  const CrisisSubmissionScreen({Key? key}) : super(key: key);

  @override
  State<CrisisSubmissionScreen> createState() => _CrisisSubmissionScreenState();
}

class _CrisisSubmissionScreenState extends State<CrisisSubmissionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _precipitationController = TextEditingController(text: "12.5");
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Description is required for swarm triage.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      debugPrint("📡 AEGIS: Starting signal transmission...");
      final double precipitation = double.tryParse(_precipitationController.text) ?? 0.0;
      
      debugPrint("📡 AEGIS: Writing to Firestore collection 'crisis_reports'...");
      final docRef = await FirebaseFirestore.instance.collection('crisis_reports').add({
        "text": _descriptionController.text,
        "precipitation": precipitation,
        "status": "PENDING",
        "latitude": 24.8922,
        "longitude": 67.0747,
        "timestamp": FieldValue.serverTimestamp(),
      });

      debugPrint("📡 AEGIS: Signal accepted! Doc ID: ${docRef.id}. Navigating to Triage...");
      HapticFeedback.vibrate(); // Tactical pulse for successful ingress

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TriageTrackingScreen(docId: docRef.id),
        ),
      );
    } catch (e) {
      debugPrint("❌ AEGIS ERROR: Signal transmission failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signal transmission failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "AEGIS SIGNAL INGRESS",
          style: GoogleFonts.orbitron(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("SITUATION DESCRIPTION"),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              hint: "Enter incident details for multi-agent analysis...",
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader("TELEMETRY DATA (MOCK)"),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _precipitationController,
              hint: "Precipitation (mm/h)",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.amber.shade400, width: 2),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        "INITIALIZE SWARM TRIAGE",
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.shareTechMono(
        color: Colors.amber.shade400,
        fontSize: 14,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(16),
          hintText: hint,
          hintStyle: GoogleFonts.robotoMono(color: Colors.grey.shade600, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
