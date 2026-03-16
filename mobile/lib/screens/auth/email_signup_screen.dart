import 'package:flutter/material.dart';

void main() {
  runApp(const SkillSyncApp());
}

class SkillSyncApp extends StatelessWidget {
  const SkillSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFF2C5364),
      ),
      home: const EmailSignupScreen(role: 'user'),
    );
  }
}

enum UserRole { student, mentor }

class EmailSignupScreen extends StatefulWidget {
  const EmailSignupScreen({super.key, required this.role});

  final String role;

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  UserRole _selectedRole = UserRole.student;

  @override
  void initState() {
    super.initState();
    _selectedRole =
        widget.role.toLowerCase() == 'mentor' ? UserRole.mentor : UserRole.student;
  }

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cvUrlController = TextEditingController();
  final _linkedinUrlController = TextEditingController();

  bool _obscurePassword = true;

  static const Color _primaryColor = Color(0xFF2C5364);
  static const Color _accentColor = Color(0xFFF5A623);
  static const Color _cardBg = Colors.white;
  static const Color _inputBg = Color(0xFFF0F0F0);
  static const Color _labelColor = Color(0xFF1A1A2E);
  static const Color _hintColor = Color(0xFFAAAAAA);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cvUrlController.dispose();
    _linkedinUrlController.dispose();
    super.dispose();
  }

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
              // Header
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

              // Card
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

                    // Role Selection
                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            role: UserRole.student,
                            selectedRole: _selectedRole,
                            label: 'Student',
                            subtitle: 'Looking for guidance',
                            icon: Icons.school_outlined,
                            onTap: () =>
                                setState(() => _selectedRole = UserRole.student),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleCard(
                            role: UserRole.mentor,
                            selectedRole: _selectedRole,
                            label: 'Mentor',
                            subtitle: 'Share expertise',
                            icon: Icons.people_outline,
                            onTap: () =>
                                setState(() => _selectedRole = UserRole.mentor),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Full Name
                    _buildLabel('Full Name *'),
                    _buildTextField(
                      controller: _fullNameController,
                      hint: 'John Doe',
                    ),
                    const SizedBox(height: 14),

                    // Email
                    _buildLabel('Email Address *'),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'your.email@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    // Password
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

                    // Phone
                    _buildLabel('Phone number *'),
                    _buildTextField(
                      controller: _phoneController,
                      hint: '+02',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    // CV URL — only required for mentor
                    _buildLabel(
                      _selectedRole == UserRole.mentor
                          ? 'CV url *'
                          : 'CV url',
                    ),
                    _buildTextField(
                      controller: _cvUrlController,
                      hint: '.....',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 14),

                    // LinkedIn URL — only required for mentor
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

                    const SizedBox(height: 20),

                    // Terms text
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
                  ],
                ),
              ),

              // "Already have an account?" — only shown for student
              if (_selectedRole == UserRole.student) ...[
                const SizedBox(height: 24),
                Center(
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accentColor, width: 1.5),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final UserRole selectedRole;
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selectedRole,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  bool get isSelected => role == selectedRole;

  static const Color _accentColor = Color(0xFFF5A623);
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
            // Icon circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentColor.withOpacity(0.12)
                    : _unselectedIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? _accentColor : const Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _accentColor : _unselectedText,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? _accentColor.withOpacity(0.8)
                    : const Color(0xFFAAAAAA),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
