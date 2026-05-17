import 'package:flutter/material.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/logic_feed_sidebar.dart';
import '../theme/dark_ops_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AEGIS-SOVEREIGN // DIGITAL TWIN'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: DarkOpsTheme.errorRed.withOpacity(0.2),
              border: Border.all(color: DarkOpsTheme.errorRed),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: DarkOpsTheme.errorRed, size: 16),
                SizedBox(width: 8),
                Text('DEFCON 3', style: TextStyle(color: DarkOpsTheme.errorRed, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: const Row(
        children: [
          // Left Side: The Interactive Map
          Expanded(
            flex: 7,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: HeatmapWidget(),
            ),
          ),
          
          // Right Side: Live Swarm Logic Feed
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 16.0, right: 16.0),
              child: LogicFeedSidebar(),
            ),
          ),
        ],
      ),
    );
  }
}
