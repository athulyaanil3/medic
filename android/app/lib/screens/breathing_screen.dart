import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../theme/app_theme.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';
import 'dashboard_screen.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() =>
      _BreathingScreenState();
}

class _BreathingScreenState
    extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _c;

  final FlutterTts _tts =
  FlutterTts();

  bool _started = false;

  bool _sessionCompleted = false;

  // NEW
  bool _countdownStarted = false;

  int _countdown = 3;

  final int inhaleSecs = 4;

  final int holdSecs = 2;

  final int exhaleSecs = 6;

  int mood = -1;

  String currentPhase =
      "Inhale";

  @override
  void initState() {

    super.initState();

    _initAnimation();
  }

  void _initAnimation() {

    _c = AnimationController(

      vsync: this,

      duration: Duration(

        seconds:
        inhaleSecs +
            holdSecs +
            exhaleSecs,
      ),
    )

      ..addListener(() {

        final total =
            inhaleSecs +
                holdSecs +
                exhaleSecs;

        final current =
            _c.value * total;

        String phase;

        if (current <
            inhaleSecs) {

          phase = "Inhale";

        } else if (
        current <
            inhaleSecs +
                holdSecs) {

          phase = "Hold";

        } else {

          phase = "Exhale";
        }

        if (phase !=
            currentPhase) {

          currentPhase =
              phase;

          _speak(phase);
        }

        setState(() {});
      })

      ..addStatusListener((status) {

        if (status ==
            AnimationStatus.completed) {

          _stopExercise(
            completed: true,
          );
        }
      });
  }

  Future<void> _speak(
      String text) async {

    await _tts.stop();

    await _tts.setSpeechRate(
      0.4,
    );

    await _tts.speak(text);
  }

  // START WITH COUNTDOWN
  Future<void>
  _startExercise() async {

    setState(() {

      _countdownStarted =
      true;

      _countdown = 3;

      _started = false;

      _sessionCompleted =
      false;

      mood = -1;
    });

    for (int i = 3;
    i >= 1;
    i--) {

      setState(() {

        _countdown = i;
      });

      await _speak(
        i.toString(),
      );

      await Future.delayed(
        const Duration(
          seconds: 1,
        ),
      );
    }

    if (!mounted) return;

    setState(() {

      _countdownStarted =
      false;

      _started = true;

      currentPhase =
      "Inhale";
    });

    await _speak(
      "Start breathing",
    );

    _c.forward(from: 0);
  }

  void _stopExercise({
    bool completed = false,
  }) {

    _tts.stop();

    if (_c.isAnimating) {

      _c.stop();
    }

    if (mounted) {

      setState(() {

        _started = false;

        _countdownStarted =
        false;

        _sessionCompleted =
            completed;
      });
    }
  }

  @override
  void dispose() {

    _tts.stop();

    if (_c.isAnimating) {

      _c.stop();
    }

    _c.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {

    final total =
        inhaleSecs +
            holdSecs +
            exhaleSecs;

    final currentTime =
        _c.value * total;

    String phase;

    double scale;

    int secondsLeft;

    // INHALE
    if (currentTime <
        inhaleSecs) {

      phase = "Inhale";

      final progress =
          currentTime /
              inhaleSecs;

      scale = 0.85 +

          (0.20 *
              Curves.easeInOut
                  .transform(
                progress,
              ));

      secondsLeft =
          (inhaleSecs -
              currentTime)
              .ceil();

      // HOLD
    } else if (
    currentTime <
        inhaleSecs +
            holdSecs) {

      phase = "Hold";

      scale = 1.05;

      secondsLeft =
          ((inhaleSecs +
              holdSecs) -
              currentTime)
              .ceil();

      // EXHALE
    } else {

      phase = "Exhale";

      final exhaleProgress =

          (currentTime -
              inhaleSecs -
              holdSecs) /

              exhaleSecs;

      scale = 1.05 -

          (0.20 *
              Curves.easeInOut
                  .transform(
                exhaleProgress,
              ));

      secondsLeft =
          (total -
              currentTime)
              .ceil();
    }

    return Scaffold(

      body: MediBackground(

        child: SafeArea(

          child: Padding(

            padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            child: Column(

              children: [

                const SizedBox(
                    height: 18),

                const PageHeader(

                  title:
                  'Guided breathing',

                  subtitle:
                  'Relax your body and calm your mind.',
                ),

                const SizedBox(
                    height: 24),

                Expanded(

                  child: GlassCard(

                    padding:
                    const EdgeInsets.symmetric(

                      horizontal: 24,

                      vertical: 28,
                    ),

                    child: Column(

                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                      children: [

                        // BEFORE START
                        if (!_started &&
                            !_sessionCompleted &&
                            !_countdownStarted) ...[

                          const Icon(

                            Icons
                                .self_improvement_rounded,

                            size: 90,

                            color:
                            AppTheme
                                .deepTeal,
                          ),

                          const SizedBox(
                              height: 25),

                          const Text(

                            "Ready to relax?",

                            style:
                            TextStyle(

                              fontSize: 28,

                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),

                          const SizedBox(
                              height: 12),

                          const Text(

                            "Start your guided breathing exercise and calm your mind.",

                            textAlign:
                            TextAlign
                                .center,

                            style:
                            TextStyle(

                              color:
                              AppTheme
                                  .inkMuted,

                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(
                              height: 35),

                          SizedBox(

                            width:
                            double
                                .infinity,

                            height: 54,

                            child:
                            ElevatedButton
                                .icon(

                              onPressed:
                              _startExercise,

                              icon:
                              const Icon(
                                Icons
                                    .play_arrow_rounded,
                              ),

                              label:
                              const Text(
                                "Start Exercise",
                              ),

                              style:
                              ElevatedButton
                                  .styleFrom(

                                backgroundColor:
                                AppTheme
                                    .deepTeal,

                                foregroundColor:
                                Colors
                                    .white,

                                shape:
                                RoundedRectangleBorder(

                                  borderRadius:
                                  BorderRadius.circular(
                                    18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],

                        // COUNTDOWN
                        if (_countdownStarted) ...[

                          AnimatedContainer(

                            duration:
                            const Duration(
                              milliseconds:
                              300,
                            ),

                            width: 180,

                            height: 180,

                            decoration:
                            BoxDecoration(

                              shape:
                              BoxShape
                                  .circle,

                              color:
                              AppTheme
                                  .deepTeal,

                              boxShadow: [

                                BoxShadow(

                                  color:
                                  AppTheme
                                      .tealLight
                                      .withValues(
                                    alpha:
                                    0.4,
                                  ),

                                  blurRadius:
                                  30,
                                ),
                              ],
                            ),

                            child: Center(

                              child: Text(

                                '$_countdown',

                                style:
                                const TextStyle(

                                  color:
                                  Colors
                                      .white,

                                  fontSize:
                                  60,

                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                              height: 30),

                          const Text(

                            'Get Ready...',

                            style:
                            TextStyle(

                              fontSize: 22,

                              fontWeight:
                              FontWeight
                                  .bold,

                              color:
                              AppTheme
                                  .deepTeal,
                            ),
                          ),
                        ],

                        // ACTIVE SESSION
                        if (_started) ...[

                          AnimatedContainer(

                            duration:
                            const Duration(
                              milliseconds:
                              300,
                            ),

                            width:
                            180 * scale,

                            height:
                            180 * scale,

                            decoration:
                            BoxDecoration(

                              shape:
                              BoxShape
                                  .circle,

                              gradient:
                              RadialGradient(

                                colors: [

                                  AppTheme
                                      .mint
                                      .withValues(
                                    alpha:
                                    0.55,
                                  ),

                                  AppTheme
                                      .tealLight,

                                  AppTheme
                                      .deepTeal,
                                ],
                              ),

                              boxShadow: [

                                BoxShadow(

                                  color:
                                  AppTheme
                                      .tealLight
                                      .withValues(
                                    alpha:
                                    0.35,
                                  ),

                                  blurRadius:
                                  35,
                                ),
                              ],
                            ),

                            child: Center(

                              child: Text(

                                phase,

                                style:
                                const TextStyle(

                                  color:
                                  Colors
                                      .white,

                                  fontSize:
                                  30,

                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                              height: 30),

                          Text(

                            '$secondsLeft sec',

                            style:
                            const TextStyle(

                              fontSize: 34,

                              letterSpacing:
                              1,

                              fontWeight:
                              FontWeight
                                  .bold,

                              color:
                              AppTheme
                                  .deepTeal,
                            ),
                          ),

                          const SizedBox(
                              height: 12),

                          Text(

                            phase ==
                                "Inhale"

                                ? 'Breathe in slowly'

                                : phase ==
                                "Hold"

                                ? 'Hold your breath gently'

                                : 'Release your breath gently',

                            textAlign:
                            TextAlign
                                .center,

                            style:
                            const TextStyle(

                              color:
                              AppTheme
                                  .inkMuted,

                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(
                              height: 35),

                          SizedBox(

                            width:
                            double
                                .infinity,

                            height: 52,

                            child:
                            ElevatedButton
                                .icon(

                              onPressed:
                                  () {

                                _stopExercise();
                              },

                              icon:
                              const Icon(
                                Icons.pause,
                              ),

                              label:
                              const Text(
                                'Stop Exercise',
                              ),

                              style:
                              ElevatedButton
                                  .styleFrom(

                                backgroundColor:
                                Colors
                                    .redAccent,

                                foregroundColor:
                                Colors
                                    .white,

                                shape:
                                RoundedRectangleBorder(

                                  borderRadius:
                                  BorderRadius.circular(
                                    18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],

                        // SESSION COMPLETE
                        if (_sessionCompleted) ...[

                          const Icon(

                            Icons
                                .check_circle_rounded,

                            color:
                            Colors.green,

                            size: 70,
                          ),

                          const SizedBox(
                              height: 18),

                          const Text(

                            'Session Complete',

                            style:
                            TextStyle(

                              fontSize: 28,

                              fontWeight:
                              FontWeight
                                  .bold,

                              color:
                              AppTheme
                                  .deepTeal,
                            ),
                          ),

                          const SizedBox(
                              height: 12),

                          const Text(

                            'How do you feel now?',

                            textAlign:
                            TextAlign
                                .center,

                            style:
                            TextStyle(

                              color:
                              AppTheme
                                  .inkMuted,

                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(
                              height: 28),

                          Row(

                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceEvenly,

                            children: [

                              _moodButton(
                                  0,
                                  "😞"),

                              _moodButton(
                                  1,
                                  "😐"),

                              _moodButton(
                                  2,
                                  "😊"),
                            ],
                          ),

                          const SizedBox(
                              height: 32),

                          Row(

                            children: [

                              Expanded(

                                child:
                                OutlinedButton.icon(

                                  onPressed:
                                      () {

                                    Navigator.pushReplacement(

                                      context,

                                      MaterialPageRoute(

                                        builder: (_) =>
                                            DashboardScreen(
                                              goTab:
                                                  (index) {},
                                            ),
                                      ),
                                    );
                                  },

                                  icon:
                                  const Icon(
                                    Icons
                                        .close_rounded,
                                  ),

                                  label:
                                  const Text(
                                    "Exit",
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  width: 14),

                              Expanded(

                                child:
                                ElevatedButton
                                    .icon(

                                  onPressed:
                                  _startExercise,

                                  icon:
                                  const Icon(
                                    Icons
                                        .refresh_rounded,
                                  ),

                                  label:
                                  const Text(
                                    "Continue",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                    height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _moodButton(
      int value,
      String emoji) {

    final selected =
        mood == value;

    return GestureDetector(

      onTap: () {

        setState(() {
          mood = value;
        });
      },

      child: AnimatedContainer(

        duration:
        const Duration(
          milliseconds: 300,
        ),

        padding:
        const EdgeInsets.all(
            14),

        decoration:
        BoxDecoration(

          color:
          selected

              ? AppTheme
              .tealLight
              .withValues(
            alpha:
            0.25,
          )

              : Colors.white,

          shape:
          BoxShape.circle,

          boxShadow: [

            if (selected)

              BoxShadow(

                color:
                AppTheme
                    .tealLight
                    .withValues(
                  alpha:
                  0.3,
                ),

                blurRadius:
                12,
              ),
          ],
        ),

        child: Text(

          emoji,

          style:
          const TextStyle(
            fontSize: 32,
          ),
        ),
      ),
    );
  }
}