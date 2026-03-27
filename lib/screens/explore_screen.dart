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
//
// Adaptive layout:
//   - Phone: vertical hero PageView (focused card dynamics)
//   - Tablet/Desktop: gallery grid for faster browsing
// ─────────────────────────────────────────────────────────────────────────────
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final PageController _pageController;
  late final ValueNotifier<double> _pageOffset;
  late final List<CategoryStyle> _styles;

  static const double _glowBaseline = 0.05;
  static const double _focusFalloff = 1.20;

  @override
  void initState() {
    super.initState();
    _styles = QuoteCategory.all.map(CategoryStyle.forCategory).toList();
    _pageController = PageController(viewportFraction: 0.72);
    _pageOffset = ValueNotifier<double>(_pageController.initialPage.toDouble());
    _pageController.addListener(_handlePageScroll);
  }

  void _handlePageScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? _pageController.initialPage.toDouble();
    if ((page - _pageOffset.value).abs() > 0.005) {
      _pageOffset.value = page;
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    _pageOffset.dispose();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            return Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: isWide
                  ? _buildWideGrid(constraints.maxWidth)
                  : _buildPhonePager(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhonePager() {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      padEnds: true,
      itemCount: _styles.length,
      itemBuilder: (context, index) {
        return ValueListenableBuilder<double>(
          valueListenable: _pageOffset,
          builder: (context, currentPage, _) {
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
    );
  }

  Widget _buildWideGrid(double width) {
    final crossAxisCount = width >= 1320 ? 3 : 2;
    final childAspectRatio = width >= 1320 ? 0.78 : 0.74;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _styles.length,
      itemBuilder: (context, index) {
        return ReactiveLightCard(
          style: _styles[index],
          focusAmount: 1.0,
          glowBaseline: _glowBaseline,
          margin: EdgeInsets.zero,
        );
      },
    );
  }
}
