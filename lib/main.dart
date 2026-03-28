import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'theme/quotesy_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: QuotesyApp()));
}

class QuotesyApp extends StatelessWidget {
  const QuotesyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quotesy',
      debugShowCheckedModeBanner: false,
      theme: darkMode,
      routerConfig: routerProvider,
    );
  }
}
