// ══════════════════════════════════════════════════════════════════════════════
// AEGIS-OMNI ADMIN — TOP NAVIGATION BAR
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aegis_admin_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class AegisAdminTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AegisAdminTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDocs = ref.watch(crisisReportStreamProvider);
    final agents = ref.watch(agentSwarmProvider);
    final activeAgents = agents.where((a) => a.status == AgentStatus.active).length;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AegisAdminTheme.canvas,
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1F1F24), width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Brand ──────────────────────────────────────────────────────────
          Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AegisAdminTheme.cyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AegisAdminTheme.cyan.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: AegisAdminTheme.cyan, size: 16),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AEGIS-OMNI',
                      style: AegisAdminTheme.mono(
                          size: 11,
                          color: AegisAdminTheme.textPrimary,
                          weight: FontWeight.bold,
                          letterSpacing: 2.0),
                    ),
                    Text(
                      'ADMIN COMMAND CENTER',
                      style: AegisAdminTheme.mono(
                          size: 7.5,
                          color: AegisAdminTheme.textMuted,
                          letterSpacing: 1.2),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF1F1F24)),

          // ── System Status Chips ────────────────────────────────────────────
          const SizedBox(width: 16),
          _TopChip(
            label: 'SWARM',
            value: '$activeAgents/${agents.length} AGENTS',
            color: activeAgents == agents.length
                ? AegisAdminTheme.success
                : AegisAdminTheme.amber,
          ),
          const SizedBox(width: 8),
          asyncDocs.when(
            data: (docs) => _TopChip(
              label: 'SIGNALS',
              value: '${docs.length} DOCS',
              color: AegisAdminTheme.cyan,
            ),
            loading: () => _TopChip(
                label: 'SIGNALS', value: 'SYNCING...', color: AegisAdminTheme.textMuted),
            error: (_, __) => _TopChip(
                label: 'SIGNALS', value: 'ERR', color: AegisAdminTheme.danger),
          ),
          const SizedBox(width: 8),
          asyncDocs.when(
            data: (docs) {
              final active = docs.where((d) => d.currentClassification['action'] == 'APPROVED').length;
              return _TopChip(
                label: 'ACTIVE DEPLOYMENTS',
                value: '$active UNITS',
                color: active > 0 ? AegisAdminTheme.danger : AegisAdminTheme.textMuted,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Spacer(),

          // ── Clock + Region ────────────────────────────────────────────────
          _LiveClock(),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AegisAdminTheme.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
              border:
                  Border.all(color: AegisAdminTheme.amber.withOpacity(0.3)),
            ),
            child: Text(
              '📍 KARACHI, PK',
              style: AegisAdminTheme.mono(
                  size: 9.5,
                  color: AegisAdminTheme.amber,
                  weight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// ── Top Status Chip ───────────────────────────────────────────────────────────
class _TopChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TopChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AegisAdminTheme.mono(size: 7, color: AegisAdminTheme.textMuted)),
          Text(value,
              style: AegisAdminTheme.mono(
                  size: 9.5, color: color, weight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Live Clock ────────────────────────────────────────────────────────────────
class _LiveClock extends StatefulWidget {
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late String _timeStr;
  late Future<void> _future;

  String _fmt() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _timeStr = _fmt();
    _tick();
  }

  void _tick() {
    _future = Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _timeStr = _fmt());
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeStr,
      style: AegisAdminTheme.mono(
          size: 13,
          color: AegisAdminTheme.textSecond,
          weight: FontWeight.bold,
          letterSpacing: 2),
    );
  }
}
