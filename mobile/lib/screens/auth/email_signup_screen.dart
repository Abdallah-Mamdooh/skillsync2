import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class EmailSignupScreen extends StatefulWidget {
  final String role;
  const EmailSignupScreen({super.key, required this.role});

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  bool _isPasswordVisible = false;

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
                      _buildTextField(label: 'Full Name', hint: 'Enter your full name'),
                      const SizedBox(height: 24),
                      _buildTextField(label: 'Email', hint: 'ex.abdallah@gmail.com', keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 24),
                      _buildTextField(label: 'Phone Number', hint: 'Enter your phone number', keyboardType: TextInputType.phone),
                      const SizedBox(height: 24),
                       _buildPasswordField(),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Handle signup logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5A100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'Signup',
                            style: GoogleFonts.getFont(
                              'Urbanist',
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

    Widget _buildTextField({required String label, required String hint, TextInputType keyboardType = TextInputType.text}) {
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
