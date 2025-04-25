import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppStyles.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          backgroundColor: AppStyles.surfaceColor,
          currentIndex: currentIndex,
          onTap: onTap,
          selectedItemColor: AppStyles.primaryColor,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
            _buildNavItem(Icons.search_outlined, Icons.search, 'Search', 1),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 2),
          ],
        ),
      ),
    );
  }
  
  BottomNavigationBarItem _buildNavItem(
    IconData defaultIcon, 
    IconData activeIcon, 
    String label, 
    int index
  ) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Icon(
          currentIndex == index ? activeIcon : defaultIcon,
          size: 28,
        ),
      ),
      label: label,
    );
  }
} 