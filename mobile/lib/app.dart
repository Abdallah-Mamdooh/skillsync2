import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/Student/student_homescreen.dart';
import 'screens/Mentor/Mentor homescreen.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/reset_password_screen.dart';
import 'services/deep_link_service.dart';
import 'utils/role_utils.dart';

class SkillSyncApp extends StatefulWidget {
  const SkillSyncApp({super.key});

  @override
  State<SkillSyncApp> createState() => _SkillSyncAppState();
}

class _SkillSyncAppState extends State<SkillSyncApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    DeepLinkService.instance.init(
      onResetLink: (token) {
        final navigator = _navigatorKey.currentState;
        if (navigator == null) return;
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: '',
              resetToken: token,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'SkillSync',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          navigatorKey: _navigatorKey,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isLoggedIn) {
                final role = auth.user?['role'];
                if (isMentorRole(role)) {
                  return const MentorHomeScreen();
                }
                return const StudentHomeScreen();
              }
              return const OnboardingScreen();
            },
          ),
        );
      },
    );
  }
}
