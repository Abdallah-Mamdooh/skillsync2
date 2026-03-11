import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import './email_login_screen.dart';
import './email_signup_screen.dart';
import '../student_homescreen.dart';
import '/services/google_auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    'LOGIN',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Email Address Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EmailLoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/Email.png',
                            width: 25,
                            height: 25,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Email Address',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ) ??
                                const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Continue with Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await GoogleAuthService.signInWithGoogle();

                        if (result['success'] == true && context.mounted) {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);

                          // GoogleAuthService already called the backend and got
                          // token + user — use them directly without a second call
                          final data = result['data'];
                          final token = data['token'] as String?;
                          final user = data['user'] as Map<String, dynamic>?;

                          if (token != null && user != null) {
                            authProvider.setFromGoogle(token: token, user: user);
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const StudentHomeScreen(),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google login failed: missing data')),
                            );
                          }
                        } else if (context.mounted && result['message'] != 'User cancelled') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'] ?? 'Login failed')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/Google Logo.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ) ??
                                const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "You don't have an account?",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black
                    ) ??
                        TextStyle(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Sign up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await precacheImage(const AssetImage('assets/images/student_signup.png'), context);
                          await precacheImage(const AssetImage('assets/images/mentor_signup.png'), context);
                          try {
                            final bytes = await rootBundle.load('assets/images/student_signup.png');
                            debugPrint('rootBundle loaded student_signup.png: ${bytes.lengthInBytes} bytes');
                          } catch (loadErr, loadSt) {
                            debugPrint('rootBundle.load error for student_signup.png: $loadErr');
                            debugPrint('$loadSt');
                          }
                        } catch (e) {
                          debugPrint('Precache error: $e');
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sign up',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ) ??
                            const TextStyle(
                              color: AppColors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'SIGNUP AS',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 80),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EmailSignupScreen(role: 'user'),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 137,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/student_signup.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Image load error (student_signup.png): $error');
                            debugPrint('$stackTrace');
                            return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EmailSignupScreen(role: 'mentor'),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 137,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/mentor_signup.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Image load error (mentor_signup.png): $error');
                            debugPrint('$stackTrace');
                            return Image.asset('assets/images/logo.png', fit: BoxFit.cover);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.7),
                        ) ??
                            TextStyle(
                              color: AppColors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Log in',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.accentOrange,
                            fontWeight: FontWeight.w600,
                          ) ??
                              const TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
