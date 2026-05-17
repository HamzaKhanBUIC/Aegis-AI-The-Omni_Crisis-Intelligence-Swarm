// ══════════════════════════════════════════════════════════════════════════════
// RIGHT PANE — DEVELOPER INFRASTRUCTURE CONTROLS & OVERRIDE SWITCHBOARD
// Administrative controls: simulation triggers, Firestore overrides, flags
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/aegis_admin_theme.dart';
import '../center_pane/live_log_streamer.dart';

class RightPane extends ConsumerStatefulWidget {
  const RightPane({super.key});

  @override
  ConsumerState<RightPane> createState() => _RightPaneState();
}

class _RightPaneState extends ConsumerState<RightPane>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExecuting = false;
  String? _lastResult;

  // Individual toggle states
  bool _realTimeMapSync = true;
  bool _agentAutoRestart = true;
  bool _anomalyDetection = true;
  bool _trustEngineLive = true;
  bool _testBurstMode = false;
  bool _devDebugOverlay = false;
  int _testBurstCount = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _executeOverride(
      String action, Future<void> Function() fn) async {
    setState(() => _isExecuting = true);
    ref.read(logStreamerProvider.notifier).injectOverrideLog(
        '[ADMIN] Executing override: $action...');
    try {
      await fn();
      setState(() {
        _lastResult = '✓ $action — SUCCESS';
        _isExecuting = false;
      });
      ref.read(logStreamerProvider.notifier).injectOverrideLog(
          '[ADMIN] Override complete: $action');
    } catch (e) {
      setState(() {
        _lastResult = '✗ $action — FAILED: ${e.toString().substring(0, min(60, e.toString().length))}';
        _isExecuting = false;
      });
      ref.read(logStreamerProvider.notifier).injectOverrideLog(
          '[ADMIN] Override FAILED: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverridesTab(),
              _buildToggleSwitchboard(),
              _buildSystemInfoTab(),
            ],
          ),
        ),
        if (_lastResult != null) _buildResultBanner(),
        const Divider(height: 1),
        // Log streamer at bottom of right pane
        const SizedBox(
          height: 220,
          child: LiveLogStreamer(),
        ),
      ],
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
              color: AegisAdminTheme.amber.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AegisAdminTheme.amber, size: 16),
          const SizedBox(width: 8),
          Text(
            'OVERRIDE SWITCHBOARD',
            style: AegisAdminTheme.mono(
                size: 11,
                color: AegisAdminTheme.amber,
                weight: FontWeight.bold,
                letterSpacing: 1.8),
          ),
          const Spacer(),
          if (_isExecuting)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AegisAdminTheme.amber),
            ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AegisAdminTheme.slateDark,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AegisAdminTheme.amber,
        indicatorWeight: 2,
        labelStyle: AegisAdminTheme.mono(
            size: 9, weight: FontWeight.bold, letterSpacing: 1.2),
        unselectedLabelStyle: AegisAdminTheme.mono(size: 9),
        labelColor: AegisAdminTheme.amber,
        unselectedLabelColor: AegisAdminTheme.textMuted,
        tabs: const [
          Tab(text: 'OVERRIDES'),
          Tab(text: 'TOGGLES'),
          Tab(text: 'SYSTEM'),
        ],
      ),
    );
  }

  // ── OVERRIDES TAB ─────────────────────────────────────────────────────────────
  Widget _buildOverridesTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── Mass Flood Routing ─────────────────────────────────────────────
        _buildDangerActionCard(
          icon: Icons.flood_rounded,
          title: 'FORCE MASS FLOOD ROUTING',
          subtitle:
              'Patches ALL crisis_reports docs to status=APPROVED + current_classification[action]=APPROVED. Stress-tests responder animation pipeline.',
          accentColor: AegisAdminTheme.danger,
          onTap: () => _executeOverride(
            'MASS FLOOD ROUTING',
            () async {
              final count =
                  await FirestoreOverrideService.forceMassFloodRouting();
              setState(() =>
                  _lastResult = '✓ MASS FLOOD — $count docs patched');
            },
          ),
          isLoading: _isExecuting,
        ),

        const SizedBox(height: 10),

        // ── Test Burst Inject ──────────────────────────────────────────────
        _buildActionCard(
          icon: Icons.bolt_rounded,
          title: 'INJECT TEST BURST',
          subtitle:
              'Creates $_testBurstCount synthetic PENDING crisis signals in crisis_reports for triage stress testing.',
          accentColor: AegisAdminTheme.amber,
          onTap: () => _executeOverride(
            'TEST BURST x$_testBurstCount',
            () => FirestoreOverrideService.injectTestBurst(_testBurstCount),
          ),
          isLoading: _isExecuting,
          trailing: _buildBurstCountStepper(),
        ),

        const SizedBox(height: 10),

        // ── Clear Override Flags ───────────────────────────────────────────
        _buildActionCard(
          icon: Icons.cleaning_services_rounded,
          title: 'CLEAR OVERRIDE FLAGS',
          subtitle:
              'Removes _override_flag metadata fields from all crisis_reports documents.',
          accentColor: AegisAdminTheme.cyan,
          onTap: () => _executeOverride(
            'CLEAR OVERRIDE FLAGS',
            FirestoreOverrideService.clearOverrideFlags,
          ),
          isLoading: _isExecuting,
        ),

        const SizedBox(height: 10),

        // ── Force Agent Recovery ───────────────────────────────────────────
        _buildActionCard(
          icon: Icons.restart_alt_rounded,
          title: 'FORCE AGENT RECOVERY',
          subtitle:
              'Resets all simulated agent nodes to ACTIVE status and normalizes latency to baseline.',
          accentColor: AegisAdminTheme.success,
          onTap: () {
            ref.read(agentSwarmProvider.notifier).forceAllActive();
            ref.read(logStreamerProvider.notifier).injectOverrideLog(
                '[ADMIN] Force recovery applied — all agents ACTIVE.');
            setState(() => _lastResult = '✓ Agent recovery applied');
          },
          isLoading: _isExecuting,
        ),
      ],
    );
  }

  // ── TOGGLES TAB ───────────────────────────────────────────────────────────────
  Widget _buildToggleSwitchboard() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionLabel('RUNTIME FLAGS'),
        const SizedBox(height: 8),
        _buildToggleRow(
          label: 'REAL-TIME MAP SYNC',
          sublabel: 'Live Firestore → map marker updates',
          value: _realTimeMapSync,
          color: AegisAdminTheme.cyan,
          onChanged: (v) => setState(() => _realTimeMapSync = v),
        ),
        _buildToggleRow(
          label: 'AGENT AUTO-RESTART',
          sublabel: 'Restart degraded agents automatically',
          value: _agentAutoRestart,
          color: AegisAdminTheme.cyan,
          onChanged: (v) => setState(() => _agentAutoRestart = v),
        ),
        _buildToggleRow(
          label: 'ANOMALY DETECTION',
          sublabel: 'Curveball contradiction sensor',
          value: _anomalyDetection,
          color: AegisAdminTheme.cyan,
          onChanged: (v) => setState(() => _anomalyDetection = v),
        ),
        _buildToggleRow(
          label: 'TRUTH ENGINE LIVE',
          sublabel: 'Enable real-time confidence scoring',
          value: _trustEngineLive,
          color: AegisAdminTheme.success,
          onChanged: (v) => setState(() => _trustEngineLive = v),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('DEVELOPER TOOLS'),
        const SizedBox(height: 8),
        _buildToggleRow(
          label: 'TEST BURST MODE',
          sublabel: 'Enable high-frequency injection mode',
          value: _testBurstMode,
          color: AegisAdminTheme.amber,
          onChanged: (v) {
            setState(() => _testBurstMode = v);
            ref.read(logStreamerProvider.notifier).injectOverrideLog(
                '[DEV] Test Burst Mode: ${v ? 'ENABLED' : 'DISABLED'}');
          },
        ),
        _buildToggleRow(
          label: 'DEBUG OVERLAY',
          sublabel: 'Show FPS + render metrics on map',
          value: _devDebugOverlay,
          color: AegisAdminTheme.amber,
          onChanged: (v) {
            setState(() => _devDebugOverlay = v);
            ref.read(logStreamerProvider.notifier).injectOverrideLog(
                '[DEV] Debug Overlay: ${v ? 'ENABLED' : 'DISABLED'}');
          },
        ),
      ],
    );
  }

  // ── SYSTEM INFO TAB ───────────────────────────────────────────────────────────
  Widget _buildSystemInfoTab() {
    final docs = ref.watch(crisisReportStreamProvider);
    final agents = ref.watch(agentSwarmProvider);
    final avgLatency = agents.isEmpty
        ? 0.0
        : agents.map((a) => a.latencyMs).reduce((a, b) => a + b) /
            agents.length;
    final avgTrust = agents.isEmpty
        ? 0.0
        : agents.map((a) => a.trustScore).reduce((a, b) => a + b) /
            agents.length;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionLabel('FIRESTORE'),
        const SizedBox(height: 8),
        _buildInfoRow(
            'COLLECTION', 'crisis_reports', AegisAdminTheme.cyan),
        _buildInfoRow(
            'DOC COUNT',
            docs.when(
              data: (d) => '${d.length}',
              loading: () => '...',
              error: (_, __) => 'ERR',
            ),
            AegisAdminTheme.textPrimary),
        _buildInfoRow(
            'ACTIVE DEPLOYMENTS',
            docs.when(
              data: (d) =>
                  '${d.where((x) => x.currentClassification['action'] == 'APPROVED').length}',
              loading: () => '...',
              error: (_, __) => 'ERR',
            ),
            AegisAdminTheme.success),
        _buildInfoRow('PROJECT', 'aegis-ai-omni', AegisAdminTheme.textSecond),

        const SizedBox(height: 16),
        _buildSectionLabel('SWARM AGGREGATE'),
        const SizedBox(height: 8),
        _buildInfoRow('ACTIVE AGENTS',
            '${agents.where((a) => a.status == AgentStatus.active).length}/${agents.length}',
            AegisAdminTheme.success),
        _buildInfoRow(
            'AVG LATENCY',
            '${avgLatency.toStringAsFixed(1)}ms',
            avgLatency > 100 ? AegisAdminTheme.danger : AegisAdminTheme.success),
        _buildInfoRow('AVG TRUST SCORE', '${avgTrust.toStringAsFixed(1)}%',
            AegisAdminTheme.success),

        const SizedBox(height: 16),
        _buildSectionLabel('ENVIRONMENT'),
        const SizedBox(height: 8),
        _buildInfoRow('MODE', 'ADMIN WEB', AegisAdminTheme.amber),
        _buildInfoRow('VERSION', '1.1.0 (Crisis Data Refactor)', AegisAdminTheme.textSecond),
        _buildInfoRow('BUILD TARGET', 'web', AegisAdminTheme.textSecond),
        _buildInfoRow('MAP PROVIDER', 'CartoDB Dark', AegisAdminTheme.textSecond),
        _buildInfoRow('REGION', 'Karachi, PK', AegisAdminTheme.cyan),
      ],
    );
  }

  // ── Result Banner ─────────────────────────────────────────────────────────────
  Widget _buildResultBanner() {
    final isSuccess = _lastResult!.startsWith('✓');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: isSuccess
          ? AegisAdminTheme.success.withOpacity(0.08)
          : AegisAdminTheme.danger.withOpacity(0.08),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            size: 14,
            color: isSuccess ? AegisAdminTheme.success : AegisAdminTheme.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lastResult!,
              style: AegisAdminTheme.mono(
                  size: 10,
                  color: isSuccess
                      ? AegisAdminTheme.success
                      : AegisAdminTheme.danger),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _lastResult = null),
            child: const Icon(Icons.close,
                size: 14, color: AegisAdminTheme.textMuted),
          ),
        ],
      ),
    );
  }

  // ── Action Cards ──────────────────────────────────────────────────────────────
  Widget _buildDangerActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.35), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: AegisAdminTheme.mono(
                            size: 11,
                            color: accentColor,
                            weight: FontWeight.bold,
                            letterSpacing: 0.8),
                      ),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: accentColor),
                      )
                    else
                      Icon(Icons.play_arrow_rounded,
                          color: accentColor, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: AegisAdminTheme.mono(
                        size: 9.5, color: AegisAdminTheme.textMuted),
                    maxLines: 3),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withOpacity(0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isLoading ? 'EXECUTING...' : '⚡ EXECUTE OVERRIDE',
                    style: AegisAdminTheme.mono(
                        size: 10,
                        color: accentColor,
                        weight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    required bool isLoading,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AegisAdminTheme.slateDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: AegisAdminTheme.mono(
                        size: 11,
                        color: AegisAdminTheme.textPrimary,
                        weight: FontWeight.bold)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle,
              style: AegisAdminTheme.mono(
                  size: 9.5, color: AegisAdminTheme.textMuted),
              maxLines: 2),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: isLoading ? null : onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Text(
                isLoading ? 'EXECUTING...' : 'RUN',
                style: AegisAdminTheme.mono(
                    size: 10, color: accentColor, weight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle Row ────────────────────────────────────────────────────────────────
  Widget _buildToggleRow({
    required String label,
    required String sublabel,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.05) : AegisAdminTheme.slateDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : AegisAdminTheme.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AegisAdminTheme.mono(
                        size: 10,
                        color: value ? color : AegisAdminTheme.textSecond,
                        weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(sublabel,
                    style: AegisAdminTheme.mono(
                        size: 8.5, color: AegisAdminTheme.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.25),
            inactiveThumbColor: AegisAdminTheme.textMuted,
            inactiveTrackColor: AegisAdminTheme.border,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      '// $label',
      style: AegisAdminTheme.mono(
          size: 9, color: AegisAdminTheme.textMuted, letterSpacing: 1.0),
    );
  }

  Widget _buildInfoRow(String key, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(key,
                style: AegisAdminTheme.mono(
                    size: 9.5, color: AegisAdminTheme.textMuted)),
          ),
          Text(value,
              style: AegisAdminTheme.mono(
                  size: 10, color: valueColor, weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBurstCountStepper() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _testBurstCount = max(1, _testBurstCount - 1)),
          child: const Icon(Icons.remove_circle_outline,
              color: AegisAdminTheme.textMuted, size: 18),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$_testBurstCount',
            style: AegisAdminTheme.mono(
                size: 13,
                color: AegisAdminTheme.amber,
                weight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: () =>
              setState(() => _testBurstCount = min(50, _testBurstCount + 1)),
          child: const Icon(Icons.add_circle_outline,
              color: AegisAdminTheme.textMuted, size: 18),
        ),
      ],
    );
  }
}
