import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Everything nav-bar related lives here:
//   1. NavBarController  — hide/show logic
//   2. NavBarControllerScope — propagates controller down the tree
//   3. QuotesyShell      — the persistent scaffold that owns the controller
//   4. QuotesyNavBar     — the floating pill UI
// ─────────────────────────────────────────────────────────────────────────────

const _kAmber = Color(0xFFB8860B);
const _kAmberGlow = Color(0xFFD4A017);

// ── 1. NavBarController ───────────────────────────────────────────────────────
// Raw pointer delta + 8px dead zone.
// Owned by QuotesyShell — lives for the shell's entire lifetime.
class NavBarController extends ChangeNotifier {
  bool _visible = true;
  double _accumulator = 0.0;
  static const double _deadZone = 8.0;

  bool get visible => _visible;

  void onDrag(double deltaY) {
    _accumulator += deltaY;
    if (_accumulator < -_deadZone) {
      _accumulator = 0.0;
      if (_visible) { _visible = false; notifyListeners(); }
    } else if (_accumulator > _deadZone) {
      _accumulator = 0.0;
      if (!_visible) { _visible = true; notifyListeners(); }
    }
  }

  void onDragEnd() => _accumulator = 0.0;

  void show() { if (!_visible) { _visible = true;  notifyListeners(); } }
  void hide() { if (_visible)  { _visible = false; notifyListeners(); } }
}

// ── 2. NavBarControllerScope ──────────────────────────────────────────────────
// InheritedNotifier — any screen below QuotesyShell can call
// NavBarControllerScope.of(context) to get the controller.
class NavBarControllerScope extends InheritedNotifier<NavBarController> {
  const NavBarControllerScope({
    super.key,
    required NavBarController controller,
    required super.child,
  }) : super(notifier: controller);

  static NavBarController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NavBarControllerScope>();
    assert(scope != null, 'NavBarControllerScope missing from widget tree.');
    return scope!.notifier!;
  }
}

// ── 3. QuotesyShell ───────────────────────────────────────────────────────────
// The persistent scaffold rendered by StatefulShellRoute.
// Owns NavBarController. Wraps everything in NavBarControllerScope so
// child screens can drive the controller without constructor drilling.
class QuotesyShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const QuotesyShell({super.key, required this.navigationShell});

  @override
  State<QuotesyShell> createState() => _QuotesyShellState();
}

class _QuotesyShellState extends State<QuotesyShell> {
  late final NavBarController _navBarController;

  @override
  void initState() {
    super.initState();
    _navBarController = NavBarController();
    _navBarController.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _navBarController.removeListener(_rebuild);
    _navBarController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      // Tapping the active tab again resets it to its initial route.
      // Harmless now, useful once tabs have nested routes.
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
            // Tab content — renders full-bleed behind the floating bar
            widget.navigationShell,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: QuotesyNavBar(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _onTabTapped,
                visible: _navBarController.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 4. QuotesyNavBar ──────────────────────────────────────────────────────────
// The floating pill. GNav handles the icon→label slide animation.
// AnimatedSlide drives the hide/show from NavBarController.visible.
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
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.8),
      duration: const Duration(milliseconds: 250),
      curve: visible ? Curves.easeOut : Curves.easeIn,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: _kAmber.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: GNav(
              color: Colors.white38,
              activeColor: _kAmberGlow,
              tabBackgroundColor: _kAmber.withValues(alpha: 0.18),
              gap: 6,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tabBorderRadius: 20,
              tabActiveBorder: Border.all(
                color: _kAmber.withValues(alpha: 0.35),
                width: 1,
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              haptic: true,
              iconSize: 20,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              selectedIndex: currentIndex,
              onTabChange: onTap,
              tabs: const [
                GButton(icon: Icons.auto_awesome_outlined, text: 'Home'),
                GButton(icon: Icons.explore_outlined,      text: 'Explore'),
                GButton(icon: Icons.bookmark_outline_rounded, text: 'Saved'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}