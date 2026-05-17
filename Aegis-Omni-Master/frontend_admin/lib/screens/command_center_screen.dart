// ══════════════════════════════════════════════════════════════════════════════
// AEGIS-OMNI ADMIN — COMMAND CENTER SCREEN
// 3-Column tactical grid: Left(40%) Map | Center(35%) Telemetry | Right(25%) Dev
// Optimized for 1080p+ widescreen desktop browsers
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../widgets/left_pane/karachi_tactical_map.dart';
import '../widgets/center_pane/center_pane.dart';
import '../widgets/right_pane/right_pane.dart';
import '../widgets/top_bar.dart';
import '../theme/aegis_admin_theme.dart';

class CommandCenterScreen extends StatelessWidget {
  const CommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisAdminTheme.canvas,
      appBar: const AegisAdminTopBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // ── Responsive: collapse to vertical on narrow viewports ──────────
          if (width < 900) {
            return _buildNarrowLayout(height);
          }

          // ── Full 3-Column Desktop Layout ──────────────────────────────────
          return _buildDesktopLayout(width, height);
        },
      ),
    );
  }

  // ── Desktop: 3-column grid ────────────────────────────────────────────────
  Widget _buildDesktopLayout(double width, double height) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT PANE — 40%
        SizedBox(
          width: width * 0.40,
          child: const KarachiTacticalMap(),
        ),

        // CENTER PANE — 35%
        SizedBox(
          width: width * 0.35,
          child: const CenterPane(),
        ),

        // RIGHT PANE — 25%
        Expanded(
          child: const RightPane(),
        ),
      ],
    );
  }

  // ── Narrow: stacked vertical columns ─────────────────────────────────────
  Widget _buildNarrowLayout(double height) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 400,
            child: const KarachiTacticalMap(),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 500,
            child: const CenterPane(),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 600,
            child: const RightPane(),
          ),
        ],
      ),
    );
  }
}
