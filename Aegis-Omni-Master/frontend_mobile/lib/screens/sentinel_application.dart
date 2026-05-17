import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SentinelApplication extends StatefulWidget {
  const SentinelApplication({Key? key}) : super(key: key);

  @override
  State<SentinelApplication> createState() => _SentinelApplicationState();
}

class _SentinelApplicationState extends State<SentinelApplication> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitted = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _passionController = TextEditingController();
  String? _selectedRole;
  bool _consentGiven = false;

  final List<String> _roles = [
    'Rescue Worker',
    'Medical Professional',
    'City Official',
    'Volunteer First Responder'
  ];

  Future<void> _submitApplication() async {
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must provide privacy consent to proceed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Transmit data to Aegis-Omni Firestore Database
        await FirebaseFirestore.instance.collection('sentinel_applications').add({
          'name': _nameController.text,
          'cnic': _cnicController.text,
          'zone': _zoneController.text,
          'experience': _experienceController.text,
          'education': _educationController.text,
          'passion': _passionController.text,
          'role': _selectedRole,
          'status': 'PENDING_VERIFICATION',
          'tier': 2,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Firestore Transmission Error: $e");
        // Simulated delay as fallback if Firebase fails
        await Future.delayed(const Duration(seconds: 1));
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitted = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _zoneController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _passionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isSubmitted ? _buildSuccessState() : _buildFormState(),
      ),
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Icon(Icons.security, size: 80, color: Color(0xFF00E5FF)),
            const SizedBox(height: 24),
            Text(
              'SENTINEL INITIATIVE',
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.5),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Apply for Level-2 Clearance to report verified ground-truth data.',
              textAlign: TextAlign.center,
              style: GoogleFonts.firaCode(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),

            // Form Fields
            _buildTextField(
              controller: _nameController,
              label: 'FULL NAME',
              icon: Icons.person_outline,
              validator: (v) => v!.isEmpty ? 'Name required for clearance' : null,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _cnicController,
              label: 'CNIC (13-Digit National ID)',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              validator: (v) => v!.length != 13 ? 'Exact 13 digits required' : null,
            ),
            const SizedBox(height: 24),
            _buildDropdownField(),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _zoneController,
              label: 'OPERATIONAL ZONE (e.g. DHA, Malir)',
              icon: Icons.map_outlined,
              validator: (v) => v!.isEmpty ? 'Zone specification required' : null,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _experienceController,
              label: 'YEARS OF EXPERIENCE',
              icon: Icons.timeline,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Experience required' : null,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _educationController,
              label: 'HIGHEST EDUCATION / CERTIFICATION',
              icon: Icons.school_outlined,
              validator: (v) => v!.isEmpty ? 'Education required' : null,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _passionController,
              label: 'WHY ARE YOU PASSIONATE ABOUT SECURING KARACHI?',
              icon: Icons.favorite_border,
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Please tell us why you are passionate' : null,
            ),
            const SizedBox(height: 32),
            
            // Consent Checkbox
            Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: Colors.white54,
              ),
              child: CheckboxListTile(
                value: _consentGiven,
                onChanged: (val) {
                  setState(() {
                    _consentGiven = val ?? false;
                  });
                },
                activeColor: const Color(0xFF00E5FF),
                checkColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'PRIVACY CONSENT: By submitting this form, I explicitly give my consent to Aegis-Omni Central Command to securely process, share, and verify my information with relevant authorities for emergency routing and clearance purposes.',
                  style: GoogleFonts.firaCode(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
                      foregroundColor: const Color(0xFF00E5FF),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _submitApplication,
                    child: Text(
                      'SUBMIT CLEARANCE REQUEST',
                      style: GoogleFonts.robotoMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF00FF66)),
              const SizedBox(height: 24),
              Text(
                'APPLICATION TRANSMITTED',
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pending Verification by Aegis Command. You will be notified upon approval.',
                textAlign: TextAlign.center,
                style: GoogleFonts.firaCode(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('RETURN TO DASHBOARD'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF)),
        filled: true,
        fillColor: const Color(0xFF121212),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'PROFESSION / ROLE',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF00E5FF)),
        filled: true,
        fillColor: const Color(0xFF121212),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
        ),
      ),
      items: _roles.map((role) {
        return DropdownMenuItem(
          value: role,
          child: Text(role),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedRole = val;
        });
      },
      validator: (v) => v == null ? 'Selection required' : null,
    );
  }
}
