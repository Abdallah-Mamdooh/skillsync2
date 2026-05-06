import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Student/student_homescreen.dart';

enum UserRole { student, mentor }

class EmailSignupScreen extends StatefulWidget {
  const EmailSignupScreen({super.key, required this.role});

  final String role;

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  late UserRole _selectedRole;

  // ── Signup Failed Dialog ─────────────────────────────────────────────────
  void _showSignupFailedDialog(BuildContext context, {String? message}) {
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
                const Text(
                  'Signup Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message ?? 'Please check your details\nand try again',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD32F2F),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5572),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
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

  // ── Mentor Pending Approval Dialog ──────────────────────────────────────
  void _showMentorPendingDialog(BuildContext context) {
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF2E7D32),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Thank You for Applying!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D5572),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your mentor application has been submitted.\n'
                  'Once our team reviews and approves your profile,\n'
                  'you will be able to log in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5572),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Back to Login',
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
  void initState() {
    super.initState();
    _selectedRole = widget.role.toLowerCase() == 'mentor'
        ? UserRole.mentor
        : UserRole.student;
  }

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _sessionFareController = TextEditingController();
  final _cvUrlController = TextEditingController();
  final _linkedinUrlController = TextEditingController();

  bool _obscurePassword = true;

  static const Color _primaryColor = Color(0xFF1D5572);
  static const Color _accentColor = Color(0xFFF5A100);
  static const Color _cardBg = Colors.white;
  static const Color _inputBg = Color(0xFFF5F5F5);
  static const Color _labelColor = Color(0xFF1A1A2E);
  static const Color _hintColor = Color(0xFFAAAAAA);
  static const Color _borderColor = Color(0xFFDDDDDD);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _bankAccountNumberController.dispose();
    _sessionFareController.dispose();
    _cvUrlController.dispose();
    _linkedinUrlController.dispose();
    super.dispose();
  }

  // ── Session Fare Button ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Join SkillSync and start your journey',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // ── Card ─────────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role selector label
                    const Text(
                      'I want to sign up as:',
                      style: TextStyle(
                        color: _labelColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Role Selection ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            role: UserRole.student,
                            selectedRole: _selectedRole,
                            label: 'Student',
                            subtitle: 'Looking for guidance',
                            iconBuilder: (isSelected) => SvgPicture.asset(
                              'assets/icons/student sign up.svg',
                              width: 30,
                              height: 30,
                              colorFilter: ColorFilter.mode(
                                isSelected
                                    ? _accentColor
                                    : const Color(0xFF888888),
                                BlendMode.srcIn,
                              ),
                            ),
                            onTap: () => setState(
                                () => _selectedRole = UserRole.student),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleCard(
                            role: UserRole.mentor,
                            selectedRole: _selectedRole,
                            label: 'Mentor',
                            subtitle: 'Share expertise',
                            iconBuilder: (isSelected) => Icon(
                              Icons.people,
                              size: 30,
                              color: isSelected
                                  ? _accentColor
                                  : const Color(0xFF888888),
                            ),
                            onTap: () =>
                                setState(() => _selectedRole = UserRole.mentor),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Full Name ─────────────────────────────────────────
                    _buildLabel('Full Name *'),
                    _buildTextField(
                      controller: _fullNameController,
                      hint: 'John Doe',
                    ),
                    const SizedBox(height: 14),

                    // ── Email ─────────────────────────────────────────────
                    _buildLabel('Email Address *'),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'your.email@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    // ── Password ──────────────────────────────────────────
                    _buildLabel('Password *'),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Create a strong password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _hintColor,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'Must be at least 8 characters',
                        style: TextStyle(fontSize: 11, color: _hintColor),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Phone ─────────────────────────────────────────────
                    _buildLabel('Phone number *'),
                    _buildTextField(
                      controller: _phoneController,
                      hint: '+02',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    // ── Mentor-only fields ────────────────────────────────
                    if (_selectedRole == UserRole.mentor) ...[
                      _buildLabel('Bank Account Number *'),
                      _buildTextField(
                        controller: _bankAccountNumberController,
                        hint: '**** **** **** ****',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── CV URL ────────────────────────────────────────────
                    _buildLabel(
                      _selectedRole == UserRole.mentor ? 'CV url *' : 'CV url',
                    ),
                    _buildTextField(
                      controller: _cvUrlController,
                      hint: '.....',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 14),

                    // ── LinkedIn URL ──────────────────────────────────────
                    _buildLabel(
                      _selectedRole == UserRole.mentor
                          ? 'Linkedin url *'
                          : 'Linkedin url',
                    ),
                    _buildTextField(
                      controller: _linkedinUrlController,
                      hint: '.....',
                      keyboardType: TextInputType.url,
                    ),

                    // ── Session Fare (mentor only) ────────────────────────
                    if (_selectedRole == UserRole.mentor) ...[
                      const SizedBox(height: 14),
                      _buildLabel('Session Fare *'),
                      _buildTextField(
                        controller: _sessionFareController,
                        hint: 'Enter session fare in EGP',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Terms ─────────────────────────────────────────────
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 11, color: _hintColor),
                        children: [
                          TextSpan(
                              text:
                                  'By creating an account, you agree to our '),
                          TextSpan(
                            text: 'TERMS OF SERVICE',
                            style: TextStyle(color: _accentColor),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'PRIVACY POLICY',
                            style: TextStyle(color: _accentColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Sign Up Button ────────────────────────────────────
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : () async {
                                    final fullName =
                                        _fullNameController.text.trim();
                                    final email = _emailController.text.trim();
                                    final password =
                                        _passwordController.text.trim();
                                    final phone = _phoneController.text.trim();
                                    final bankAccountNumber =
                                        _bankAccountNumberController.text
                                            .trim();
                                    final sessionFare =
                                        _sessionFareController.text.trim();
                                    final cvUrl = _cvUrlController.text.trim();
                                    final linkedinUrl =
                                        _linkedinUrlController.text.trim();
                                    final roleStr =
                                        _selectedRole == UserRole.mentor
                                            ? 'mentor'
                                            : 'user';

                                    // ── Basic validation ──────────────────
                                    if (fullName.isEmpty ||
                                        email.isEmpty ||
                                        password.isEmpty ||
                                        phone.isEmpty) {
                                      _showSignupFailedDialog(context,
                                          message:
                                              'Please fill in all required fields');
                                      return;
                                    }

                                    // ── Mentor-specific validation ────────
                                    if (roleStr == 'mentor') {
                                      if (bankAccountNumber.isEmpty ||
                                          sessionFare.isEmpty ||
                                          cvUrl.isEmpty ||
                                          linkedinUrl.isEmpty) {
                                        _showSignupFailedDialog(context,
                                            message:
                                                'Mentors must provide bank account number, session fare, CV, and LinkedIn URLs');
                                        return;
                                      }
                                      if (double.tryParse(sessionFare) ==
                                              null ||
                                          (double.tryParse(sessionFare) ?? 0) <=
                                              0) {
                                        _showSignupFailedDialog(context,
                                            message:
                                                'Please enter a valid session fare');
                                        return;
                                      }
                                    }

                                    // ── Map session fare to string ─────────
                                    final parsedBaseRate =
                                        double.tryParse(sessionFare);

                                    final success = await authProvider.signup(
                                      fullName: fullName,
                                      email: email,
                                      phoneNumber: phone,
                                      password: password,
                                      role: roleStr,
                                      cvUrl: roleStr == 'mentor' ? cvUrl : null,
                                      linkedinUrl: roleStr == 'mentor'
                                          ? linkedinUrl
                                          : null,
                                      additionalInfo: roleStr == 'mentor'
                                          ? bankAccountNumber
                                          : null,
                                      baseRate: roleStr == 'mentor'
                                          ? parsedBaseRate
                                          : null,
                                    );

                                    if (success && context.mounted) {
                                      if (roleStr == 'mentor') {
                                        final token = authProvider.token;
                                        if (token != null) {
                                          await ApiService.postWithAuth(
                                            '/mentors/me',
                                            {
                                              'baseRate': parsedBaseRate ?? 0,
                                              'linkedinUrl': linkedinUrl,
                                            },
                                            token,
                                          );
                                        }
                                        if (context.mounted) {
                                          _showMentorPendingDialog(context);
                                        }
                                      } else {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const StudentHomeScreen(),
                                          ),
                                        );
                                      }
                                    } else if (context.mounted) {
                                      _showSignupFailedDialog(context,
                                          message: authProvider.error ??
                                              'Signup failed. Please try again.');
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
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
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Already have an account? ──────────────────────────────
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      children: [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: _labelColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _labelColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
        filled: true,
        fillColor: _inputBg,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: _primaryColor, width: 1.8),
        ),
      ),
    );
  }
}

// ── Role Card Widget ─────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final UserRole role;
  final UserRole selectedRole;
  final String label;
  final String subtitle;
  final Widget Function(bool isSelected) iconBuilder;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selectedRole,
    required this.label,
    required this.subtitle,
    required this.iconBuilder,
    required this.onTap,
  });

  bool get isSelected => role == selectedRole;

  static const Color _accentColor = Color(0xFFF5A100);
  static const Color _unselectedIconBg = Color(0xFFE8E8E8);
  static const Color _unselectedText = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _accentColor : const Color(0xFFDDDDDD),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentColor.withOpacity(0.12)
                    : _unselectedIconBg,
                shape: BoxShape.circle,
              ),
              child: Center(child: iconBuilder(isSelected)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _accentColor : _unselectedText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected
                    ? _accentColor.withOpacity(0.8)
                    : const Color(0xFFAAAAAA),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
