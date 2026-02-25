import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../homescreen.dart';

class EmailSignupScreen extends StatefulWidget {
  final String role;
  const EmailSignupScreen({super.key, required this.role});

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  bool _isPasswordVisible = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text.trim();
    final emailValid = email.contains('@') && email.contains('.');
    setState(() {
      _isFormValid = name.isNotEmpty && emailValid && phone.isNotEmpty && pass.isNotEmpty;
    });
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'SIGNUP AS \${widget.role.toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 60),
                      _buildTextField(controller: _nameController, label: 'Full Name', hint: 'Enter your full name'),
                      const SizedBox(height: 24),
                      _buildTextField(controller: _emailController, label: 'Email', hint: 'ex.abdallah@gmail.com', keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 24),
                      _buildTextField(controller: _phoneController, label: 'Phone Number', hint: 'Enter your phone number', keyboardType: TextInputType.phone),
                      const SizedBox(height: 24),
                       _buildPasswordField(),
                      const SizedBox(height: 40),
                      Consumer<AuthProvider>(builder: (context, authProvider, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading || !_isFormValid
                                ? null
                                : () async {
                                    final success = await authProvider.signup(
                                      fullName: _nameController.text.trim(),
                                      email: _emailController.text.trim(),
                                      phoneNumber: _phoneController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      role: widget.role,
                                    );

                                    if (success && mounted) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => const HomeScreen(),
                                        ),
                                      );
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(authProvider.error ?? 'Signup failed')),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (!_isFormValid || authProvider.isLoading)
                                  ? const Color(0xFFF5A100).withOpacity(0.4)
                                  : const Color(0xFFF5A100),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Signup',
                                    style: GoogleFonts.getFont(
                                      'Urbanist',
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        );
                      }),
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

    Widget _buildTextField({TextEditingController? controller, required String label, required String hint, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
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
            ),
            style: GoogleFonts.getFont(
              'Inter',
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.2,
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
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
      ],
    );
  }
}
