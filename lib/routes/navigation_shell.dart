import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:quotesy/theme/quotesy_theme.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int)? onTap;

  const NavBar({super.key, required this.currentIndex, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: .circular(40),
              color: QColors.surface,
              border: BoxBorder.all(color: QNavColors.pillBorder),
            ),
            padding: .all(8),
            child: GNav(
              selectedIndex: currentIndex,
              onTabChange: onTap,
              padding: .symmetric(horizontal: 12, vertical: 10),
              activeColor: QColors.amberGlow,
              mainAxisAlignment: .center,
              color: QNavColors.inactive,
              tabBackgroundColor: QColors.amberGlow.withValues(alpha: 0.2),
              tabActiveBorder: Border.all(
                color: QColors.amberGlow.withValues(alpha: 0.5),
              ),
              tabs: [
                // home
                GButton(
                  icon: currentIndex == 0
                      ? CupertinoIcons.book_fill
                      : CupertinoIcons.book,
                  text: 'Quotes',
                  iconActiveColor: QColors.amber,
                  gap: 4,
                ),

                // explore
                GButton(
                  icon: currentIndex == 1
                      ? Icons.travel_explore_rounded
                      : Icons.travel_explore_outlined,
                  text: 'Explore',
                  iconActiveColor: QColors.amber,
                  gap: 4,
                ),

                // saved
                GButton(
                  gap: 4,
                  icon: currentIndex == 2
                      ? CupertinoIcons.bookmark_fill
                      : CupertinoIcons.bookmark,
                  text: 'Saved',
                  iconActiveColor: QColors.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
