// ══════════════════════════════════════════════════════════════════════════════
// AEGIS-OMNI ADMIN — PROVIDERS (Riverpod)
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

// ── Firestore Stream ──────────────────────────────────────────────────────────
final crisisReportStreamProvider = StreamProvider<List<CrisisReport>>((ref) {
  return FirebaseFirestore.instance
      .collection('crisis_reports')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => CrisisReport.fromDoc(d)).toList());
});

// ── Selected Document for JSON Inspector ─────────────────────────────────────
final selectedDocProvider = StateProvider<CrisisReport?>((ref) => null);

// ── Agent Swarm Monitor ───────────────────────────────────────────────────────
class AgentSwarmNotifier extends StateNotifier<List<AgentNode>> {
  AgentSwarmNotifier()
      : super([
          const AgentNode(
            id: 'agent_triage',
            displayName: 'AGENT_TRIAGE',
            status: AgentStatus.active,
            latencyMs: 38.0,
            trustScore: 97.2,
            processedCount: 0,
          ),
          const AgentNode(
            id: 'truth_engine',
            displayName: 'TRUTH_ENGINE',
            status: AgentStatus.active,
            latencyMs: 42.0,
            trustScore: 98.4,
            processedCount: 0,
          ),
          const AgentNode(
            id: 'vision_specialist',
            displayName: 'VISION_SPECIALIST',
            status: AgentStatus.active,
            latencyMs: 67.0,
            trustScore: 94.1,
            processedCount: 0,
          ),
          const AgentNode(
            id: 'command_dispatcher',
            displayName: 'CMD_DISPATCHER',
            status: AgentStatus.active,
            latencyMs: 21.0,
            trustScore: 99.1,
            processedCount: 0,
          ),
        ]) {
    _startSimulation();
  }

  Timer? _timer;
  final Random _rng = Random();

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      state = state.map((agent) {
        // Jitter latency ±15ms
        final newLatency = (agent.latencyMs + (_rng.nextDouble() - 0.5) * 15)
            .clamp(12.0, 200.0);
        // Drift trust score slightly
        final newTrust =
            (agent.trustScore + (_rng.nextDouble() - 0.5) * 0.6).clamp(80.0, 100.0);
        // Randomly degrade an agent for realism (1% chance)
        AgentStatus newStatus = AgentStatus.active;
        if (_rng.nextInt(100) == 0) {
          newStatus = AgentStatus.degraded;
        }
        return agent.copyWith(
          latencyMs: double.parse(newLatency.toStringAsFixed(1)),
          trustScore: double.parse(newTrust.toStringAsFixed(1)),
          status: newStatus,
          processedCount: agent.processedCount + _rng.nextInt(3),
        );
      }).toList();
    });
  }

  void forceAllActive() {
    state = state
        .map((a) => a.copyWith(status: AgentStatus.active, latencyMs: 30.0))
        .toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final agentSwarmProvider =
    StateNotifierProvider<AgentSwarmNotifier, List<AgentNode>>(
        (ref) => AgentSwarmNotifier());

// ── Log Streamer ──────────────────────────────────────────────────────────────
class LogStreamerNotifier extends StateNotifier<List<LogEntry>> {
  LogStreamerNotifier() : super([]) {
    _inject(_systemBoot);
    _startPeriodicLogs();
  }

  Timer? _timer;
  final Random _rng = Random();

  static final List<LogEntry> _systemBoot = [
    LogEntry(
      time: DateTime.now(),
      source: 'SYSTEM',
      message: 'Aegis-Omni Admin Command Center initialized.',
      level: LogLevel.system,
    ),
    LogEntry(
      time: DateTime.now(),
      source: 'FIRESTORE',
      message: "Listening to 'crisis_reports' collection...",
      level: LogLevel.info,
    ),
    LogEntry(
      time: DateTime.now(),
      source: 'SWARM',
      message: 'LangGraph agents online. Topology: TRIAGE → TRUTH_ENGINE → CMD_DISPATCHER.',
      level: LogLevel.info,
    ),
  ];

  static const List<String> _mockMessages = [
    '[CMD_DISPATCHER] Allocating 2x RESCUE_1122 units to Saddar high-density sector.',
    'TRUTH_ENGINE: Verified Water Main Burst in Grid B-12. Anomaly detected: MET_FLOOD=FALSE.',
    'KWSB: Engineering crew routed to exact coordinates 24.892, 67.074.',
    'K-ELECTRIC: Dispatching field engineers to sub-station grid failure source.',
    'TRAFFIC_POLICE: Establishing perimeter in Gulshan-e-Iqbal to preserve life lines.',
    'RESCUE_1122: Critical casualty prevention protocol active in Sector 7.',
    'Sovereign Sentinel: Suppressing false positive social signal in Clifton.',
    'CMD: Rationale - Prioritizing Saddar core over residential periphery due to density.',
    'Swarm health check: All agents nominal.',
    'KWSB: Pressure drop detected in line K-III. Dispatching repair swarm.',
  ];

  void _inject(List<LogEntry> entries) {
    state = [...state, ...entries].take(200).toList();
  }

  void add(LogEntry entry) {
    state = [entry, ...state].take(200).toList();
  }

  void _startPeriodicLogs() {
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      final msg = _mockMessages[_rng.nextInt(_mockMessages.length)];
      final sources = ['SWARM', 'FIRESTORE', 'TRIAGE', 'TRUTH_ENGINE', 'CMD'];
      add(LogEntry(
        time: DateTime.now(),
        source: sources[_rng.nextInt(sources.length)],
        message: msg,
        level: _rng.nextInt(10) == 0 ? LogLevel.warn : LogLevel.info,
      ));
    });
  }

  void injectOverrideLog(String message) {
    add(LogEntry(
      time: DateTime.now(),
      source: 'OVERRIDE',
      message: message,
      level: LogLevel.warn,
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final logStreamerProvider =
    StateNotifierProvider<LogStreamerNotifier, List<LogEntry>>(
        (ref) => LogStreamerNotifier());

// ── Override Mode ─────────────────────────────────────────────────────────────
final overrideModeProvider = StateProvider<OverrideMode>((ref) => OverrideMode.normal);

// ── Firestore Override Service ────────────────────────────────────────────────
class FirestoreOverrideService {
  static Future<int> forceMassFloodRouting() async {
    final col = FirebaseFirestore.instance.collection('crisis_reports');
    final snap = await col.get();
    final batch = FirebaseFirestore.instance.batch();
    int count = 0;
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'status': 'APPROVED',
        'text': 'MASS FLOOD EMERGENCY: Overridden by Admin',
        'ai_classification': {'action': 'APPROVED'},
        'ai_dispatches': [
          {'unit_type': 'RESCUE_1122', 'eta': '5m'},
          {'unit_type': 'KWSB_DRAINAGE', 'eta': '12m'}
        ],
        '_override_flag': 'MASS_FLOOD_ROUTING',
        '_override_ts': FieldValue.serverTimestamp(),
      });
      count++;
    }
    await batch.commit();
    return count;
  }

  static Future<void> clearOverrideFlags() async {
    final col = FirebaseFirestore.instance.collection('crisis_reports');
    final snap = await col.where('_override_flag', isNotEqualTo: null).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        '_override_flag': FieldValue.delete(),
        '_override_ts': FieldValue.delete(),
      });
    }
    await batch.commit();
  }

  static Future<void> injectTestBurst(int count) async {
    final col = FirebaseFirestore.instance.collection('crisis_reports');
    final rng = Random();
    final descriptions = [
      'Severe urban flooding reported in Saddar.',
      'Power grid failure detected in North Nazimabad.',
      'Major traffic gridlock on Shahrah-e-Faisal.',
      'Water main burst near Civic Center.',
    ];
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < count; i++) {
      final ref = col.doc();
      batch.set(ref, {
        'text': descriptions[rng.nextInt(descriptions.length)],
        'latitude': 24.70 + rng.nextDouble() * 0.40,
        'longitude': 66.80 + rng.nextDouble() * 0.50,
        'precipitation': 15.0 + rng.nextDouble() * 85.0,
        'status': 'PENDING',
        'ai_classification': {},
        'ai_dispatches': [],
        'timestamp': FieldValue.serverTimestamp(),
        '_test_burst': true,
      });
    }
    await batch.commit();
  }
}
