import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/page_indicators.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skip() => _goToLogin();

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A4A),
      body: Stack(
        children: [
          // PageView
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _OnboardingPageOne(
                onGetStarted: () => _goToPage(1),
                onLogin: _goToLogin,
              ),
              _OnboardingPageWithBg(
                title: 'START YOUR\nCAREER JOURNEY',
                description:
                    "Choosing a career shouldn't be confusing or stressful. "
                    "SkillSync's intelligent assessment evaluates your skills, "
                    "interests, and experience to recommend career paths that "
                    "fit who you are and where the market is going.",
                imagePath: 'assets/images/page2.png',
              ),
              _OnboardingPageWithBg(
                title: 'LEARN FROM EXPERTS WHO\u2019VE BEEN IN YOUR PLACE',
                description:
                    'Career growth is faster when you learn from someone experienced. SkillSync connects you with verified mentors who understand your challenges and guide you step by step toward your goals.',
                imagePath: 'assets/images/page3,4.png',
              ),
              _OnboardingPageWithBg(
                title: 'TURN YOUR CV INTO \nA CAREER MAGNET',
                description:
                    'Your CV shouldn\u2019t just list your experience \u2014 it should tell your story the right way. SkillSync uses advanced AI to deeply analyze your resume, detect missing skills, improve wording, and optimize it for modern recruiters and ATS systems.',
                imagePath: 'assets/images/page3,4.png',
              ),
            ],
          ),

          // Bottom nav — hidden on page 0
          if (_currentPage != 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: OnboardingPageIndicators(
                            currentIndex: _currentPage,
                            count: _totalPages,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          child: TextButton(
                            onPressed: _skip,
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: _NextButton(onPressed: _next),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Page 1 ───────────────────────────────────────────────────────────────────

class _OnboardingPageOne extends StatelessWidget {
  const _OnboardingPageOne({
    required this.onGetStarted,
    required this.onLogin,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Image.asset(
          'assets/images/onboarding_bg.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  width: size.width * 0.70,
                  height: size.height * 0.35,
                ),

                const SizedBox(height: 4),

                // App name
                const Text(
                  'SKILLSYNC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    fontFamily: 'Inter',
                    fontFamilyFallback: [
                      'Roboto',
                      'sans-serif'
                    ], // optional fallback
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle description
                const Text(
                  'AI-powered career guidance to help you\ndiscover your perfect path',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF1D5572),
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 32),

                // Get Started button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5572),
                      foregroundColor: const Color(0xFFF5A100),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Already have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: const Color(0xFF1D5572),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: onLogin,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: const Color(0xFF1D5572),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Pages 2, 3, 4 ────────────────────────────────────────────────────────────

class _OnboardingPageWithBg extends StatelessWidget {
  const _OnboardingPageWithBg({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Dark base
        Container(color: const Color(0xFF1A3A4A)),

        // 2. Gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5A100),
                Color(0xFF1D5572),
              ],
              stops: [0.0, 0.55],
            ),
          ),
        ),

        // 3. Half-circle image at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: size.height * 0.52,
            child: ClipPath(
              clipper: _BottomHalfCircleClipper(),
              child: Image.asset(
                imagePath,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),

        // 4. Text content — positioned below the image curve
        Positioned(
          top: size.height * 0.57,
          left: 32,
          right: 32,
          bottom: 80,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.accentOrange,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Next Button ──────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentOrange,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: AppColors.accentOrange.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Clipper ──────────────────────────────────────────────────────────────────

class _BottomHalfCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final curveDepth = math.min(size.height * 0.22, 160.0);
    final path = Path()
      ..lineTo(0, size.height - curveDepth)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + curveDepth,
        size.width,
        size.height - curveDepth,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
