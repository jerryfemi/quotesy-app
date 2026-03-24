import 'package:flutter/material.dart';

class NavBarController extends ChangeNotifier {
  bool _visible = true;
  double _dragAccumulator = 0.0;
  static const double _deadZone = 8.0;

  bool get visible => _visible;

  void onDrag(double deltaY) {
    _dragAccumulator += deltaY;

    if (_dragAccumulator < -_deadZone) {
      _dragAccumulator = 0.0;
      if (_visible) {
        _visible = false;
        notifyListeners();
      }
    } else if (_dragAccumulator > _deadZone) {
      _dragAccumulator = 0.0;
      if (!_visible) {
        _visible = true;
        notifyListeners();
      }
    }
  }

  void onDragEnd() {
    _dragAccumulator = 0.0;
  }

  void show() {
    if (!_visible) {
      _visible = true;
      notifyListeners();
    }
  }
}

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
      offset: visible ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 250),
      curve: visible ? Curves.easeOut : Curves.easeIn,
      child: _NavBarBody(currentIndex: currentIndex, onTap: onTap),
    );
  }
}

class _NavBarBody extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavBarBody({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, bottomInset > 0 ? 12 : 20),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            index: 0,
            currentIndex: currentIndex,
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Home',
            onTap: onTap,
          ),
          _NavItem(
            index: 1,
            currentIndex: currentIndex,
            icon: Icons.perm_contact_calendar_outlined,
            activeIcon: Icons.perm_contact_calendar,
            label: 'Explore',
            onTap: onTap,
          ),
          _NavItem(
            index: 2,
            currentIndex: currentIndex,
            icon: Icons.bookmark_outline_rounded,
            activeIcon: Icons.bookmark_rounded,
            label: 'Saved',
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFDCEEDB) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive
                  ? const Color(0xFF1D8F3A)
                  : const Color(0xFF2D2D2D),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1D8F3A)
                    : const Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
