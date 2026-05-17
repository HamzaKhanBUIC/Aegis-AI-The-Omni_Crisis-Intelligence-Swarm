// ══════════════════════════════════════════════════════════════════════════════
// LOG STREAMER — Terminal-style live feed widget
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/aegis_admin_theme.dart';

class LiveLogStreamer extends ConsumerStatefulWidget {
  const LiveLogStreamer({super.key});

  @override
  ConsumerState<LiveLogStreamer> createState() => _LiveLogStreamerState();
}

class _LiveLogStreamerState extends ConsumerState<LiveLogStreamer> {
  final ScrollController _scroll = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeAutoScroll() {
    if (_autoScroll && _scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logStreamerProvider);
    _maybeAutoScroll();

    return Container(
      color: const Color(0xFF060607),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: logs.length,
              itemBuilder: (ctx, i) => _LogLine(entry: logs[i]),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: AegisAdminTheme.canvas,
      child: Row(
        children: [
          const Icon(Icons.terminal_rounded,
              color: AegisAdminTheme.success, size: 14),
          const SizedBox(width: 8),
          Text(
            'ORCHESTRATION FEED',
            style: AegisAdminTheme.mono(
                size: 10,
                color: AegisAdminTheme.success,
                weight: FontWeight.bold,
                letterSpacing: 1.5),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _autoScroll = !_autoScroll),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _autoScroll
                    ? AegisAdminTheme.success.withOpacity(0.1)
                    : AegisAdminTheme.border,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                    color: _autoScroll
                        ? AegisAdminTheme.success.withOpacity(0.4)
                        : AegisAdminTheme.border),
              ),
              child: Text(
                _autoScroll ? 'AUTO ▼' : 'PAUSED',
                style: AegisAdminTheme.mono(
                    size: 8,
                    color: _autoScroll
                        ? AegisAdminTheme.success
                        : AegisAdminTheme.textMuted,
                    weight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final logs = ref.read(logStreamerProvider);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: AegisAdminTheme.canvas.withOpacity(0.6),
      child: Row(
        children: [
          Text('${logs.length} ENTRIES',
              style: AegisAdminTheme.mono(
                  size: 9, color: AegisAdminTheme.textMuted)),
          const Spacer(),
          Text('aegis-omni/orchestrator',
              style: AegisAdminTheme.mono(
                  size: 9, color: AegisAdminTheme.textMuted)),
        ],
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  final LogEntry entry;
  const _LogLine({required this.entry});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss.SSS').format(entry.time);
    final levelColor = _levelColor(entry.level);
    final levelStr = _levelStr(entry.level);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(timeStr,
              style: AegisAdminTheme.mono(
                  size: 9, color: AegisAdminTheme.textMuted)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(levelStr,
                style: AegisAdminTheme.mono(
                    size: 8,
                    color: levelColor,
                    weight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Text('[${entry.source}]',
              style: AegisAdminTheme.mono(
                  size: 10, color: AegisAdminTheme.cyan)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entry.message,
              style: AegisAdminTheme.mono(
                  size: 10, color: AegisAdminTheme.textSecond),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(LogLevel l) {
    switch (l) {
      case LogLevel.info:
        return AegisAdminTheme.success;
      case LogLevel.warn:
        return AegisAdminTheme.amber;
      case LogLevel.error:
        return AegisAdminTheme.danger;
      case LogLevel.system:
        return AegisAdminTheme.cyan;
    }
  }

  String _levelStr(LogLevel l) {
    switch (l) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warn:
        return 'WARN';
      case LogLevel.error:
        return 'ERR ';
      case LogLevel.system:
        return 'SYS ';
    }
  }
}
