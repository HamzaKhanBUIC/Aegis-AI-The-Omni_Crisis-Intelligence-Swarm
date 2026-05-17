// ══════════════════════════════════════════════════════════════════════════════
// AEGIS-OMNI ADMIN — MODELS
// ══════════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';

// ── Crisis Report Document ───────────────────────────────────────────────────
class CrisisReport {
  final String id;
  final String text;
  final double latitude;
  final double longitude;
  final double precipitation;
  final String status;
  final Map<String, dynamic> currentClassification;
  final List<Map<String, dynamic>> resourceDispatches;
  final DateTime? timestamp;
  final Map<String, dynamic> rawData;

  const CrisisReport({
    required this.id,
    required this.text,
    required this.latitude,
    required this.longitude,
    required this.precipitation,
    required this.status,
    required this.currentClassification,
    required this.resourceDispatches,
    this.timestamp,
    required this.rawData,
  });

  factory CrisisReport.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Defensive parsing for nested maps and lists
    final classification = data['current_classification'] as Map<String, dynamic>? ?? {};
    final dispatchesRaw = data['resource_dispatches'] as List<dynamic>? ?? [];
    final dispatches = dispatchesRaw
        .map((e) => e as Map<String, dynamic>? ?? {})
        .where((e) => e.isNotEmpty)
        .toList();

    // Robust timestamp parsing (handles both Timestamp and ISO String)
    DateTime? parsedTimestamp;
    final tsData = data['timestamp'];
    if (tsData is Timestamp) {
      parsedTimestamp = tsData.toDate();
    } else if (tsData is String) {
      parsedTimestamp = DateTime.tryParse(tsData);
    }

    return CrisisReport(
      id: doc.id,
      text: data['text'] ?? 'No description provided',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      precipitation: (data['precipitation'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'PENDING',
      currentClassification: classification,
      resourceDispatches: dispatches,
      timestamp: parsedTimestamp,
      rawData: data,
    );
  }
}

// ── Agent Health Status ───────────────────────────────────────────────────────
enum AgentStatus { active, degraded, offline }

class AgentNode {
  final String id;
  final String displayName;
  final AgentStatus status;
  final double latencyMs;
  final double trustScore;
  final int processedCount;

  const AgentNode({
    required this.id,
    required this.displayName,
    required this.status,
    required this.latencyMs,
    required this.trustScore,
    required this.processedCount,
  });

  AgentNode copyWith({
    AgentStatus? status,
    double? latencyMs,
    double? trustScore,
    int? processedCount,
  }) =>
      AgentNode(
        id: id,
        displayName: displayName,
        status: status ?? this.status,
        latencyMs: latencyMs ?? this.latencyMs,
        trustScore: trustScore ?? this.trustScore,
        processedCount: processedCount ?? this.processedCount,
      );
}

// ── Log Entry ─────────────────────────────────────────────────────────────────
class LogEntry {
  final DateTime time;
  final String source;
  final String message;
  final LogLevel level;
  final String? agency; // KWSB, KE, RESCUE_1122, TRAFFIC_POLICE

  const LogEntry({
    required this.time,
    required this.source,
    required this.message,
    required this.level,
    this.agency,
  });
}

enum LogLevel { info, warn, error, system }

// ── Override Flag ─────────────────────────────────────────────────────────────
enum OverrideMode { normal, massFlood, lockdown, testBurst }
