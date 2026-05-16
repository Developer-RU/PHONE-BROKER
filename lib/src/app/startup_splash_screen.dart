import 'package:flutter/material.dart';

class StartupSplashScreen extends StatefulWidget {
  const StartupSplashScreen({
    super.key,
    required this.progress,
    required this.statusMessage,
  });

  final double progress;
  final String statusMessage;

  @override
  State<StartupSplashScreen> createState() => _StartupSplashScreenState();
}

class _StartupSplashScreenState extends State<StartupSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B1015);
    const accent = Color(0xFF36C2A0);
    const accentSoft = Color(0xFF2EA98C);
    final normalized = widget.progress.clamp(0.0, 1.0);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FadeTransition(
                        opacity: Tween<double>(
                          begin: 0.24,
                          end: 0.55,
                        ).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0x6636C2A0),
                                Color(0x332EA98C),
                                Color(0x0036C2A0),
                              ],
                              stops: [0.1, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      RotationTransition(
                        turns: CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeInOut,
                        ),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.85),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.9,
                          end: 1.06,
                        ).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(
                              0.0,
                              0.6,
                              curve: Curves.easeOut,
                            ),
                            reverseCurve: const Interval(
                              0.4,
                              1.0,
                              curve: Curves.easeIn,
                            ),
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/splash_logo.png',
                          width: 112,
                          height: 112,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MQTT HUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.statusMessage,
                  style: const TextStyle(
                    color: Color(0xFF9AA7B5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: normalized),
                  builder: (context, animatedProgress, child) {
                    final percent = (animatedProgress * 100).round();
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: animatedProgress,
                            backgroundColor: const Color(0xFF1B242E),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              accentSoft,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            color: Color(0xFFB6C3D1),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
