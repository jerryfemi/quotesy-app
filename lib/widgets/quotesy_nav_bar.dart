import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const _kAmber = Color(0xFFB8860B);
const _kAmberGlow = Color(0xFFD4A017);

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
  // Controller is created once and provided via scope.
  // No manual listener needed — InheritedNotifier handles propagation.
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
        backgroundColor: const Color(0xFF050505),
        extendBody: true,
        body: Stack(
          children: [
            widget.navigationShell,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              // QuotesyNavBar now reads visible from the scope itself.
              // No currentIndex/visible props need to flow through setState.
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

// ─────────────────────────────────────────────────────────────────────────────
// _NavBarConsumer
//
// Thin wrapper that reads `visible` from NavBarControllerScope and passes it
// to QuotesyNavBar. Because it calls dependOnInheritedWidgetOfExactType,
// only this subtree rebuilds when visibility changes — not QuotesyShell.
// ─────────────────────────────────────────────────────────────────────────────
class _NavBarConsumer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavBarConsumer({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visible = NavBarControllerScope.of(context).visible;
    return QuotesyNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      visible: visible,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuotesyNavBar
//
// Center: compact Home/Explore pill.
// Right: detached circular Saved button.
// AnimatedSlide with Offset(0, 2.0) — safe ceiling that fully clears any
// device height, replacing the fragile 1.8 value.
// ─────────────────────────────────────────────────────────────────────────────
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

    return AnimatedSlide(
      // 2.0 = guaranteed full hide on any device height, replacing fragile 1.8
      offset: visible ? Offset.zero : const Offset(0, 2.0),
      duration: const Duration(milliseconds: 250),
      curve: visible ? Curves.easeOut : Curves.easeIn,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            height: 52,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x8C000000), // black @ 55%
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Color(0x14B8860B), // amber @ 8%
                          blurRadius: 20,
                          spreadRadius: -4,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PillTabButton(
                          icon: Icons.auto_awesome_outlined,
                          label: 'Home',
                          isActive: isHome,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onTap(0);
                          },
                        ),
                        const SizedBox(width: 6),
                        _PillTabButton(
                          icon: Icons.explore_outlined,
                          label: 'Explore',
                          isActive: isExplore,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onTap(1);
                          },
                        ),
                      ],
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
                      // Animate the border/bg alpha so the glow actually
                      // transitions — AnimatedContainer can't interpolate
                      // BoxShadow, TweenAnimationBuilder can.
                      tween: Tween(begin: 0.0, end: isSaved ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      builder: (context, t, _) {
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0xFF111111),
                              _kAmber.withValues(alpha: 0.20),
                              t,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color.lerp(
                                Colors.white.withValues(alpha: 0.07),
                                _kAmber.withValues(alpha: 0.45),
                                t,
                              )!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              // Amber glow only animates when saved
                              if (t > 0)
                                BoxShadow(
                                  color: _kAmber.withValues(alpha: 0.15 * t),
                                  blurRadius: 12,
                                  spreadRadius: -2,
                                ),
                            ],
                          ),
                          child: Icon(
                            Icons.bookmark_outline_rounded,
                            size: 20,
                            color: Color.lerp(
                              Colors.white38,
                              _kAmberGlow,
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
  final VoidCallback onTap;

  const _PillTabButton({
    required this.icon,
    required this.label,
    required this.isActive,
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
              ? _kAmber.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? _kAmber.withValues(alpha: 0.35)
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
              color: isActive ? _kAmberGlow : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
                color: isActive ? _kAmberGlow : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}