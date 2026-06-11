import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/crash_logger.dart';
import '../widgets/scaffold_background.dart';

class CrashLogScreen extends StatefulWidget {
  const CrashLogScreen({super.key});
  @override
  State<CrashLogScreen> createState() => _CrashLogScreenState();
}

class _CrashLogScreenState extends State<CrashLogScreen> {
  String _log = 'Loading…';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await CrashLogger.readAll();
    if (!mounted) return;
    setState(() => _log = s);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Crash logs'),
          actions: [
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _log));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await CrashLogger.clear();
                _load();
              },
            ),
            IconButton(
              tooltip: 'Reload',
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _log,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
