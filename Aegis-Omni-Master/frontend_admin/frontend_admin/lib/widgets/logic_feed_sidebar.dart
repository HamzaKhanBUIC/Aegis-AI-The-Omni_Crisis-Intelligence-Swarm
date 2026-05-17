import 'package:flutter/material.dart';
import '../theme/dark_ops_theme.dart';

class LogicFeedSidebar extends StatelessWidget {
  const LogicFeedSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data representing the internal swarm thoughts
    final List<Map<String, dynamic>> logs = [
      {
        "agent": "Orchestrator",
        "action": "Received payload 05a42b... Routing to Vision Specialist.",
        "color": Colors.white,
        "time": "00:00:12"
      },
      {
        "agent": "Vision Specialist",
        "action": "Visual Verification Complete. Flood indicators positive (92%).",
        "color": DarkOpsTheme.accent,
        "time": "00:00:14"
      },
      {
        "agent": "Cyber Trust",
        "action": "Cross-referenced visual data with IoT grid. Verified.",
        "color": DarkOpsTheme.accent,
        "time": "00:00:15"
      },
      {
        "agent": "Orchestrator",
        "action": "CRITICAL: Threshold met. Triggering Climate Cascade Logic.",
        "color": DarkOpsTheme.errorRed,
        "time": "00:00:16"
      },
      {
        "agent": "Fin Officer",
        "action": "Initiating BackupLoan for affected user subset (Karachi_South).",
        "color": Colors.orangeAccent,
        "time": "00:00:18"
      },
      {
        "agent": "Fin Officer",
        "action": "Transaction 0x77a9... confirmed on Ledger.",
        "color": Colors.greenAccent,
        "time": "00:00:19"
      },
    ];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2A2A35))),
            ),
            child: const Text(
              'LIVE SWARM LOGIC FEED',
              style: TextStyle(
                color: DarkOpsTheme.accent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogItem(
                  agent: log['agent'],
                  action: log['action'],
                  color: log['color'],
                  time: log['time'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem({
    required String agent,
    required String action,
    required Color color,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '[$time]',
          style: const TextStyle(
            color: DarkOpsTheme.textSecondary,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '// $agent',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action,
                style: const TextStyle(
                  color: DarkOpsTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
