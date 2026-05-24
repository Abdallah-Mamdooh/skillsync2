import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/mentor_service.dart';
import '../../services/payout_service.dart';
import '../../widgets/bottom_navigation.dart';
import 'profile_screen.dart';
import 'Earnings screen.dart';
import 'Session requests screen.dart';
import 'event_requests .dart';
import '../Student/payment_confirmation_screen.dart';
import 'break_mode_active.dart';

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
  String _currentStatus = 'Online';
  bool _isLoading = true;
  bool _isUpdatingStatus = false;

  Timer? _breakTimer;
  int _breakSecondsRemaining = 0;

  Map<String, dynamic>? _mentorProfile;
  List<dynamic> _sessionRequests = [];
  List<dynamic> _allSessions = [];
  double _monthlyEarnings = 0;

  static const Color primaryDark = Color(0xFF1B4F72);
  static const Color accentOrange = Color(0xFFF5A623);

  @override
  void initState() {
    super.initState();
    _loadMentorData();
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    super.dispose();
  }

  bool _toBool(dynamic value, {bool fallback = true}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'online' || normalized == '1')
        return true;
      if (normalized == 'false' || normalized == 'offline' || normalized == '0')
        return false;
    }
    return fallback;
  }

  Future<void> _loadMentorData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final profileResponse = await MentorService.getMyProfile(token);
      if (profileResponse['success'] == true) {
        final profileData = profileResponse['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(profileResponse['data'])
            : <String, dynamic>{};
        setState(() {
          _mentorProfile = profileData;
          _currentStatus =
              _toBool(profileData['isAvailable']) ? 'Online' : 'Offline';
        });
      }
      final sessionsResponse = await MentorService.getIncomingSessions(token);
      if (sessionsResponse['success'] == true) {
        setState(() {
          _sessionRequests = sessionsResponse['data'] ?? [];
        });
      }
      final allSessionsResponse = await MentorService.getMySessions(token);
      if (allSessionsResponse['success'] == true) {
        setState(() {
          _allSessions = allSessionsResponse['data'] ?? [];
        });
      }
      final balanceResponse = await PayoutService.getBalance(token);
      if (balanceResponse['success'] == true) {
        setState(() {
          _monthlyEarnings =
              (balanceResponse['data']['totalEarned'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null || _isUpdatingStatus) return;
    final bool isAvailable = newStatus == 'Online';
    setState(() {
      _isUpdatingStatus = true;
      _currentStatus = newStatus;
      _mentorProfile = {...?_mentorProfile, 'isAvailable': isAvailable};
    });
    try {
      final response =
          await MentorService.updateAvailability(token, isAvailable);
      if (response['success'] == true) {
        final responseData = response['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(response['data'])
            : <String, dynamic>{};
        final confirmedAvailable =
            _toBool(responseData['isAvailable'], fallback: isAvailable);
        if (mounted) {
          setState(() {
            _currentStatus = confirmedAvailable
                ? 'Online'
                : (newStatus == 'Online' ? 'Offline' : newStatus);
            _isUpdatingStatus = false;
            _mentorProfile = {
              ...?_mentorProfile,
              ...responseData,
              'isAvailable': confirmedAvailable
            };
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Status updated to $_currentStatus'),
                duration: const Duration(seconds: 1)),
          );
        }
      } else {
        setState(() {
          _isUpdatingStatus = false;
          _currentStatus = isAvailable ? 'Offline' : 'Online';
          _mentorProfile = {...?_mentorProfile, 'isAvailable': !isAvailable};
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to update status: ${response['message'] ?? 'Unknown error'}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUpdatingStatus = false;
        _currentStatus = isAvailable ? 'Offline' : 'Online';
        _mentorProfile = {...?_mentorProfile, 'isAvailable': !isAvailable};
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Future<void> _showBreakConfirmationDialog() async {
    int selectedDuration = 5;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Icon
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                    ),
                    child: const Icon(
                      Icons.local_cafe_outlined,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  'Choose Break Duration',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF5A623),
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  'Users cannot book slots overlapping your break period.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1D5572),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Options
                _buildDurationOption(
                  label: '5 Minutes',
                  value: 5,
                  groupValue: selectedDuration,
                  onChanged: (val) => setState(() => selectedDuration = val!),
                ),
                const SizedBox(height: 8),
                _buildDurationOption(
                  label: '10 Minutes',
                  value: 10,
                  groupValue: selectedDuration,
                  onChanged: (val) => setState(() => selectedDuration = val!),
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D5572),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D5572),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Start Break',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _updateStatus('Break');
      if (mounted) {
        _startBreakTimer(selectedDuration);
      }
    }
  }

  void _startBreakTimer(int minutes) {
    _breakTimer?.cancel();
    setState(() {
      _breakSecondsRemaining = minutes * 60;
    });
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_breakSecondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _breakSecondsRemaining--;
          });
        }
      } else {
        _stopBreak();
      }
    });
  }

  void _stopBreak() {
    _breakTimer?.cancel();
    if (mounted) {
      setState(() {
        _breakSecondsRemaining = 0;
      });
      _updateStatus('Online');
    }
  }

  Widget _buildDurationOption({
    required String label,
    required int value,
    required int groupValue,
    required ValueChanged<int?> onChanged,
  }) {
    final bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: const Color(0xFF1D5572),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1D5572),
              ),
            ),
          ],
        ),
      ),
    );
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
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildSessionRequestCard(),
                        const SizedBox(height: 24),
                        _buildQuickActionsSection(),
                        const SizedBox(height: 24),
                        _buildManageSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const MentorBottomNavigation(
        selectedIndex: MentorBottomNavIndex.home,
      ),
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
              // Greeting row — no status button here anymore
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
                'Ready to mentor today?',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 16),

              // Stat cards
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

  /// Inline status card matching the image design
  Widget _buildStatusCard() {
    final bool isOnBreak =
        _currentStatus == 'Break' && _breakSecondsRemaining > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1D5572), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: "Current Status" label + active status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Status',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              // Active status pill (right side, matches image)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnBreak ? Icons.local_cafe : Icons.circle,
                      size: isOnBreak ? 14 : 8,
                      color: _currentStatus == 'Online'
                          ? Colors.green
                          : _currentStatus == 'Break'
                              ? Colors.black87
                              : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isUpdatingStatus
                          ? 'Updating...'
                          : (isOnBreak ? 'On Break' : _currentStatus),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Divider(thickness: 2, color: Color(0xFFD9D9D9)),
          const SizedBox(height: 12),

          if (isOnBreak)
            _buildBreakTimerContent()
          else
            // Three status buttons
            Row(
              children: [
                // Online
                Expanded(
                  child: _buildStatusButton(
                    label: 'Online',
                    dotColor: Colors.green,
                    isSelected: _currentStatus == 'Online',
                    onTap: () {
                      if (!_isUpdatingStatus && _currentStatus != 'Online') {
                        _updateStatus('Online');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Offline
                Expanded(
                  child: _buildStatusButton(
                    label: 'Offline',
                    dotColor: Colors.red,
                    isSelected: _currentStatus == 'Offline',
                    onTap: () {
                      if (!_isUpdatingStatus && _currentStatus != 'Offline') {
                        _updateStatus('Offline');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Take a break
                Expanded(
                  child: _buildStatusButton(
                    label: 'Take a break',
                    dotColor: Colors.orange,
                    isSelected: _currentStatus == 'Break',
                    onTap: () {
                      if (!_isUpdatingStatus && _currentStatus != 'Break') {
                        _showBreakConfirmationDialog();
                      }
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBreakTimerContent() {
    final minutes = (_breakSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_breakSecondsRemaining % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timer Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7), // Light amber/yellow
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Break Ends In',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$minutes:$seconds',
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bullet points
        _buildBulletPoint(
            'Users cannot book slots overlapping your break period.'),
        const SizedBox(height: 8),
        _buildBulletPoint(
            'Break activity is tracked for platform reliability.'),
        const SizedBox(height: 20),

        // End Break Early Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _stopBreak,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D5572),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'End Break Early',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: Colors.black87),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required String label,
    required Color dotColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D5572) : const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: dotColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? dotColor : Colors.black,
                ),
              ),
            ),
          ],
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
        color: const Color(0xffD9D9D9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF001636), size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                height: 1.1),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRequestCard() {
    return GestureDetector(
      onTap: _navigateToSessionRequests,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE68A).withOpacity(0.1),
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
                      color: Color(0xFF1C3A52)),
                ),
                SizedBox(height: 4),
                Text('Tap to review and respond',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5A7A8A))),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: accentOrange, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '${_sessionRequests.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
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
              color: Color(0xff1D5572)),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _navigateToEventRequests,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset('assets/images/create event.png',
                        fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Event',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C3A52))),
                      SizedBox(height: 3),
                      Text('Set up and submit your event for review',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF5A7A8A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _navigateToWallet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset('assets/images/mentor wallet.png',
                        fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('View Earnings',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C3A52))),
                    const SizedBox(height: 3),
                    Text(
                        '${_monthlyEarnings.toStringAsFixed(0)} EGP this month',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF5A7A8A))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff1D5572)),
        ),
        const SizedBox(height: 16),

        // Active Weekly Schedule
        GestureDetector(
          onTap: _navigateToWeeklySchedule,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                        'assets/images/Active Weekly Schedule.png',
                        fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Weekly Schedule',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C3A52))),
                      SizedBox(height: 3),
                      Text('Admin-approved recurring availability',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF5A7A8A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Availability Exceptions
        GestureDetector(
          onTap: _navigateToAvailabilityExceptions,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                        'assets/images/Availability exceptions.png',
                        fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Availability Exceptions',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C3A52))),
                      SizedBox(height: 3),
                      Text('Temporarily block booking availability',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF5A7A8A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Complete Your Profile
        GestureDetector(
          onTap: _navigateToProfile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
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
                          color: primaryDark, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Complete Your Profile',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C3A52))),
                          SizedBox(height: 4),
                          Text(
                            'Add more details to get better career recommendations and mentor matches.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5A7A8A),
                                height: 1.4),
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
                    onPressed: _navigateToProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Update Profile',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToEventRequests() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const EventRequestsScreen()));
  }

  void _navigateToWallet() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
  }

  void _navigateToSessionRequests() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SessionRequestsScreen()));
  }

  void _navigateToProfile() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _navigateToWeeklySchedule() {
    // Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen()));
  }

  void _navigateToAvailabilityExceptions() {
    // Navigator.push(context, MaterialPageRoute(builder: (_) => const AvailabilityExceptionsScreen()));
  }
}
