import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SentinelMobileHUD extends StatelessWidget {
  const SentinelMobileHUD({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090d16),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f172a),
        title: const Text('AEGIS SENTINEL NODE', style: TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Pointing to active crisis nodes modified by agent_triage_listener.py
        stream: FirebaseFirestore.instance.collection('active_crises').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final double dScore = data['d_score'] ?? 0.0;
              final bool isCurveball = dScore >= 0.75;

              return Card(
                color: isCurveball ? const Color(0xff2d1015) : const Color(0xff0f172a),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isCurveball ? Colors.red : Colors.cyan, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text('Crisis ID: ${docs[index].id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${isCurveball ? "HOLD - VERIFYING DRONE SECTOR" : "DISPATCH APPROVED"} \nD_Score: $dScore', 
                    style: TextStyle(color: isCurveball ? Colors.redAccent : Colors.greenAccent)),
                  trailing: Icon(
                    isCurveball ? Icons.warning_amber_rounded : Icons.gpp_good_rounded,
                    color: isCurveball ? Colors.red : Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
