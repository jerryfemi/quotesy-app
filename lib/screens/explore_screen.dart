import 'package:flutter/foundation.dart';
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
  double _currentPage = 0.0;
  double _glowBaseline = 0.20;
  double _focusFalloff = 0.75;

  @override
  void initState() {
    super.initState();
    // Built once. CategoryStyle.forCategory is pure — safe to cache here.
    _styles = QuoteCategory.all.map(CategoryStyle.forCategory).toList();
    _pageController = PageController(viewportFraction: 0.76);
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _pageController.page ?? 0.0;
    if ((page - _currentPage).abs() > 0.001) {
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
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
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Tune glow',
              icon: const Icon(Icons.tune_rounded),
              onPressed: _showGlowTuner,
            ),
        ],
      ),
      body: Listener(
        onPointerMove: (e) => nav.onDrag(e.delta.dy),
        onPointerUp: (_) => nav.onDragEnd(),
        onPointerCancel: (_) => nav.onDragEnd(),
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          padEnds: true,
          itemCount: _styles.length,
          itemBuilder: (context, index) {
            final distance = (_currentPage - index).abs();
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
        ),
      ),
    );
  }

  void _showGlowTuner() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: QColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Glow Tuner',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Baseline: ${(_glowBaseline * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _glowBaseline,
                    min: 0.05,
                    max: 0.40,
                    divisions: 35,
                    onChanged: (value) {
                      setState(() => _glowBaseline = value);
                      setModalState(() {});
                    },
                  ),
                  Text(
                    'Falloff: ${_focusFalloff.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _focusFalloff,
                    min: 0.50,
                    max: 1.20,
                    divisions: 70,
                    onChanged: (value) {
                      setState(() => _focusFalloff = value);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
