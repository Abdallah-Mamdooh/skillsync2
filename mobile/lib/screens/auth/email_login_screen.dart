import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../student_homescreen.dart';
import './forgot_password_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  bool _isPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isFormValid = false;
  bool _isEmailValid = true;
  bool _hasEmailAtSymbol = false;
  bool _hasEmailDomain = false;
  bool _hasEmailTld = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      // Email validation checks
      final email = _emailController.text.trim();

      // Check for @ symbol
      _hasEmailAtSymbol = email.contains('@');

      // Check for valid domain (something after @ with a dot)
      if (_hasEmailAtSymbol) {
        final parts = email.split('@');
        if (parts.length == 2) {
          final domainPart = parts[1];
          _hasEmailDomain = domainPart.contains('.') &&
              domainPart.indexOf('.') > 0 &&
              domainPart.indexOf('.') < domainPart.length - 1;

          // Check for valid TLD (at least 2 characters after last dot)
          if (_hasEmailDomain) {
            final lastDotIndex = domainPart.lastIndexOf('.');
            _hasEmailTld = lastDotIndex < domainPart.length - 1 &&
                domainPart.substring(lastDotIndex + 1).length >= 2;
          } else {
            _hasEmailTld = false;
          }
        } else {
          _hasEmailDomain = false;
          _hasEmailTld = false;
        }
      } else {
        _hasEmailDomain = false;
        _hasEmailTld = false;
      }

      // Overall email valid if all conditions met
      _isEmailValid = _hasEmailAtSymbol && _hasEmailDomain && _hasEmailTld;

      // Form is valid only if both email and password are valid
      _isFormValid = _isEmailValid && _passwordController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
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
              child: Center(
                child: SingleChildScrollView(
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'LOGIN',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Email Field
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 56,
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'ex.abdallah@gmail.com',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                hintStyle: GoogleFonts.getFont(
                                  'Inter',
                                  color: const Color(0xFFBCBCBC),
                                  fontSize: 16,
                                ),
                                errorText: _emailController.text.isNotEmpty && !_isEmailValid
                                    ? 'Please enter a valid email address'
                                    : null,
                                errorStyle: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                              style: GoogleFonts.getFont(
                                'Inter',
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Password Field
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 56,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: '***********************',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                hintStyle: GoogleFonts.getFont(
                                  'Inter',
                                  color: const Color(0xFFBCBCBC),
                                  fontSize: 16,
                                ),
                              ),
                              style: GoogleFonts.getFont(
                                'Inter',
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          // Password Empty Warning
                          if (_passwordController.text.isNotEmpty &&
                              _passwordController.text.trim().isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Password cannot be empty or just spaces',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 30),

                          // Login Button with validation
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (!_isFormValid || authProvider.isLoading)
                                  ? null
                                  : () async {
                                final success =
                                await authProvider.login(
                                  email: _emailController.text.trim(),
                                  password:
                                  _passwordController.text.trim(),
                                );

                                if (success && mounted) {
                                  Navigator.of(context)
                                      .pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const StudentHomeScreen(),
                                    ),
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        authProvider.error ??
                                            'Login failed',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_isFormValid && !authProvider.isLoading)
                                    ? const Color(0xFFF5A100)
                                    : const Color(0xFFF5A100).withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                                  : Text(
                                'Login',
                                style: GoogleFonts.getFont(
                                  'Urbanist',
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Form Status Message
                          if (!_isFormValid && (_emailController.text.isNotEmpty || _passwordController.text.isNotEmpty))
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getFormStatusMessage(),
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Forgot Password Link
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.getFont(
                                  'Urbanist',
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormStatusMessage() {
    if (!_isEmailValid && _emailController.text.isNotEmpty) {
      return 'Please enter a valid email address that includes: @ symbol, domain name, and top-level domain (e.g., .com)';
    } else if (_passwordController.text.trim().isEmpty && _passwordController.text.isNotEmpty) {
      return 'Password cannot be empty or just spaces';
    } else if (_emailController.text.isEmpty) {
      return 'Please enter your email address';
    } else if (_passwordController.text.isEmpty) {
      return 'Please enter your password';
    }
    return 'Please complete all required fields';
  }
}