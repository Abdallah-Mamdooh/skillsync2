import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import './email_signup_screen.dart';
import '../student_homescreen.dart';
import '../mentorship_screen.dart';
import '/services/google_auth_service.dart';
import './forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Brand colors
  static const Color _bgColor = Color(0xFF1D5572);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _accentGold = Color(0xFFF5A100);
  static const Color _darkTeal = Color(0xFF1D5572);
  static const Color _hintColor = Color(0xFFAAAAAA);
  static const Color _borderColor = Color(0xFFDDDDDD);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login Failed Dialog ──────────────────────────────────────────────────
  void _showLoginFailedDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red circle with X icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFD32F2F),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),

                // "Login Failed" title
                const Text(
                  'Login Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle message
                Text(
                  message ??
                      'Please check your email and password\nand try again',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD32F2F),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Try again button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5572),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'try again',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Header ──────────────────────────────────────────────────
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Login to continue your career journey',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 36),

                // ── LOGIN title ABOVE the card ───────────────────────────────
                const Center(
                  child: Text(
                    'LOGIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card ─────────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Email Field ────────────────────────────────────────
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF333333)),
                        decoration: InputDecoration(
                          hintText: 'your.email@example.com',
                          hintStyle:
                          const TextStyle(color: _hintColor, fontSize: 14),
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: _hintColor, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                            const BorderSide(color: _bgColor, width: 1.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Password Field ─────────────────────────────────────
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF333333)),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle:
                          const TextStyle(color: _hintColor, fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: _hintColor, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _hintColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(
                                      () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                            const BorderSide(color: _bgColor, width: 1.8),
                          ),
                        ),
                      ),

                      // ── Forgot Password ────────────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: _accentGold,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Login Button ───────────────────────────────────────
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () async {
                                final email =
                                _emailController.text.trim();
                                final password =
                                _passwordController.text.trim();

                                // Validate empty fields
                                if (email.isEmpty || password.isEmpty) {
                                  _showLoginFailedDialog(
                                    context,
                                    message:
                                    'Please enter your email\nand password',
                                  );
                                  return;
                                }

                                final success = await authProvider.login(
                                  email: email,
                                  password: password,
                                );

                                if (success && context.mounted) {
                                  final user = authProvider.user;
                                  if (user != null &&
                                      user['role'] == 'mentor') {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const MentorshipScreen(),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const StudentHomeScreen(),
                                      ),
                                    );
                                  }
                                } else if (context.mounted) {
                                  // Show Login Failed dialog
                                  _showLoginFailedDialog(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _darkTeal,
                                foregroundColor: _accentGold,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: _accentGold,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Divider ────────────────────────────────────────────
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Color(0xFFDDDDDD))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or continue with',
                              style:
                              TextStyle(color: _hintColor, fontSize: 13),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFDDDDDD))),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Google Button ──────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () async {
                            final result =
                            await GoogleAuthService.signInWithGoogle();

                            if (result['success'] == true &&
                                context.mounted) {
                              final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false);
                              final email = result['email'] as String?;

                              if (email != null) {
                                final success = await authProvider.googleLogin(
                                    email: email);
                                if (success && context.mounted) {
                                  final user = authProvider.user;
                                  if (user != null &&
                                      user['role'] == 'mentor') {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const MentorshipScreen(),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const StudentHomeScreen(),
                                      ),
                                    );
                                  }
                                } else if (context.mounted) {
                                  _showLoginFailedDialog(
                                    context,
                                    message:
                                    'Google login failed.\nPlease try again.',
                                  );
                                }
                              }
                            } else if (context.mounted &&
                                result['message'] != 'User cancelled') {
                              _showLoginFailedDialog(
                                context,
                                message: result['message'] ??
                                    'Google login failed.\nPlease try again.',
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleLogo(),
                              const SizedBox(width: 10),
                              const Text(
                                'Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Sign Up ──────────────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style:
                        TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmailSignupScreen(role: 'user'),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

