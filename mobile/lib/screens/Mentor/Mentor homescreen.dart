import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/mentor_service.dart';
import '../../services/payout_service.dart';
import 'profile_screen.dart';
import 'Earnings screen.dart';
import 'Session requests screen.dart';
import '../Student/chathistory.dart';
import '../Student/Notifications screen.dart';

void main() {
  runApp(const MentorApp());
}

class MentorApp extends StatelessWidget {
  const MentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentor App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MentorHomeScreen(),
    );
  }
}

class MentorHomeScreen extends StatefulWidget {
  const MentorHomeScreen({super.key});

  @override
  State<MentorHomeScreen> createState() => _MentorHomeScreenState();
}

class _MentorHomeScreenState extends State<MentorHomeScreen> {
  int _selectedIndex = 0;
  bool _isOnline = true;
  bool _isLoading = true;

  // Mentor profile data
  Map<String, dynamic>? _mentorProfile;

  // Session data
  List<dynamic> _sessionRequests = [];
  List<dynamic> _allSessions = [];

  // Earnings data
  double _monthlyEarnings = 0;

  static const Color primaryDark = Color(0xFF1B4F72);
  static const Color accentOrange = Color(0xFFF5A623);

  @override
  void initState() {
    super.initState();
    _loadMentorData();
  }

  Future<void> _loadMentorData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      // Fetch mentor profile
      final profileResponse = await MentorService.getMyProfile(token);
      if (profileResponse['success'] == true) {
        setState(() {
          _mentorProfile = profileResponse['data'];
          _isOnline = _mentorProfile?['isAvailable'] ?? true;
        });
      }

      // Fetch session requests
      final sessionsResponse = await MentorService.getIncomingSessions(token);
      if (sessionsResponse['success'] == true) {
        setState(() {
          _sessionRequests = sessionsResponse['data'] ?? [];
        });
      }

      // Fetch all sessions for stats
      final allSessionsResponse = await MentorService.getMySessions(token);
      if (allSessionsResponse['success'] == true) {
        setState(() {
          _allSessions = allSessionsResponse['data'] ?? [];
        });
      }

      // Fetch earnings/balance
      final balanceResponse = await PayoutService.getBalance(token);
      if (balanceResponse['success'] == true) {
        setState(() {
          _monthlyEarnings =
              (balanceResponse['data']['totalEarned'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnlineStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    final newStatus = !_isOnline;

    // Optimistic UI update
    setState(() => _isOnline = newStatus);

    try {
      final response = await MentorService.updateAvailability(token, newStatus);
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  newStatus ? 'You are now online' : 'You are now offline'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Revert on failure
        setState(() => _isOnline = !newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to update status: ${response['message'] ?? 'Unknown error'}')),
          );
        }
      }
    } catch (e) {
      // Revert on error
      setState(() => _isOnline = !newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  int get _todaySessionsCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allSessions.where((session) {
      final scheduledDate = DateTime.parse(
          session['scheduledDate'] ?? session['createdAt'] ?? '');
      return scheduledDate.isAfter(today.subtract(const Duration(days: 1))) &&
          scheduledDate.isBefore(today.add(const Duration(days: 1)));
    }).length;
  }

  int get _weekSessionsCount {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    return _allSessions.where((session) {
      final scheduledDate = DateTime.parse(
          session['scheduledDate'] ?? session['createdAt'] ?? '');
      return scheduledDate.isAfter(startOfLastWeek) &&
          scheduledDate.isBefore(now);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSessionRequestCard(),
                        const SizedBox(height: 24),
                        _buildQuickActionsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _mentorProfile != null
                            ? '${_mentorProfile?['headline'] ?? 'Ready to mentor today?'}'
                            : 'Ready to mentor today?',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _toggleOnlineStatus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.power_settings_new,
                            size: 18,
                            color: _isOnline ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOnline ? 'Online' : 'Offline',
                            style: GoogleFonts.inter(
                              color: _isOnline
                                  ? const Color(0xFF1C3A52)
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.access_time_rounded,
                      label: "Today's Sessions",
                      value: '$_todaySessionsCount',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.trending_up_rounded,
                      label: 'This Week',
                      value: '$_weekSessionsCount',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Color(0xffD9D9D9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF001636), size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRequestCard() {
    return GestureDetector(
      onTap: () => _handleNavTap(4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFFDE68A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Session Requests',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C3A52),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to review and respond',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A7A8A),
                  ),
                ),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: accentOrange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${_sessionRequests.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xff1D5572),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _handleNavTap(1),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF1D5572).withOpacity(0.6), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/mentor wallet.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'View Earnings',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C3A52),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_monthlyEarnings.toStringAsFixed(0)} EGP this month',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A7A8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => setState(() => _selectedIndex = 5),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF1D5572).withOpacity(0.6), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: primaryDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C3A52),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add more details to get better career recommendations and mentor matches.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5A7A8A),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedIndex = 5),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Update Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.account_balance_wallet_outlined, 'label': 'Wallet'},
      {'icon': Icons.send_rounded, 'label': 'Chat'},
      {'icon': Icons.notifications_outlined, 'label': 'Notification'},
      {'icon': Icons.person_search_outlined, 'label': 'Request'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff1D5572),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == _selectedIndex;
              return GestureDetector(
                onTap: () => _handleNavTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[index]['icon'] as IconData,
                      color: isSelected ? accentOrange : Colors.white60,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index]['label'] as String,
                      style: TextStyle(
                        color: isSelected ? accentOrange : Colors.white60,
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    switch (index) {
      case 0: // Home
        // Already on home
        break;
      case 1: // Wallet
        _navigateToWallet();
        break;
      case 2: // Chat
        _navigateToChat();
        break;
      case 3: // Notification
        _navigateToNotifications();
        break;
      case 4: // Request
        _navigateToSessionRequests();
        break;
      case 5: // Profile
        _navigateToProfile();
        break;
    }
  }

  void _navigateToWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EarningsScreen()),
    );
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatsScreen()),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _navigateToSessionRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SessionRequestsScreen()),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }
}
