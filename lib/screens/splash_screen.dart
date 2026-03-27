import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/database_provider.dart';
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
  late final Animation<Offset> _dropAnimation;
  late final Animation<double> _iconFadeAnimation;
  late final Animation<double> _brandFadeAnimation;
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

    _dropAnimation = Tween<Offset>(
      begin: const Offset(0, -0.30),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

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

    _esyColorAnimation = ColorTween(begin: Colors.white, end: QColors.amberGlow)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.56, 0.94, curve: Curves.easeInOutCubic),
          ),
        );

    _runStartupFlow();
  }

  Future<void> _runStartupFlow() async {
    final initFuture = ref.read(databaseInitProvider.future);

    await Future.wait([
      _controller.forward(),
      initFuture,
      Future<void>.delayed(_minimumVisibleDuration),
    ]);

    if (!mounted) return;
    await _exitController.forward();
    if (!mounted) return;
    context.go('/home');
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
            const Positioned.fill(child: _SplashBackdrop()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SlideTransition(
                    position: _dropAnimation,
                    child: FadeTransition(
                      opacity: _iconFadeAnimation,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white70,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  FadeTransition(
                    opacity: _brandFadeAnimation,
                    child: AnimatedBuilder(
                      animation: _esyColorAnimation,
                      builder: (context, _) {
                        return RichText(
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
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'ESY',
                                style: TextStyle(
                                  color: _esyColorAnimation.value,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _brandFadeAnimation,
                    child: Container(
                      width: 54,
                      height: 2,
                      color: Colors.white.withValues(alpha: 0.10),
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
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13191D), QColors.obsidian],
          stops: [0.0, 0.6],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(0.85, -0.72),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.9, 0.88),
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
