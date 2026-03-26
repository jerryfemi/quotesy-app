import 'package:flutter/material.dart';

import '../models/category_style.dart';
import '../services/database_service.dart';
import '../widgets/quotesy_nav_bar.dart';
import '../widgets/reactive_light_card.dart';
import '../theme/quotesy_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExploreScreen
//
// Vertical PageView of ReactiveLightCards.
// Styles list built once in initState — not on every scroll frame.
// Listener drives nav bar hide/show via raw pointer delta.
// ─────────────────────────────────────────────────────────────────────────────
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final PageController _pageController;
  late final List<CategoryStyle> _styles;
  final double _glowBaseline = 0.05;
  final double _focusFalloff = 1.20;

  @override
  void initState() {
    super.initState();
    // Built once. CategoryStyle.forCategory is pure — safe to cache here.
    _styles = QuoteCategory.all.map(CategoryStyle.forCategory).toList();
    _pageController = PageController(viewportFraction: 0.72);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = NavBarControllerScope.of(context);

    return Scaffold(
      backgroundColor: QColors.obsidian,
      appBar: AppBar(
        title: Text(
          'Explore',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Listener(
        onPointerMove: (e) => nav.onDrag(e.delta.dy),
        onPointerUp: (_) => nav.onDragEnd(),
        onPointerCancel: (_) => nav.onDragEnd(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 72),
          child: AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              final currentPage = _pageController.hasClients
                  ? (_pageController.page ??
                        _pageController.initialPage.toDouble())
                  : _pageController.initialPage.toDouble();

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                padEnds: true,
                itemCount: _styles.length,
                itemBuilder: (context, index) {
                  final distance = (currentPage - index).abs();
                  final focusAmount = (1.0 - (distance * _focusFalloff)).clamp(
                    0.0,
                    1.0,
                  );

                  return ReactiveLightCard(
                    style: _styles[index],
                    focusAmount: focusAmount,
                    glowBaseline: _glowBaseline,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
