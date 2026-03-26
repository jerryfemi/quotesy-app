import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kAmber = Color(0xFFB8860B);
const _kAmberGlow = Color(0xFFD4A017);

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

  void _rebuild() {
    if (mounted) setState(() {});
  }

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
// Center: compact Home/Explore pill.
// Right: detached circular Saved button.
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
    final isHome = currentIndex == 0;
    final isExplore = currentIndex == 1;
    final isSaved = currentIndex == 2;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.8),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PillTabButton(
                          icon: Icons.auto_awesome_outlined,
                          label: 'Home',
                          isActive: isHome,
                          onTap: () => onTap(0),
                        ),
                        const SizedBox(width: 6),
                        _PillTabButton(
                          icon: Icons.explore_outlined,
                          label: 'Explore',
                          isActive: isExplore,
                          onTap: () => onTap(1),
                        ),
                      ],
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap: () => onTap(2),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSaved
                            ? _kAmber.withValues(alpha: 0.20)
                            : const Color(0xFF111111),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSaved
                              ? _kAmber.withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.07),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.bookmark_outline_rounded,
                        size: 20,
                        color: isSaved ? _kAmberGlow : Colors.white38,
                      ),
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
