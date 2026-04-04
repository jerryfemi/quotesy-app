import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/streak_model.dart';
import '../providers/database_provider.dart';
import '../services/notifications.dart';
import '../theme/quotesy_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 1500);
  static const _minimumVisibleDuration = Duration(milliseconds: 1800);
  static const _handoffFadeDuration = Duration(milliseconds: 260);

  late final AnimationController _controller;
  late final AnimationController _exitController;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<double> _iconTiltAnimation;
  late final Animation<double> _ambientPulseAnimation;
  late final Animation<double> _iconFadeAnimation;
  late final Animation<double> _brandFadeAnimation;
  late final Animation<Offset> _brandSlideAnimation;
  late final Animation<double> _brandShimmerAnimation;
  late final Animation<Color?> _esyColorAnimation;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _exitController = AnimationController(
      vsync: this,
      duration: _handoffFadeDuration,
    );

    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOutCubic),
    );

    _ambientPulseAnimation = Tween<double>(begin: 0.82, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.76, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.58, curve: Curves.easeOutBack),
      ),
    );

    _iconTiltAnimation = Tween<double>(begin: -0.10, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.52, curve: Curves.easeOutCubic),
      ),
    );

    _iconFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.72, curve: Curves.easeIn),
      ),
    );

    _brandFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );

    _brandSlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.10), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.22, 0.80, curve: Curves.easeOutCubic),
          ),
        );

    _brandShimmerAnimation = Tween<double>(begin: -1.3, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.98, curve: Curves.easeInOut),
      ),
    );

    _esyColorAnimation = ColorTween(begin: QColors.textPrimary, end: QColors.amberGlow)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.56, 0.94, curve: Curves.easeInOutCubic),
          ),
        );

    _runStartupFlow();
  }

  Future<void> _runStartupFlow() async {
    final initDB = ref.read(databaseInitProvider.future);
    _initOtherServices();

    await Future.wait([
      _controller.forward(),
      initDB,
      Future<void>.delayed(_minimumVisibleDuration),
    ]);

    if (!mounted) return;
    final streak = ref.read(streakProvider.notifier).reconcileOnAppOpen();

    await _exitController.forward();
    if (!mounted) return;
    context.go('/home');

    unawaited(_runPostHandoffSync(streak));
  }

  void _initOtherServices() {
    unawaited(_safeInitRevenueCat());
    unawaited(Notifications().initialize());
  }

  Future<void> _safeInitRevenueCat() async {
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
      await Purchases.configure(
        PurchasesConfiguration('goog_xrjdqrwqgLqwUvrGwcDUnxBBHKP'),
      );
    } catch (error, stack) {
      debugPrint('RevenueCat init failed (continuing): $error\n$stack');
    }
  }

  Future<void> _runPostHandoffSync(StreakData streak) async {
    final db = ref.read(databaseServiceProvider);
    await Notifications().initializeAndSync(database: db, streak: streak);
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QColors.obsidian,
      body: FadeTransition(
        opacity: _exitOpacity,
        child: Stack(
          children: [
            Positioned.fill(
              child: _SplashBackdrop(ambientPulse: _ambientPulseAnimation),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _iconFadeAnimation,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconTiltAnimation.value,
                          child: Transform.scale(
                            scale: _iconScaleAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          color: QColors.textPrimary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: QColors.textPrimary.withValues(alpha: 0.10),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: QColors.amberGlow.withValues(alpha: 0.12),
                              blurRadius: 24,
                              spreadRadius: -6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: QColors.textMuted,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  FadeTransition(
                    opacity: _brandFadeAnimation,
                    child: SlideTransition(
                      position: _brandSlideAnimation,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'Playfair Display',
                                    fontSize: 62,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    height: 0.9,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'QUOT',
                                      style: TextStyle(color: QColors.textPrimary),
                                    ),
                                    TextSpan(
                                      text: 'ESY',
                                      style: TextStyle(
                                        color: _esyColorAnimation.value,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IgnorePointer(
                                child: FractionalTranslation(
                                  translation: Offset(
                                    _brandShimmerAnimation.value,
                                    0,
                                  ),
                                  child: Container(
                                    width: 120,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          QColors.amberGlow.withValues(
                                            alpha: 0.08,
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _brandFadeAnimation,
                    child: Container(
                      width: 54,
                      height: 2,
                      color: QColors.textPrimary.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop({required this.ambientPulse});

  final Animation<double> ambientPulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientPulse,
      builder: (context, _) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [QColors.surface, QColors.obsidian],
              stops: [0.0, 0.6],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: const Alignment(0.85, -0.72),
                child: Transform.scale(
                  scale: ambientPulse.value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: QColors.textPrimary.withValues(alpha: 0.03),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(-0.9, 0.88),
                child: Transform.scale(
                  scale: 2.0 - ambientPulse.value,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: QColors.textPrimary.withValues(alpha: 0.02),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
