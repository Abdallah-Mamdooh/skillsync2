import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OnboardingPageIndicators extends StatelessWidget {
  const OnboardingPageIndicators({
    super.key,
    required this.currentIndex,
    this.count = 4,
  });

  final int currentIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentOrange : AppColors.indicatorInactive,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
