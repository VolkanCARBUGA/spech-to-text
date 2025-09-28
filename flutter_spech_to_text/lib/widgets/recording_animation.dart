import 'package:flutter/material.dart';

class RecordingPulse extends StatefulWidget {
  const RecordingPulse({super.key, required this.size, required this.color});
  final double size;
  final Color color;

  @override
  State<RecordingPulse> createState() => _RecordingPulseState();
}

class _RecordingPulseState extends State<RecordingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scale = Tween<double>(begin: 0.9, end: 1.25)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);
    _opacity = Tween<double>(begin: 0.35, end: 0.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}