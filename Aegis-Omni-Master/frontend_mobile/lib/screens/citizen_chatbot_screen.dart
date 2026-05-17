import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CitizenChatbotScreen extends StatefulWidget {
  const CitizenChatbotScreen({Key? key}) : super(key: key);

  @override
  State<CitizenChatbotScreen> createState() => _CitizenChatbotScreenState();
}

class _CitizenChatbotScreenState extends State<CitizenChatbotScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      "sender": "aegis",
      "text": "Aegis Assistant Online. Weather: Clear, 12.5mm rain expected. Air quality: AQI 42 (Good). How can I assist you?"
    }
  ];

  List<Map<String, dynamic>> _activeReports = [];
  StreamSubscription? _reportsSubscription;

  @override
  void initState() {
    super.initState();
    _reportsSubscription = FirebaseFirestore.instance
        .collection('crisis_reports')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _activeReports = snapshot.docs.map((doc) {
            final d = doc.data();
            d['id'] = doc.id;
            return d;
          }).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    final userText = _chatController.text.trim();
    setState(() {
      _messages.add({"sender": "user", "text": userText});
    });
    _chatController.clear();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      String response = "";
      final query = userText.toLowerCase();

      if (query.contains("happening") || query.contains("status") || query.contains("active") || query.contains("problem") || query.contains("crisis") || query.contains("incident")) {
        final activeCrises = _activeReports.where((r) => r['status'] == 'APPROVED' || r['status'] == 'PROCESSED').toList();
        if (activeCrises.isEmpty) {
          response = "All systems green. Aegis Swarm has not flagged any active crises in the city grid right now.";
        } else {
          response = "Aegis Swarm is currently tracking ${activeCrises.length} active verified incidents:\n";
          for (var i = 0; i < activeCrises.length; i++) {
            final c = activeCrises[i];
            final classification = c['ai_classification'] as Map<String, dynamic>? ?? c['current_classification'] as Map<String, dynamic>? ?? {};
            final type = classification['crisis_type'] ?? 'General Incident';
            final sev = classification['severity'] ?? 'LOW';
            final text = c['text'] ?? 'Report';
            response += "\n• [$type | Severity: $sev] \"$text\"";
          }
        }
      } else if (query.contains("weather") || query.contains("rain") || query.contains("temp") || query.contains("air") || query.contains("aqi")) {
        response = "Aegis Weather Integration:\n• Status: Clear\n• Precipitation: 12.5mm expected\n• Air Quality Index: AQI 42 (Safe/Good).";
      } else if (query.contains("dispatch") || query.contains("rescue") || query.contains("allocat") || query.contains("send") || query.contains("unit") || query.contains("truck") || query.contains("ambulance")) {
        final dispatchedUnits = <String>[];
        for (var c in _activeReports) {
          final dispatches = c['ai_dispatches'] as List<dynamic>? ?? c['resource_dispatches'] as List<dynamic>? ?? [];
          for (var d in dispatches) {
            if (d is Map) {
              dispatchedUnits.add("${d['unit_type'] ?? d['agency'] ?? 'Emergency Unit'} (${d['eta'] ?? 'en route'})");
            } else if (d is String) {
              dispatchedUnits.add(d);
            }
          }
        }
        if (dispatchedUnits.isEmpty) {
          response = "No emergency resources are currently deployed. Standby readiness mode active.";
        } else {
          response = "Aegis Resource Dispatch Control has deployed the following units to threat zones:\n" + dispatchedUnits.map((u) => "➡ $u").join("\n");
        }
      } else if (query.contains("help") || query.contains("what can you do") || query.contains("menu")) {
        response = "I am the Aegis Citizen Assistant. You can ask me:\n"
            "• 'What is happening right now?' to see active crises.\n"
            "• 'What units are dispatched?' to track active resources.\n"
            "• 'How is the weather and air quality?' to check sensor telemetry.";
      } else {
        response = "I am tracking the Aegis City Grid. For active situations, ask me 'what is happening' or 'what units are dispatched'.";
      }
      
      setState(() {
        _messages.add({"sender": "aegis", "text": response});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "AEGIS ASSISTANT & LIVE FEED",
          style: GoogleFonts.orbitron(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // LIVE COMMAND TERMINAL FEED (FIRESTORE)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "LIVE INCIDENT TERMINAL",
                        style: GoogleFonts.shareTechMono(color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.amber),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('crisis_reports')
                          .orderBy('timestamp', descending: true)
                          .limit(20)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: Colors.amber));
                        }

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return Text("> No active incidents reported.", style: GoogleFonts.robotoMono(color: Colors.greenAccent));
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final status = data['status'] ?? 'PENDING';
                            final text = data['text'] ?? data['description'] ?? 'Unknown signal';
                            
                            final classification = data['ai_classification'] as Map<String, dynamic>? ?? data['current_classification'] as Map<String, dynamic>? ?? {};
                            final dispatches = data['ai_dispatches'] as List<dynamic>? ?? data['resource_dispatches'] as List<dynamic>? ?? [];
                            
                            final crisisType = classification['crisis_type'] ?? 'PENDING_TRIAGE';
                            final severity = classification['severity'] ?? 'PENDING';
                            
                            Color statusColor = Colors.amberAccent;
                            if (status == 'REJECTED') statusColor = Colors.redAccent;
                            if (status == 'PROCESSED' || status == 'APPROVED') statusColor = Colors.greenAccent;

                            List<TextSpan> lines = [];
                            
                            // Signal line
                            lines.add(TextSpan(
                              text: "\n[SIGNAL DETECTED] Karachi Grid Sentinel\n",
                              style: GoogleFonts.shareTechMono(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                            ));
                            lines.add(TextSpan(
                              text: "↳ Payload: \"$text\"\n",
                              style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 11),
                            ));
                            
                            // Triage line
                            if (classification.isNotEmpty) {
                              lines.add(TextSpan(
                                text: "[AI TRIAGE SWARM] Threat Classification Matrix\n",
                                style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11),
                              ));
                              lines.add(TextSpan(
                                text: "↳ Category: $crisisType | Severity Level: $severity\n",
                                style: GoogleFonts.robotoMono(color: Colors.cyanAccent.withOpacity(0.8), fontSize: 11),
                              ));
                            }
                            
                            // Dispatch & Solving line
                            if (dispatches.isNotEmpty) {
                              lines.add(TextSpan(
                                text: "[ORCHESTRATION ENGINE] Dispatching Resources\n",
                                style: GoogleFonts.shareTechMono(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 11),
                              ));
                              for (var d in dispatches) {
                                final name = d is Map ? (d['unit_type'] ?? d['agency'] ?? 'Emergency Unit') : d.toString();
                                final eta = d is Map ? (d['eta'] ?? 'en route') : '5m';
                                lines.add(TextSpan(
                                  text: "  ↳ Dispatching: $name (ETA: $eta) -> ACTIVE RESOLUTION\n",
                                  style: GoogleFonts.robotoMono(color: Colors.pinkAccent.withOpacity(0.8), fontSize: 11),
                                ));
                              }
                            }
                            
                            // Current Node Status line
                            lines.add(TextSpan(
                              text: "[TRUST NODES STATUS] Verification: ",
                              style: GoogleFonts.shareTechMono(color: Colors.grey, fontSize: 11),
                            ));
                            lines.add(TextSpan(
                              text: "${(status == 'PROCESSED' || status == 'APPROVED') ? 'VERIFIED & PASSED' : status}\n",
                              style: GoogleFonts.shareTechMono(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                            ));
                            
                            // Visual separator
                            lines.add(TextSpan(
                              text: "========================================\n",
                              style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10),
                            ));

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: RichText(
                                text: TextSpan(children: lines),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CHATBOT AREA
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isAegis = msg["sender"] == "aegis";
                        return Align(
                          alignment: isAegis ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isAegis ? Colors.cyan.shade900.withOpacity(0.3) : Colors.amber.shade900.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isAegis ? Colors.cyan : Colors.amber, width: 1),
                            ),
                            child: Text(
                              msg["text"]!,
                              style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Ask Aegis about safety, weather...",
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.cyan),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
