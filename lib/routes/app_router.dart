import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/explore_screen.dart';
import '../screens/home_screen.dart';
import '../screens/vault_screen.dart';
import '../widgets/quotesy_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeBranch');
final _exploreNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'exploreBranch',
);
final _vaultNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'vaultBranch');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return QuotesyShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _exploreNavigatorKey,
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _vaultNavigatorKey,
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => const VaultScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

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
    _navBarController.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _navBarController.removeListener(_onControllerChanged);
    _navBarController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
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
        body: Stack(
          children: [
            widget.navigationShell,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: QuotesyNavBar(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: _onTap,
                visible: _navBarController.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavBarControllerScope extends InheritedNotifier<NavBarController> {
  const NavBarControllerScope({
    super.key,
    required NavBarController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static NavBarController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NavBarControllerScope>();
    assert(scope != null, 'NavBarControllerScope is missing in widget tree.');
    return scope!.notifier!;
  }
}