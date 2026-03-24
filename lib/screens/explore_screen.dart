import 'package:flutter/material.dart';
import 'package:quotes/models/category_style.dart';
import '../services/database_service.dart';
import '../widgets/reactive_light_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85, // Cards peek from below — creates depth
    );
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    final page = _pageController.page ?? 0.0;
    // Only call setState if the value actually changed meaningfully.
    // 0.001 threshold avoids rebuilds from floating-point noise.
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
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: _buildCardList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURATED ANTHOLOGIES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              letterSpacing: 3,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quotesy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    // Build styles once, not on every scroll frame.
    final styles = QuoteCategory.all.map(CategoryStyle.forCategory).toList();

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final distance = (_currentPage - index).abs();
        final focusAmount = (1.0 - (distance * 1.2)).clamp(0.0, 1.0);

        return ReactiveLightCard(
          style: styles[index],
          focusAmount: focusAmount,
        );
      },
    );
  }
}
