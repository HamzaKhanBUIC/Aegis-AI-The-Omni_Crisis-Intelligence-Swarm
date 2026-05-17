// ══════════════════════════════════════════════════════════════════════════════
// CENTER PANE — AGENT SWARM MONITOR
// Real-time health monitor for LangGraph backend agents
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/aegis_admin_theme.dart';

class AgentSwarmMonitor extends ConsumerStatefulWidget {
  const AgentSwarmMonitor({super.key});

  @override
  ConsumerState<AgentSwarmMonitor> createState() => _AgentSwarmMonitorState();
}

class _AgentSwarmMonitorState extends ConsumerState<AgentSwarmMonitor>
    with TickerProviderStateMixin {
  // Per-agent pulse animations
  final Map<String, AnimationController> _pulseCtrl = {};
  final Map<String, Animation<double>> _pulseAnim = {};

  @override
  void initState() {
    super.initState();
    final agentIds = [
      'agent_triage',
      'truth_engine',
      'vision_specialist',
      'command_dispatcher'
    ];
    for (final id in agentIds) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 900 + Random().nextInt(600)),
      )..repeat(reverse: true);
      _pulseCtrl[id] = ctrl;
      _pulseAnim[id] = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _pulseCtrl.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agents = ref.watch(agentSwarmProvider);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AegisAdminTheme.border.withOpacity(0.5), width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: agents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _buildAgentCard(agents[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AegisAdminTheme.canvas,
        border: Border(
          bottom: BorderSide(
              color: AegisAdminTheme.cyan.withOpacity(0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_tree_rounded,
              color: AegisAdminTheme.cyan, size: 16),
          const SizedBox(width: 8),
          Text(
            'SWARM AGENT MONITOR',
            style: AegisAdminTheme.mono(
                size: 11,
                color: AegisAdminTheme.cyan,
                weight: FontWeight.bold,
                letterSpacing: 1.8),
          ),
          const Spacer(),
          _PulsingDot(color: AegisAdminTheme.success),
          const SizedBox(width: 6),
          Text('LIVE',
              style: AegisAdminTheme.mono(
                  size: 9, color: AegisAdminTheme.success, weight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Agent Card ────────────────────────────────────────────────────────────────
  Widget _buildAgentCard(AgentNode agent) {
    final statusColor = _statusColor(agent.status);
    final anim = _pulseAnim[agent.id];

    return AnimatedBuilder(
      animation: anim ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AegisAdminTheme.slateDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: statusColor.withOpacity(
                  agent.status == AgentStatus.active
                      ? (anim?.value ?? 1.0) * 0.4
                      : 0.5),
              width: 1,
            ),
            boxShadow: agent.status == AgentStatus.active
                ? [
                    BoxShadow(
                      color: statusColor.withOpacity(0.05),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status orb
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(anim?.value ?? 1.0),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    agent.displayName,
                    style: AegisAdminTheme.mono(
                      size: 12,
                      color: AegisAdminTheme.textPrimary,
                      weight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(status: agent.status),
                ],
              ),
              const SizedBox(height: 10),

              // Metrics Row
              Row(
                children: [
                  _MetricChip(
                    label: 'LATENCY',
                    value: '${agent.latencyMs}ms',
                    color: agent.latencyMs > 100
                        ? AegisAdminTheme.danger
                        : agent.latencyMs > 60
                            ? AegisAdminTheme.amber
                            : AegisAdminTheme.success,
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    label: 'TRUST',
                    value: '${agent.trustScore}%',
                    color: agent.trustScore > 95
                        ? AegisAdminTheme.success
                        : agent.trustScore > 85
                            ? AegisAdminTheme.amber
                            : AegisAdminTheme.danger,
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    label: 'PROCESSED',
                    value: '${agent.processedCount}',
                    color: AegisAdminTheme.cyan,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Trust Score bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: agent.trustScore / 100,
                  minHeight: 3,
                  backgroundColor: AegisAdminTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(AgentStatus s) {
    switch (s) {
      case AgentStatus.active:
        return AegisAdminTheme.success;
      case AgentStatus.degraded:
        return AegisAdminTheme.amber;
      case AgentStatus.offline:
        return AegisAdminTheme.danger;
    }
  }
}

// ── JSON Payload Inspector ────────────────────────────────────────────────────
class JsonPayloadInspector extends ConsumerWidget {
  const JsonPayloadInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDocs = ref.watch(crisisReportStreamProvider);
    final selected = ref.watch(selectedDocProvider);

    return Column(
      children: [
        _buildInspectorHeader(),
        // Document selector list
        SizedBox(
          height: 120,
          child: asyncDocs.when(
            data: (docs) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final doc = docs[i];
                final isSelected = selected?.id == doc.id;
                return GestureDetector(
                  onTap: () =>
                      ref.read(selectedDocProvider.notifier).state = doc,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 160,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AegisAdminTheme.cyan.withOpacity(0.12)
                          : AegisAdminTheme.slateDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AegisAdminTheme.cyan.withOpacity(0.7)
                            : AegisAdminTheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: AegisAdminTheme.cyan.withOpacity(0.1),
                                  blurRadius: 10)
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doc.id.substring(0, min(12, doc.id.length)).toUpperCase(),
                                style: AegisAdminTheme.mono(
                                  size: 9,
                                  color: isSelected
                                      ? AegisAdminTheme.cyan
                                      : AegisAdminTheme.textMuted,
                                  weight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildTriagePhaseIcon(doc),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          doc.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AegisAdminTheme.mono(
                              size: 10, color: AegisAdminTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        _TriageBadge(doc: doc),
                      ],
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AegisAdminTheme.cyan)),
            error: (e, _) => Center(
                child: Text('Error',
                    style: AegisAdminTheme.mono(color: AegisAdminTheme.danger))),
          ),
        ),

        const Divider(height: 1),

        // JSON Terminal View
        Expanded(
          child: Container(
            color: const Color(0xFF060607),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: selected == null
                ? _buildNoSelection()
                : _buildJsonView(selected),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectorHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AegisAdminTheme.canvas,
        border: Border(
          bottom: BorderSide(
              color: AegisAdminTheme.amber.withOpacity(0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.data_object_rounded,
              color: AegisAdminTheme.amber, size: 16),
          const SizedBox(width: 8),
          Text(
            'CRISIS PAYLOAD INSPECTOR',
            style: AegisAdminTheme.mono(
                size: 11,
                color: AegisAdminTheme.amber,
                weight: FontWeight.bold,
                letterSpacing: 1.8),
          ),
          const Spacer(),
          Text('LIVE STREAM',
              style: AegisAdminTheme.mono(size: 9, color: AegisAdminTheme.success)),
        ],
      ),
    );
  }

  Widget _buildNoSelection() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.terminal_rounded,
              color: AegisAdminTheme.textMuted, size: 32),
          const SizedBox(height: 10),
          Text(
            '// Awaiting document selection...',
            style: AegisAdminTheme.mono(color: AegisAdminTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonView(CrisisReport doc) {
    final json = doc.rawData;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('// DOC_REF: ${doc.id}',
                  style: AegisAdminTheme.mono(
                      size: 9, color: AegisAdminTheme.textMuted)),
              const Spacer(),
              if (doc.status == 'PENDING')
                const _SpinningRadar(size: 12)
              else
                Icon(Icons.verified_user_rounded, 
                    color: doc.currentClassification['action'] == 'APPROVED' 
                        ? AegisAdminTheme.success 
                        : AegisAdminTheme.danger, 
                    size: 14),
            ],
          ),
          const SizedBox(height: 12),
          
          // Resource Dispatches Highlight (if approved)
          if (doc.resourceDispatches.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AegisAdminTheme.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AegisAdminTheme.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DEPLOYMENT_MANIFEST', 
                      style: AegisAdminTheme.mono(size: 9, color: AegisAdminTheme.success, weight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...doc.resourceDispatches.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right_rounded, size: 12, color: AegisAdminTheme.success),
                        const SizedBox(width: 6),
                        Text('${d['unit_type']} ', style: AegisAdminTheme.mono(size: 10, color: AegisAdminTheme.textPrimary)),
                        const Spacer(),
                        Text('ETA: ${d['eta']}', style: AegisAdminTheme.mono(size: 10, color: AegisAdminTheme.success)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          Text('{',
              style: AegisAdminTheme.mono(
                  color: AegisAdminTheme.textSecond, size: 14)),
          ...json.entries.map((e) => _buildJsonLine(e.key, e.value, indent: 1)),
          Text('}',
              style: AegisAdminTheme.mono(
                  color: AegisAdminTheme.textSecond, size: 14)),
        ],
      ),
    );
  }

  Widget _buildJsonLine(String key, dynamic value, {int indent = 1}) {
    Color valueColor;
    String valueStr;

    if (value == null) {
      valueColor = AegisAdminTheme.textMuted;
      valueStr = 'null';
    } else if (value is String) {
      valueColor = AegisAdminTheme.success;
      valueStr = '"$value"';
    } else if (value is num) {
      valueColor = AegisAdminTheme.cyan;
      valueStr = '$value';
    } else if (value is bool) {
      valueColor = AegisAdminTheme.amber;
      valueStr = '$value';
    } else if (value is Map) {
      return Padding(
        padding: EdgeInsets.only(left: 16.0 * indent, top: 2, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"$key": {', style: AegisAdminTheme.mono(color: AegisAdminTheme.cyan, size: 12)),
            ...value.entries.map((e) => _buildJsonLine(e.key.toString(), e.value, indent: indent + 1)),
            Text('},', style: AegisAdminTheme.mono(color: AegisAdminTheme.cyan, size: 12)),
          ],
        ),
      );
    } else if (value is List) {
      return Padding(
        padding: EdgeInsets.only(left: 16.0 * indent, top: 2, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"$key": [', style: AegisAdminTheme.mono(color: AegisAdminTheme.cyan, size: 12)),
            ...value.map((v) => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text('$v,', style: AegisAdminTheme.mono(color: AegisAdminTheme.textPrimary, size: 12)),
            )),
            Text('],', style: AegisAdminTheme.mono(color: AegisAdminTheme.cyan, size: 12)),
          ],
        ),
      );
    } else {
      valueColor = AegisAdminTheme.textSecond;
      valueStr = value.toString();
    }

    return Padding(
      padding: EdgeInsets.only(left: 16.0 * indent, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"$key": ',
              style:
                  AegisAdminTheme.mono(color: AegisAdminTheme.cyan, size: 12)),
          Expanded(
            child: Text(
              valueStr,
              style: AegisAdminTheme.mono(color: valueColor, size: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriagePhaseIcon(CrisisReport doc) {
    if (doc.status == 'PENDING') {
      return const _SpinningRadar(size: 14);
    }
    final action = doc.currentClassification['action'];
    if (action == 'APPROVED') {
      return const Icon(Icons.check_circle_rounded, color: AegisAdminTheme.success, size: 14);
    }
    if (action == 'REJECTED') {
      return const Icon(Icons.cancel_rounded, color: AegisAdminTheme.danger, size: 14);
    }
    return const Icon(Icons.hourglass_empty_rounded, color: AegisAdminTheme.textMuted, size: 14);
  }
}

// ── Triage Badges ─────────────────────────────────────────────────────────────
class _TriageBadge extends StatelessWidget {
  final CrisisReport doc;
  const _TriageBadge({required this.doc});

  @override
  Widget build(BuildContext context) {
    if (doc.status == 'PENDING') {
      return _Badge(label: 'TRIAGE_PENDING', color: AegisAdminTheme.amber);
    }
    final action = doc.currentClassification['action'];
    if (action == 'APPROVED') {
      return _Badge(label: 'SWARM ACCEPTS', color: AegisAdminTheme.success);
    }
    if (action == 'REJECTED') {
      return _Badge(label: 'ZERO-TRUST REJECTED', color: AegisAdminTheme.danger);
    }
    return _Badge(label: doc.status, color: AegisAdminTheme.textMuted);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: AegisAdminTheme.mono(
              size: 8,
              color: color,
              weight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }
}

class _SpinningRadar extends StatefulWidget {
  final double size;
  const _SpinningRadar({this.size = 16});

  @override
  State<_SpinningRadar> createState() => _SpinningRadarState();
}

class _SpinningRadarState extends State<_SpinningRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Icon(Icons.radar_rounded, color: AegisAdminTheme.amber, size: widget.size),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CENTER PANE COMPOSITE
// ══════════════════════════════════════════════════════════════════════════════
class CenterPane extends StatelessWidget {
  const CenterPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: AegisAdminTheme.borderCyan.withOpacity(0.6),
            width: 1,
          ),
        ),
      ),
      child: const Column(
        children: [
          // Agent Monitor takes 45% of height
          Expanded(flex: 45, child: AgentSwarmMonitor()),
          // JSON Inspector takes 55%
          Expanded(flex: 55, child: JsonPayloadInspector()),
        ],
      ),
    );
  }
}

// ── Shared Sub-Widgets ────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final AgentStatus status;
  final bool compact;
  const _StatusBadge({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Color c;
    String label;
    switch (status) {
      case AgentStatus.active:
        c = AegisAdminTheme.success;
        label = 'ACTIVE';
        break;
      case AgentStatus.degraded:
        c = AegisAdminTheme.amber;
        label = 'DEGRADED';
        break;
      case AgentStatus.offline:
        c = AegisAdminTheme.danger;
        label = 'OFFLINE';
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 7, vertical: compact ? 1 : 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Text(label,
          style: AegisAdminTheme.mono(
              size: compact ? 8 : 9,
              color: c,
              weight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    AegisAdminTheme.mono(size: 8, color: AegisAdminTheme.textMuted)),
            const SizedBox(height: 2),
            Text(value,
                style: AegisAdminTheme.mono(
                    size: 11, color: color, weight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: widget.color.withOpacity(0.5 * _anim.value),
                blurRadius: 6)
          ],
        ),
      ),
    );
  }
}
