import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../theme/app_theme.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';

/// 4-2-6 breathing: inhale 4s, hold 2s, exhale 6s per cycle.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const _inhaleSecs = 4;
  static const _holdSecs = 2;
  static const _exhaleSecs = 6;
  static const _cycleSecs = _inhaleSecs + _holdSecs + _exhaleSecs;
  static const _sessionCycles = 5;

  AnimationController? _anim;
  final FlutterTts _tts = FlutterTts();

  bool _countdownActive = false;
  int _countdown = 3;
  bool _running = false;
  bool _completed = false;
  int _cycleIndex = 0;
  int _mood = -1;
  String _phase = 'Inhale';
  String? _lastSpokenPhase;

  AnimationController get _controller {
    _ensureAnim();
    return _anim!;
  }

  void _ensureAnim() {
    if (_anim != null) return;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _cycleSecs),
    )
      ..addListener(_onAnimTick)
      ..addStatusListener(_onAnimStatus);
  }

  @override
  void initState() {
    super.initState();
    _ensureAnim();
    unawaited(_initTts());
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload can leave State alive without a controller.
    final wasRunning = _running;
    final cycle = _cycleIndex;
    _anim?.dispose();
    _anim = null;
    _ensureAnim();
    if (wasRunning) {
      _cycleIndex = cycle;
      _controller.value = 0;
      _controller.forward();
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    _anim?.dispose();
    _anim = null;
    super.dispose();
  }

  void _onAnimTick() {
    if (!_running || _anim == null) return;

    final t = _controller.value * _cycleSecs;
    String phase;
    if (t < _inhaleSecs) {
      phase = 'Inhale';
    } else if (t < _inhaleSecs + _holdSecs) {
      phase = 'Hold';
    } else {
      phase = 'Exhale';
    }

    if (phase != _phase) {
      _phase = phase;
      _speakPhase(phase);
    }
    setState(() {});
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_running) return;

    _cycleIndex++;
    if (_cycleIndex < _sessionCycles) {
      _controller.reset();
      _controller.forward();
      return;
    }
    _finishSession();
  }

  void _speakPhase(String phase) {
    if (_lastSpokenPhase == phase) return;
    _lastSpokenPhase = phase;
    unawaited(_tts.stop());
    unawaited(_tts.speak(phase));
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _startSession() async {
    if (_countdownActive || _running) return;

    setState(() {
      _countdownActive = true;
      _countdown = 3;
      _running = false;
      _completed = false;
      _cycleIndex = 0;
      _mood = -1;
      _phase = 'Inhale';
      _lastSpokenPhase = null;
    });

    for (var i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      unawaited(_speak('$i'));
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    setState(() {
      _countdownActive = false;
      _running = true;
      _phase = 'Inhale';
    });

    unawaited(_speak('Start breathing'));
    _controller.reset();
    _controller.forward();
  }

  void _stopSession({bool completed = false}) {
    unawaited(_tts.stop());
    if (_anim?.isAnimating ?? false) {
      _controller.stop();
    }
    _controller.reset();
    if (!mounted) return;
    setState(() {
      _running = false;
      _countdownActive = false;
      _completed = completed;
      _lastSpokenPhase = null;
    });
  }

  void _finishSession() {
    _stopSession(completed: true);
  }

  void _resetToStart() {
    _stopSession();
    setState(() {
      _completed = false;
      _countdown = 3;
      _cycleIndex = 0;
      _mood = -1;
    });
  }

  _BreathVisual _visual() {
    final t = _controller.value * _cycleSecs;

    if (t < _inhaleSecs) {
      final p = t / _inhaleSecs;
      return _BreathVisual(
        phase: 'Inhale',
        scale: 0.85 + 0.2 * Curves.easeInOut.transform(p),
        secondsLeft: (_inhaleSecs - t).ceil().clamp(1, _inhaleSecs),
        hint: 'Breathe in slowly',
      );
    }
    if (t < _inhaleSecs + _holdSecs) {
      return _BreathVisual(
        phase: 'Hold',
        scale: 1.05,
        secondsLeft: ((_inhaleSecs + _holdSecs) - t).ceil().clamp(1, _holdSecs),
        hint: 'Hold gently',
      );
    }

    final p = (t - _inhaleSecs - _holdSecs) / _exhaleSecs;
    return _BreathVisual(
      phase: 'Exhale',
      scale: 1.05 - 0.2 * Curves.easeInOut.transform(p),
      secondsLeft: (_cycleSecs - t).ceil().clamp(1, _exhaleSecs),
      hint: 'Breathe out slowly',
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureAnim();
    final visual = _running ? _visual() : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MediBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 18),
                const PageHeader(
                  title: 'Guided breathing',
                  subtitle: '4 sec in · 2 sec hold · 6 sec out — 5 calm cycles.',
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_running && !_completed && !_countdownActive)
                          ..._buildIntro(context)
                        else if (_countdownActive)
                          ..._buildCountdown()
                        else if (_running && visual != null)
                          ..._buildActive(visual)
                        else if (_completed)
                          ..._buildComplete(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildIntro(BuildContext context) {
    return [
      const Icon(Icons.self_improvement_rounded, size: 88, color: AppTheme.deepTeal),
      const SizedBox(height: 24),
      Text(
        'Ready to relax?',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Find a comfortable seat. Tap start when you are ready.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.inkMuted, fontSize: 15, height: 1.45),
      ),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: _startSession,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start session'),
        ),
      ),
    ];
  }

  List<Widget> _buildCountdown() {
    return [
      _BreathCircle(
        size: 180,
        child: Text(
          '$_countdown',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 60,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Text(
        'Get ready…',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.deepTeal,
        ),
      ),
    ];
  }

  List<Widget> _buildActive(_BreathVisual visual) {
    return [
      Text(
        'Cycle ${_cycleIndex + 1} of $_sessionCycles',
        style: const TextStyle(color: AppTheme.inkMuted, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 20),
      _BreathCircle(
        size: 180 * visual.scale,
        gradient: true,
        child: Text(
          visual.phase,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 28),
      Text(
        '${visual.secondsLeft}s',
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: AppTheme.deepTeal,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        visual.hint,
        style: const TextStyle(color: AppTheme.inkMuted, fontSize: 15),
      ),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: () => _stopSession(),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Stop'),
        ),
      ),
    ];
  }

  List<Widget> _buildComplete(BuildContext context) {
    return [
      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 68),
      const SizedBox(height: 16),
      Text(
        'Session complete',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.deepTeal,
            ),
      ),
      const SizedBox(height: 10),
      const Text(
        'How do you feel now?',
        style: TextStyle(color: AppTheme.inkMuted, fontSize: 15),
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _moodChip(0, '😞'),
          _moodChip(1, '😐'),
          _moodChip(2, '😊'),
        ],
      ),
      const SizedBox(height: 28),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetToStart,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Done'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _startSession,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Again'),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _moodChip(int value, String emoji) {
    final selected = _mood == value;
    return GestureDetector(
      onTap: () => setState(() => _mood = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.tealLight.withValues(alpha: 0.25) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: selected
              ? [BoxShadow(color: AppTheme.tealLight.withValues(alpha: 0.3), blurRadius: 12)]
              : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }
}

class _BreathVisual {
  const _BreathVisual({
    required this.phase,
    required this.scale,
    required this.secondsLeft,
    required this.hint,
  });

  final String phase;
  final double scale;
  final int secondsLeft;
  final String hint;
}

class _BreathCircle extends StatelessWidget {
  const _BreathCircle({
    required this.size,
    required this.child,
    this.gradient = false,
  });

  final double size;
  final Widget child;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient ? null : AppTheme.deepTeal,
        gradient: gradient
            ? const RadialGradient(
                colors: [
                  Color(0x8C5EEAD4),
                  AppTheme.tealLight,
                  AppTheme.deepTeal,
                ],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.tealLight.withValues(alpha: 0.35),
            blurRadius: 30,
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
