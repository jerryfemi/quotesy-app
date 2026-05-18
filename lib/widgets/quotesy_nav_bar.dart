import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/navigation_shell.dart';
import '../theme/quotesy_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NavBarController
//
// ChangeNotifier that owns hide/show state, driven by ScrollNotifications.
// Dead-zone accumulator prevents jitter from micro scroll deltas.
// ─────────────────────────────────────────────────────────────────────────────
class NavBarController extends ChangeNotifier {
  bool _visible = true;
  double _accumulator = 0.0;
  static const double _deadZone = 8.0;

  bool get visible => _visible;

  bool onScroll(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      _accumulator = 0.0;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0.0;
      if (delta == 0.0) return false;

      _accumulator += delta;
      if (_accumulator > _deadZone) {
        _accumulator = 0.0;
        if (_visible) {
          _visible = false;
          notifyListeners();
        }
      } else if (_accumulator < -_deadZone) {
        _accumulator = 0.0;
        if (!_visible) {
          _visible = true;
          notifyListeners();
        }
      }
    }

    return false;
  }

  void show() {
    if (!_visible) {
      _visible = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_visible) {
      _visible = false;
      notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NavBarControllerScope
// ─────────────────────────────────────────────────────────────────────────────
class NavBarControllerScope extends InheritedNotifier<NavBarController> {
  const NavBarControllerScope({
    super.key,
    required NavBarController controller,
    required super.child,
  }) : super(notifier: controller);

  static NavBarController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NavBarControllerScope>();
    assert(scope != null, 'NavBarControllerScope missing from widget tree.');
    return scope!.notifier!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuotesyShell
// ─────────────────────────────────────────────────────────────────────────────
class QuotesyShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const QuotesyShell({super.key, required this.navigationShell});

  @override
  State<QuotesyShell> createState() => _QuotesyShellState();
}

class _QuotesyShellState extends State<QuotesyShell> {
  final NavBarController _navBarController = NavBarController();

  @override
  void dispose() {
    _navBarController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    _navBarController.show();
  }

  @override
  Widget build(BuildContext context) {
    return NavBarControllerScope(
      controller: _navBarController,
      child: Scaffold(
        backgroundColor: QNavColors.shellBackground,
        extendBody: true,
        body: Stack(
          children: [
            widget.navigationShell,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _NavBarConsumer(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _onTabTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarConsumer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavBarConsumer({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visible = NavBarControllerScope.of(context).visible;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.2),
      duration: const Duration(milliseconds: 220),
      curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: NavBar(currentIndex: currentIndex, onTap: onTap),
          ),
        ),
      ),
    );
  }
}

/*
Previous implementation (commented out as requested)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quotesy/routes/navigation_shell.dart';
import '../theme/quotesy_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NavBarController
//
// ChangeNotifier that owns hide/show state.
// Dead-zone accumulator prevents jitter from micro-scroll deltas.
// ─────────────────────────────────────────────────────────────────────────────
class NavBarController extends ChangeNotifier {
  bool _visible = true;
  double _accumulator = 0.0;
  static const double _deadZone = 8.0;

  bool get visible => _visible;

  void onDrag(double deltaY) {
    _accumulator += deltaY;
    if (_accumulator < -_deadZone) {
      _accumulator = 0.0;
      if (_visible) {
        _visible = false;
        notifyListeners();
      }
    } else if (_accumulator > _deadZone) {
      _accumulator = 0.0;
      if (!_visible) {
        _visible = true;
        notifyListeners();
      }
    }
  }

  void onDragEnd() => _accumulator = 0.0;

  void show() {
    if (!_visible) {
      _visible = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_visible) {
      _visible = false;
      notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NavBarControllerScope
//
// InheritedNotifier — any widget that calls .of(context) will automatically
// rebuild when the controller notifies. No manual addListener needed.
// ─────────────────────────────────────────────────────────────────────────────
class NavBarControllerScope extends InheritedNotifier<NavBarController> {
  const NavBarControllerScope({
    super.key,
    required NavBarController controller,
    required super.child,
  }) : super(notifier: controller);

  static NavBarController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NavBarControllerScope>();
    assert(scope != null, 'NavBarControllerScope missing from widget tree.');
    return scope!.notifier!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuotesyShell
//
// FIX: Removed the manual _rebuild listener + setState pattern.
// Previously _QuotesyShellState was listening to NavBarController and calling
// setState, which rebuilt the entire shell (including navigationShell) on
// every hide/show event. Now QuotesyNavBar reads `visible` directly from the
// scope via dependOnInheritedWidgetOfExactType, so only the nav bar subtree
// rebuilds — not the whole shell.
// ─────────────────────────────────────────────────────────────────────────────
class QuotesyShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const QuotesyShell({super.key, required this.navigationShell});

  @override
  State<QuotesyShell> createState() => _QuotesyShellState();
}

class _QuotesyShellState extends State<QuotesyShell> {
  final NavBarController _navBarController = NavBarController();

  @override
  void dispose() {
    _navBarController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    _navBarController.show();
  }

  @override
  Widget build(BuildContext context) {
    return NavBarControllerScope(
      controller: _navBarController,
      child: Scaffold(
        backgroundColor: QNavColors.shellBackground,
        extendBody: true,
        body: Stack(
          children: [
            widget.navigationShell,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,

              child: _NavBarConsumer(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _onTabTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarConsumer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavBarConsumer({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visible = NavBarControllerScope.of(context).visible;
    return NavBar(currentIndex: currentIndex,onTap: onTap );
  }
}

class QuotesyNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool visible;

  const QuotesyNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    final isHome = currentIndex == 0;
    final isExplore = currentIndex == 1;
    final isSaved = currentIndex == 2;
    final rawScale = MediaQuery.textScalerOf(context).scale(1.0);
    final navLabelScale = rawScale.clamp(1.0, 1.08);
    final navHeight = rawScale > 1.2 ? 56.0 : 52.0;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 2.0),
      duration: const Duration(milliseconds: 250),
      curve: visible ? Curves.easeOut : Curves.easeIn,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            height: navHeight,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    // Reserve room for the detached Saved circle at large text scales.
                    padding: const EdgeInsets.only(right: 56),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: QNavColors.pillBackground,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: QNavColors.pillBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PillTabButton(
                            icon: Icons.format_quote_outlined,
                            label: 'Home',
                            isActive: isHome,
                            labelScale: navLabelScale,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onTap(0);
                            },
                          ),
                          const SizedBox(width: 6),
                          _PillTabButton(
                            icon: Icons.travel_explore_outlined,
                            label: 'Explore',
                            isActive: isExplore,
                            labelScale: navLabelScale,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onTap(1);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap(2);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: isSaved ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      builder: (context, t, _) {
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              QNavColors.pillBackground,
                              QNavColors.accent.withValues(alpha: 0.20),
                              t,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color.lerp(
                                QNavColors.pillBorder,
                                QNavColors.accent.withValues(alpha: 0.45),
                                t,
                              )!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: QNavColors.detachedShadow,
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              // Amber glow only animates when saved
                              if (t > 0)
                                BoxShadow(
                                  color: QNavColors.accent.withValues(
                                    alpha: 0.15 * t,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: -2,
                                ),
                            ],
                          ),
                          child: Icon(
                            Icons.bookmark_outline_rounded,
                            size: 20,
                            color: Color.lerp(
                              QNavColors.inactive,
                              QNavColors.accentGlow,
                              t,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final double labelScale;
  final VoidCallback onTap;

  const _PillTabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.labelScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? QNavColors.accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? QNavColors.accent.withValues(alpha: 0.35)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? QNavColors.accentGlow : QNavColors.inactive,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              textScaler: TextScaler.linear(labelScale),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
                color: isActive ? QNavColors.accentGlow : QNavColors.inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

*/
