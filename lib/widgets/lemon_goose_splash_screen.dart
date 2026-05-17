import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';

class LemonGooseSplashScreen extends StatefulWidget {
  const LemonGooseSplashScreen({super.key});

  static const String logoAsset = 'assets/Images/GooseLogo.png';

  @override
  State<LemonGooseSplashScreen> createState() => _LemonGooseSplashScreenState();
}

class _LemonGooseSplashScreenState extends State<LemonGooseSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: 0.94,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Lemon Goose Games Inc.',
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                LightcorePalette.night,
                LightcorePalette.abyss,
                Color(0xFF1B1C1E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: LightcorePalette.solar.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 42,
                              spreadRadius: -12,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.36),
                              blurRadius: 28,
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            LemonGooseSplashScreen.logoAsset,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
