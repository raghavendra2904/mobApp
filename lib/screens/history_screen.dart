import 'package:flutter/material.dart';

import '../models/alarm_event.dart';
import '../services/history_service.dart';
import '../widgets/scaffold_background.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AlarmEvent> _events = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await HistoryService.recent(limit: 500);
    if (!mounted) return;
    setState(() {
      _events = e;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Alarm history'),
          actions: [
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear all history?'),
                    content: const Text(
                        'This will permanently delete all logged alarms.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await HistoryService.clear();
                  _load();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
                  ? const Center(
                      child: Text('No alarms logged yet.',
                          style: TextStyle(color: Colors.white70)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final e = _events[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber,
                                  color: Colors.amberAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_fmt(e.triggeredAt),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                      'Tilt ${e.avgTiltDegrees.toStringAsFixed(0)}° • held ${e.sustainedSeconds}s',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }
}
