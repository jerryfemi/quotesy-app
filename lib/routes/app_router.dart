import 'package:go_router/go_router.dart';
import 'package:quotesy/screens/category_screen.dart';

import '../screens/home_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/saved_screen.dart';
import '../screens/splash_screen.dart';
import '../widgets/quotesy_nav_bar.dart';

// Routes only. No widgets, no controllers, no scaffolds.
final routerProvider = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/splash'),
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          QuotesyShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/category/:name',
      builder: (context, state) {
        final encoded = state.pathParameters['name'] ?? '';
        final category = Uri.decodeComponent(encoded);
        return CategoryFeedScreen(category: category);
      },
    ),
  ],
);
