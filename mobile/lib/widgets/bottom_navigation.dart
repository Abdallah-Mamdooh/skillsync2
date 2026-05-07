import 'package:flutter/material.dart';
import '../screens/Student/student_homescreen.dart';
import '../screens/Student/assessment_flow.dart';
import '../screens/Student/chathistory.dart';
import '../screens/Student/profile_screen.dart';
import '../screens/Mentor/Mentor homescreen.dart';
import '../screens/Mentor/Session requests screen.dart';
import '../screens/Mentor/Earnings screen.dart';
import '../screens/Mentor/profile_screen.dart' as mentor_profile;
import '../screens/Mentor/mentor_chathistory.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum BottomNavIndex { home, assess, chat, profile, none }

enum MentorBottomNavIndex { home, requests, chats, earnings, profile, none }

// ─── Student Bottom Navigation ───────────────────────────────────────────────

class BottomNavigation extends StatelessWidget {
  final BottomNavIndex selectedIndex;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
  });

  static const Color _navBg = Color(0xFF1D5572);
  static const Color _activeColor = Color(0xFFF5A623);
  static const Color _inactiveColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: _navBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context,
              assetPath: 'assets/images/home_nav.png',
              label: 'Home',
              index: BottomNavIndex.home),
          _buildNavItem(context,
              assetPath: 'assets/images/chat_nav.png',
              label: 'Chat',
              index: BottomNavIndex.chat),
          _buildNavItem(context,
              assetPath: 'assets/images/wallet_nav.png',
              label: 'Wallet',
              index: BottomNavIndex.assess),
          _buildNavItem(context,
              icon: Icons.person,
              activeIcon: Icons.person,
              label: 'Profile',
              index: BottomNavIndex.profile),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    String? assetPath,
    IconData? icon,
    IconData? activeIcon,
    required String label,
    required BottomNavIndex index,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? _activeColor.withOpacity(0.20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: assetPath != null
                ? Image.asset(
                    assetPath,
                    width: 24,
                    height: 24,
                    color: isSelected ? _activeColor : _inactiveColor,
                  )
                : Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? _activeColor : _inactiveColor,
                    size: 24,
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? _activeColor : _inactiveColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, BottomNavIndex index) {
    if (selectedIndex == index) return;

    switch (index) {
      case BottomNavIndex.home:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          (route) => false,
        );
        break;
      case BottomNavIndex.assess:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AssessmentStartScreen()));
        break;
      case BottomNavIndex.chat:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ChatsScreen()));
        break;
      case BottomNavIndex.profile:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      case BottomNavIndex.none:
        break;
    }
  }
}

// ─── Mentor Bottom Navigation ─────────────────────────────────────────────────

class MentorBottomNavigation extends StatelessWidget {
  final MentorBottomNavIndex selectedIndex;

  const MentorBottomNavigation({
    super.key,
    required this.selectedIndex,
  });

  static const Color _navBg = Color(0xFF1D5572);
  static const Color _activeColor = Color(0xFFF5A623); // orange from image
  static const Color _inactiveColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: _navBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              index: MentorBottomNavIndex.home),
          _buildNavItem(context,
              icon: Icons.inbox_outlined,
              activeIcon: Icons.inbox,
              label: 'Requests',
              index: MentorBottomNavIndex.requests),
          _buildNavItem(context,
              icon: Icons.send_outlined,
              activeIcon: Icons.send,
              label: 'Chats',
              index: MentorBottomNavIndex.chats),
          _buildNavItem(context,
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet,
              label: 'Earnings',
              index: MentorBottomNavIndex.earnings),
          _buildNavItem(context,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              index: MentorBottomNavIndex.profile),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required MentorBottomNavIndex index,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Orange pill background on active icon (matches image)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? _activeColor.withOpacity(0.20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? _activeColor : _inactiveColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? _activeColor : _inactiveColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, MentorBottomNavIndex index) {
    if (selectedIndex == index) return;

    switch (index) {
      case MentorBottomNavIndex.home:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MentorHomeScreen()),
          (route) => false,
        );
        break;
      case MentorBottomNavIndex.requests:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SessionRequestsScreen()),
        );
        break;
      case MentorBottomNavIndex.chats:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MentorChatsScreen()),
        );
        break;
      case MentorBottomNavIndex.earnings:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EarningsScreen()),
        );
        break;
      case MentorBottomNavIndex.profile:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const mentor_profile.ProfileScreen(),
          ),
        );
        break;
      case MentorBottomNavIndex.none:
        break;
    }
  }
}
