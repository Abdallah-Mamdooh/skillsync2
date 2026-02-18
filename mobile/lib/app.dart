import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';

class SkillSyncApp extends StatelessWidget {
  const SkillSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const OnboardingScreen(),
    );
  }
}
