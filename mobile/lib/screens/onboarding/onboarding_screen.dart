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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding_bg2.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _OnboardingPageOne(),
                      _OnboardingPageTwo(title: 'Get Started'),
                      _OnboardingPageTwo(title: 'Your Adventures Starts Here'),
                      _OnboardingPageTwo(title: 'Your Adventures Starts Here'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
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
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: AppColors.accentOrange,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageOne extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/onboarding_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = MediaQuery.sizeOf(context);
                  final maxW = size.width * 0.85;
                  final maxH = size.height * 0.5;
                  return Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    width: maxW,
                    height: maxH,
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Closer Than You Think',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accentOrange,
                      fontSize: 17,
                    ) ??
                    const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accentOrange,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageTwo extends StatelessWidget {
  const _OnboardingPageTwo({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/onboarding_bg2.png',
          fit: BoxFit.cover,
        ),
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.sizeOf(context).height * 0.38,
            left: 32,
            right: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.accentOrange,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Lorem Ipsum is simply dummy text of the printing and typesetting industry. '
                'Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s.',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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
              color: AppColors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
