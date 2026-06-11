import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/history_service.dart';
import '../widgets/scaffold_background.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, int> _counts = {};
  bool _loaded = false;
  int _windowDays = 14;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await HistoryService.countsByDay(days: _windowDays);
    if (!mounted) return;
    setState(() {
      _counts = c;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Analytics'),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.calendar_today),
              onSelected: (v) {
                setState(() => _windowDays = v);
                _load();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 7, child: Text('Last 7 days')),
                PopupMenuItem(value: 14, child: Text('Last 14 days')),
                PopupMenuItem(value: 30, child: Text('Last 30 days')),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final keys = _counts.keys.toList()..sort();
    final values = keys.map((k) => _counts[k] ?? 0).toList();
    final total = values.fold<int>(0, (a, b) => a + b);
    final avg = values.isEmpty ? 0.0 : total / values.length;

    // Trend: average of last third vs first third
    final third = (values.length / 3).floor();
    final firstAvg = values.take(third).fold<int>(0, (a, b) => a + b) /
        (third == 0 ? 1 : third);
    final lastAvg = values.reversed.take(third).fold<int>(0, (a, b) => a + b) /
        (third == 0 ? 1 : third);
    final improving = lastAvg < firstAvg;
    final delta = (firstAvg - lastAvg).abs();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatRow(total: total, avg: avg, days: _windowDays),
        const SizedBox(height: 16),
        Container(
          height: 280,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (values.isEmpty ? 5 : values.reduce((a, b) => a > b ? a : b) + 2)
                  .toDouble(),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= keys.length) {
                        return const SizedBox.shrink();
                      }
                      // Show every other label to keep readable
                      if (keys.length > 10 && i % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      final parts = keys[i].split('-');
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${parts[2]}/${parts[1]}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10)),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (v) =>
                    const FlLine(color: Colors.white12, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < values.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: values[i].toDouble(),
                      color: values[i] == 0
                          ? Colors.white24
                          : Colors.tealAccent.shade400,
                      width: 14,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _TrendCard(
          improving: improving,
          delta: delta,
          haveData: total > 0,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final int total;
  final double avg;
  final int days;
  const _StatRow({required this.total, required this.avg, required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(value: '$total', label: 'Alerts (last $days days)')),
        const SizedBox(width: 12),
        Expanded(child: _Stat(value: avg.toStringAsFixed(1), label: 'Avg per day')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final bool improving;
  final double delta;
  final bool haveData;
  const _TrendCard(
      {required this.improving, required this.delta, required this.haveData});

  @override
  Widget build(BuildContext context) {
    String headline;
    String body;
    Color color;
    IconData icon;
    if (!haveData) {
      headline = 'No data yet';
      body =
          'Keep monitoring active. As you accumulate days of use, this page '
          'will show whether your neck-bending habits are improving.';
      color = Colors.white70;
      icon = Icons.hourglass_empty;
    } else if (improving) {
      headline = 'You are improving';
      body =
          'Your daily alerts have dropped by an average of '
          '${delta.toStringAsFixed(1)} per day across the window. Keep using a '
          'phone stand and bringing the device to eye level — it is working.';
      color = Colors.greenAccent;
      icon = Icons.trending_down;
    } else if (delta < 0.5) {
      headline = 'Steady';
      body =
          'Your alert rate is roughly flat. Try a chin-tuck every 20 minutes '
          'and lower the threshold slightly in Settings to challenge yourself.';
      color = Colors.amberAccent;
      icon = Icons.trending_flat;
    } else {
      headline = 'Trending the wrong way';
      body =
          'Your alerts are up by about ${delta.toStringAsFixed(1)} per day '
          'recently. Consider holding the phone higher, taking breaks every '
          '20 minutes, and reviewing the tips in "Why it matters".';
      color = Colors.redAccent;
      icon = Icons.trending_up;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline,
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(body,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
