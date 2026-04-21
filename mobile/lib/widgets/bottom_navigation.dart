import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/student_homescreen.dart';
import '../screens/assessment_flow.dart';
import '../screens/ChatsScreen.dart';
import '../screens/profile_screen.dart';

enum BottomNavIndex { home, assess, chat, profile }

class BottomNavigation extends StatelessWidget {
  final BottomNavIndex selectedIndex;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            index: BottomNavIndex.home,
          ),
          _buildNavItem(
            context,
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'assess',
            index: BottomNavIndex.assess,
          ),
          _buildNavItem(
            context,
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Chat',
            index: BottomNavIndex.chat,
          ),
          _buildNavItem(
            context,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            index: BottomNavIndex.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required BottomNavIndex index,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? activeIcon : icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, BottomNavIndex index) {
    // Don't navigate if already on this screen
    if (selectedIndex == index) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    switch (index) {
      case BottomNavIndex.home:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          (route) => false,
        );
        break;

      case BottomNavIndex.assess:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AssessmentStartScreen()),
        );
        break;

      case BottomNavIndex.chat:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatsScreen()),
        );
        break;

      case BottomNavIndex.profile:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }
}
