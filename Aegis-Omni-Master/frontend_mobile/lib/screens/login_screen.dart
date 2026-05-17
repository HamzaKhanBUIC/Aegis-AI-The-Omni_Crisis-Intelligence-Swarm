import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'command_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CommandDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF030305), // Ultra Dark
              Color(0xFF0A0A14), // Cyber Blue Tint
              Color(0xFF000000), // Pure Black
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with Pulse Animation
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E5FF).withOpacity(0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_moon_outlined,
                        size: 100,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Title Text
                  Text(
                    'AEGIS-OMNI',
                    style: GoogleFonts.robotoMono(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.8),
                          blurRadius: 20,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'INTELLIGENCE SWARM GRID',
                    style: GoogleFonts.firaCode(
                      fontSize: 14,
                      letterSpacing: 4,
                      color: const Color(0xFF00E5FF).withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Glassmorphism Login Container
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.05),
                          blurRadius: 24,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFF00E5FF))
                            : InkWell(
                                onTap: signInWithGoogle,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF00E5FF).withOpacity(0.2),
                                        const Color(0xFF00E5FF).withOpacity(0.05),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.security, color: Colors.white, size: 28),
                                      const SizedBox(width: 16),
                                      Text(
                                        'INITIALIZE ACCESS',
                                        style: GoogleFonts.firaCode(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const CommandDashboard()),
                            );
                          },
                          child: Text(
                            '[ BYPASS PROTOCOL ]',
                            style: GoogleFonts.firaCode(
                              color: Colors.white38,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  // Connection Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF66),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FF66).withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ENCRYPTED CHANNEL SECURE',
                        style: GoogleFonts.firaCode(
                          color: const Color(0xFF00FF66),
                          fontSize: 10,
                          letterSpacing: 2,
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
    );
  }
}
