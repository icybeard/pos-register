import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/hifi.dart';

/// Self-ticking timestamp displayed in HifiChrome. Updates every 30s
/// because we render minutes-precision; faster ticks waste rebuilds.
///
/// Usage: drop into `HifiChrome.extras` (or anywhere else). The widget
/// owns its own timer and disposes it cleanly.
///
/// Format: `dd.mm.yyyy HH:MM` — matches the Variant C hi-fi spec
/// (`pos-docs/hifi/...`). If the design needs seconds, bump the period
/// to 1 s and update [_format].
class HifiLiveClock extends StatefulWidget {
  const HifiLiveClock({
    super.key,
    this.color,
    this.size = 11,
    this.tick = const Duration(seconds: 30),
  });

  /// Foreground color. Defaults to a translucent white over the navy chrome.
  final Color? color;

  /// Font size in logical pixels. Default 11pt matches the hi-fi spec.
  final double size;

  /// Tick interval. Default 30s — the displayed format only shows minutes,
  /// so 1 s would be wasted rebuilds.
  final Duration tick;

  @override
  State<HifiLiveClock> createState() => _HifiLiveClockState();
}

class _HifiLiveClockState extends State<HifiLiveClock> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(widget.tick, (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}.${p(d.month)}.${d.year} ${p(d.hour)}:${p(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.white.withValues(alpha: 0.6);
    return Text(
      _format(_now),
      style: Hifi.mono(size: widget.size, color: color),
    );
  }
}
