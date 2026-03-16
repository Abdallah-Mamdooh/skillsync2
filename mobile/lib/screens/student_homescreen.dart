import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'assessment_flow.dart';
import 'cv_Optimizer.dart';
import 'profile_screen.dart';
import 'mentorship_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'Notifications screen.dart';
import 'ChatsScreen.dart';
import 'roadmap_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _hasRoadmap = false;
  bool _isRoadmapLoading = true;
  int _roadmapPercent = 0;
  String? _lastToken;

  double _walletBalance = 0;
  String _walletCurrency = 'EGP';
  bool _isWalletLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.read<AuthProvider>().token;
    if (token != _lastToken) {
      _lastToken = token;
      if (mounted) {
        setState(() {
          _hasRoadmap = false;
          _isRoadmapLoading = true;
        });
      }
      _loadRoadmapStatus();
      _loadWalletBalance();
    }
  }

  Future<void> _loadRoadmapStatus() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _hasRoadmap = false;
          _isRoadmapLoading = false;
          _roadmapPercent = 0;
        });
      }
      return;
    }

    final response = await ApiService.get('/roadmap/my-roadmap', token);
    final hasRoadmap = response['success'] == true && response['data'] != null;
    int percent = 0;
    if (hasRoadmap) {
      final data = response['data'];
      final raw = data is Map<String, dynamic> ? data['completionPercent'] : null;
      if (raw is num) {
        percent = raw.round();
      } else {
        final parsed = int.tryParse((raw ?? '').toString());
        percent = parsed ?? 0;
      }
      if (percent < 0) percent = 0;
      if (percent > 100) percent = 100;
    }

    if (mounted) {
      setState(() {
        _hasRoadmap = hasRoadmap;
        _isRoadmapLoading = false;
        _roadmapPercent = percent;
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _walletBalance = 0;
          _walletCurrency = 'EGP';
          _isWalletLoading = false;
        });
      }
      return;
    }

    try {
      final response = await ApiService.get('/payments/wallet', token);
      double balance = 0;
      String currency = 'EGP';
      if (response['success'] == true && response['data'] != null) {
        final wallet = response['data']['wallet'];
        if (wallet != null) {
          final rawBalance = wallet['availableBalance'];
          if (rawBalance is num) {
            balance = rawBalance.toDouble();
          }
          currency = wallet['currency'] ?? 'EGP';
        }
      }

      if (mounted) {
        setState(() {
          _walletBalance = balance;
          _walletCurrency = currency;
          _isWalletLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _walletBalance = 0;
          _walletCurrency = 'EGP';
          _isWalletLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final firstName = user?['fullName']?.split(' ')[0] ?? 'User';
    final showRoadmap = _hasRoadmap && !_isRoadmapLoading;
    final progressPercent = _roadmapPercent.clamp(0, 100);

    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(color: Colors.white),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF1D5572),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 53, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + Title row
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 61,
                          height: 62,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.star, color: Color(0xFFF5A100), size: 60),
                        ),
                        const SizedBox(width: 9),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SKILLSYNC',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFF5A100),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                                children: [
                                  const TextSpan(text: 'Welcome back'),
                                  const TextSpan(
                                      text: ', ', style: TextStyle(color: Color(0xFFF5A100))),
                                  TextSpan(text: firstName),
                                  const TextSpan(
                                      text: '!', style: TextStyle(color: Color(0xFFF5A100))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                            );
                          },
                          icon: SvgPicture.asset(
                            'assets/icons/notification.svg',
                            width: 28,
                            height: 28,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Balance card
                    Container(
                      width: double.infinity,
                      height: 93,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3F000000),
                            spreadRadius: 0,
                            offset: Offset(0, 2),
                            blurRadius: 2,
                          )
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 11,
                            top: 21,
                            child: Text(
                              'Balance',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF2E2E2E),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 11,
                            top: 42,
                            child: _isWalletLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1D5572),
                                    ),
                                  )
                                : Text(
                                    '${_walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} $_walletCurrency',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF2E2E2E),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          Positioned(
                            right: 11,
                            top: 20,
                            child: Container(
                              width: 48,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/wallet.png',
                                    width: 25,
                                    height: 25,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.account_balance_wallet,
                                        color: Color(0xFF1D5572),
                                        size: 25),
                                  ),
                                  const Text(
                                    'Wallet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Roadmap Progress (only when roadmap exists) ──────
              if (showRoadmap) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D5572),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x7F000000),
                          spreadRadius: 0,
                          offset: Offset(0, 4),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header row: white background ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    color: Color(0xFF001636),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Learning Progress',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFF5A100),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$progressPercent%',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF001636), 
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ── Progress bar + sub-text: teal background ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Stack(
                                  children: [
                                    // Track
                                    Container(
                                      width: double.infinity,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0x7FF5A100),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                    ),
                                    // Fill
                                    FractionallySizedBox(
                                      widthFactor: progressPercent / 100,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Sub-text
                              Text(
                                "Keep going! You're making great progress on your roadmap.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Quick Actions title ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Quick Actions',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1D5572),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Quick Actions cards ──────────────────────────────
              if (!showRoadmap) ...[
                // ── NO ROADMAP: full-width vertical list ────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildListActionCard(
                        context,
                        imagePath: 'assets/images/skill_assessment_logo.png',
                        fallbackIcon: Icons.assessment,
                        iconColor: const Color(0xFF1D5572),
                        title: 'Skill Assessment',
                        subtitle: 'Discover your strengths',
                        borderColor: const Color(0xFF1D5572),
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                              builder: (_) => const AssessmentStartScreen()))
                              .then((_) => _loadRoadmapStatus());
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildListActionCard(
                        context,
                        imagePath: 'assets/images/cv_optimizer_logo.png',
                        fallbackIcon: Icons.description,
                        iconColor: const Color(0xFFF5A100),
                        title: 'CV Optimizer',
                        subtitle: 'Polish your resume',
                        borderColor: const Color(0xFFF5A100),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const CVOptimizerScreen()));
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildListActionCard(
                        context,
                        imagePath: 'assets/images/find_mentor_logo.png',
                        fallbackIcon: Icons.person_search,
                        iconColor: const Color(0xFF1D5572),
                        title: 'Find Mentor',
                        subtitle: 'Connect with experts',
                        borderColor: const Color(0xFF1D5572),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const MentorshipScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // ── HAS ROADMAP: original 2-column grid ─────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Skill Assessment
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                    builder: (_) => const AssessmentStartScreen()))
                                    .then((_) => _loadRoadmapStatus());
                              },
                              child: Container(
                                height: 118,
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  border: Border.all(color: const Color(0xFF1D5572)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 12,
                                      top: 12,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12)),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/skill_assessment_logo.png',
                                            width: 24,
                                            height: 24,
                                            errorBuilder: (_, __, ___) => const Icon(
                                                Icons.assessment,
                                                color: Color(0xFF1D5572)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 13,
                                      top: 65,
                                      child: Text('Skill Assessment',
                                          style: GoogleFonts.cairo(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              height: 1.1)),
                                    ),
                                    Positioned(
                                      left: 13,
                                      top: 87,
                                      child: Text('Discover your strengths',
                                          style: GoogleFonts.cairo(
                                              color: Colors.black,
                                              fontSize: 13,
                                              height: 1.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Roadmaps
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const RoadmapScreen()));
                              },
                              child: Container(
                                height: 118,
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  border: Border.all(color: const Color(0xFFF5A100)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 12,
                                      top: 12,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12)),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/roadmaps_logo.png',
                                            width: 23,
                                            height: 23,
                                            errorBuilder: (_, __, ___) => const Icon(
                                                Icons.map,
                                                color: Color(0xFFF5A100)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 13,
                                      top: 65,
                                      child: Text('Roadmaps',
                                          style: GoogleFonts.cairo(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              height: 1.1)),
                                    ),
                                    Positioned(
                                      left: 13,
                                      top: 87,
                                      child: Text('Find your ideal path',
                                          style: GoogleFonts.cairo(
                                              color: Colors.black,
                                              fontSize: 13,
                                              height: 1.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // CV Optimizer
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const CVOptimizerScreen()));
                              },
                              child: Container(
                                height: 118,
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  border: Border.all(color: const Color(0xFFF5A100)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 10,
                                      top: 12,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12)),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/cv_optimizer_logo.png',
                                            width: 20,
                                            height: 25,
                                            errorBuilder: (_, __, ___) => const Icon(
                                                Icons.description,
                                                color: Color(0xFFF5A100)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      top: 65,
                                      child: Text('CV Optimizer',
                                          style: GoogleFonts.cairo(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              height: 1.1)),
                                    ),
                                    Positioned(
                                      left: 10,
                                      top: 87,
                                      child: Text('Polish your resume',
                                          style: GoogleFonts.cairo(
                                              color: Colors.black,
                                              fontSize: 13,
                                              height: 1.7)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Find Mentor
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const MentorshipScreen()));
                              },
                              child: Container(
                                height: 118,
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  border: Border.all(color: const Color(0xFF1D5572)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 12,
                                      top: 12,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12)),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/images/find_mentor_logo.png',
                                            width: 27,
                                            height: 18,
                                            errorBuilder: (_, __, ___) => const Icon(
                                                Icons.person_search,
                                                color: Color(0xFF1D5572)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 13,
                                      top: 65,
                                      child: Text('Find Mentor',
                                          style: GoogleFonts.cairo(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              height: 1.1)),
                                    ),
                                    Positioned(
                                      left: 13,
                                      top: 87,
                                      child: SizedBox(
                                        width: 124,
                                        child: Text('Connect with experts',
                                            style: GoogleFonts.cairo(
                                                color: Colors.black,
                                                fontSize: 13,
                                                height: 1.7)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Recommended for You ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Recommended for You',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1D5572),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1D5572)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3F000000),
                        spreadRadius: 0,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      )
                    ],
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFAF5FF), Color(0xFFEFF6FF)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D5572),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Center(
                            child: Icon(Icons.person_add, color: Colors.white, size: 27),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complete Your Profile',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add more details to get better career recommendations and mentor matches.',
                                style: GoogleFonts.cairo(
                                  color: Colors.black,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5A100),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Update Profile',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100), // space for nav bar

              // ── Bottom Nav ───────────────────────────────────────
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, Icons.home, 'Home', true),
            _buildNavItem(context, Icons.assessment, 'assess', false),
            _buildNavItem(context, Icons.chat, 'Chat', false),
            _buildNavItem(context, Icons.person, 'Profile', false),
          ],
        ),
      ),
    );
  }

  /// Full-width card used in the no-roadmap list layout
  Widget _buildListActionCard(
      BuildContext context, {
        required String imagePath,
        required IconData fallbackIcon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required Color borderColor,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(fallbackIcon, color: iconColor, size: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    color: Colors.black,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (label == 'assess') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AssessmentStartScreen()),
          );
        } else if (label == 'Profile') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        } else if (label == 'Chat') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatsScreen()),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF001636), size: 24),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF001636),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
