import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/streak_model.dart';
import '../providers/database_provider.dart';
import '../services/notifications.dart';
import '../theme/quotesy_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 1500);
  static const _minimumVisibleDuration = Duration(milliseconds: 1900);

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration);

    // Slow, elegant fade in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Very subtle, continuous cinematic scale (Ken Burns effect)
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutSine),
    );

    _runStartupFlow();
  }

  Future<void> _runStartupFlow() async {
    final initDB = ref.read(databaseInitProvider.future);
    unawaited(Notifications().initialize());

    await Future.wait([
      _controller.forward(),
      initDB,
      Future<void>.delayed(_minimumVisibleDuration),
    ]);

    if (!mounted) return;
    final streak = ref.read(streakProvider.notifier).reconcileOnAppOpen();
    
    // GoRouter will handle the fade transition if configured in app_router.dart
    context.go('/home'); 
    
    unawaited(Notifications().initializeAndSync(
      database: ref.read(databaseServiceProvider), 
      streak: streak,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QColors.obsidian,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 48, // Slightly smaller, more elegant
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4.0, // Wider tracking looks premium
                ),
                children: [
                  TextSpan(
                    text: 'QUOT',
                    style: TextStyle(color: QColors.textPrimary),
                  ),
                  TextSpan(
                    text: 'ESY',
                    style: TextStyle(color: QColors.amberGlow),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
