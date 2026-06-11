import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});

  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<OverlayBubble> {
  Color _color = Colors.green;
  int _elapsed = 0;
  int _threshold = 70;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          if (data['color'] != null) _color = Color(data['color'] as int);
          if (data['elapsed'] != null) _elapsed = data['elapsed'] as int;
          if (data['threshold'] != null) _threshold = data['threshold'] as int;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_elapsed / _threshold).clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: _color.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 2),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 4,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '${_elapsed}s',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
