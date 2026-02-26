import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'assessment_flow.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final firstName = user?['fullName']?.split(' ')[0] ?? 'User';

    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            height: 968,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 282,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D5572),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 53,
                  child: Container(
                    width: 306,
                    height: 64,
                    color: Colors.transparent,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 70,
                          top: -1,
                          child: SizedBox(
                            width: 194,
                            height: 36,
                            child: Text(
                              'SKILLSYNC',
                              textAlign: TextAlign.left,
                              style: GoogleFonts.getFont(
                                'Inter',
                                color: const Color(0xFFF5A100),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 0.7,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 70,
                          top: 29,
                          child: SizedBox(
                            width: 275,
                            height: 36,
                            child: RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                style: GoogleFonts.getFont(
                                  'Inter',
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                                children: [
                                  const TextSpan(text: 'Welcome back'),
                                  const TextSpan(
                                    text: ', ',
                                    style: TextStyle(
                                      color: Color(0xFFF5A100),
                                    ),
                                  ),
                                  TextSpan(text: firstName),
                                  const TextSpan(
                                    text: '!',
                                    style: TextStyle(
                                      color: Color(0xFFF5A100),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 61,
                            height: 62,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Color(0xFFF5A100), size: 60),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 13,
                  top: 128,
                  child: Container(
                    width: 345,
                    height: 93,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          spreadRadius: 0,
                          offset: Offset(0, 2),
                          blurRadius: 2,
                        )
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 11,
                          top: 11,
                          child: Text(
                            'Balance',
                            style: GoogleFonts.getFont(
                              'Inter',
                              color: const Color(0xFF2E2E2E),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 11,
                          top: 32,
                          child: Text(
                            '1,000 EGP',
                            style: GoogleFonts.getFont(
                              'Inter',
                              color: const Color(0xFF2E2E2E),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 11,
                          top: 68,
                          child: Text(
                            'Coin Reward 5.400',
                            style: TextStyle(
                              color: Color(0xFF919191),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                        Positioned(
                          left: 285,
                          top: 20,
                          child: SizedBox(
                            width: 48,
                            height: 54,
                            child: Container(
                              width: 48,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Color(0xFF1D5572), size: 25),
                                  Text(
                                    'Wallet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Roboto',
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 13,
                  top: 242,
                  child: Container(
                    width: 345,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 13,
                  top: 282,
                  child: Container(
                    width: 345,
                    height: 128,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D5572),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x7F000000),
                          spreadRadius: 0,
                          offset: Offset(0, 4),
                          blurRadius: 12,
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 30,
                  top: 314,
                  child: Container(
                    width: 313,
                    height: 6,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: const Color(0x7FF5A100),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Positioned(
                  left: 30,
                  top: 314,
                  child: Container(
                    width: 238,
                    height: 6,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Positioned(
                  left: 43,
                  top: 250,
                  child: SizedBox(
                    width: 199,
                    height: 36,
                    child: Text(
                      'Learning Progress',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(
                        'Inter',
                        color: const Color(0xFFF5A100),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 25,
                  top: 335,
                  child: SizedBox(
                    width: 319,
                    height: 51,
                    child: Text(
                      "Keep going! You're making great progress on your roadmap.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(
                        'Inter',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 299,
                  top: 249,
                  child: SizedBox(
                    width: 57,
                    height: 36,
                    child: Text(
                      '75%',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(
                        'Inter',
                        color: const Color(0xFF001636),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 26,
                  top: 254,
                  child: Icon(
                    Icons.trending_up,
                    color: Color(0xFF001636),
                    size: 20,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 463,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AssessmentQuestion1()),
                      );
                    },
                    child: Container(
                      width: 165,
                      height: 118,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        border: Border.all(
                          color: const Color(0xFF1D5572),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Container(
                              width: 40,
                              height: 40,
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/skill_assessment_logo.png',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.assessment, color: Color(0xFF1D5572)),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 13,
                            top: 65,
                            child: SizedBox(
                              width: 151,
                              child: Text(
                                'Skill Assessment',
                                style: GoogleFonts.getFont(
                                  'Cairo',
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 13,
                            top: 87,
                            child: Text(
                              'Discover your strengths',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.getFont(
                                'Cairo',
                                color: Colors.black,
                                fontSize: 13,
                                height: 1.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 194,
                  top: 463,
                  child: Container(
                    width: 165,
                    height: 118,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      border: Border.all(
                        color: const Color(0xFFF5A100),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  left: 206,
                  top: 475,
                  child: Container(
                    width: 40,
                    height: 40,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  left: 215,
                  top: 484,
                  child: Image.asset(
                    'assets/images/roadmaps_logo.png',
                    width: 23,
                    height: 23,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.map, color: Color(0xFFF5A100)),
                  ),
                ),
                Positioned(
                  left: 207,
                  top: 528,
                  child: SizedBox(
                    width: 102,
                    child: Text(
                      'Roadmaps',
                      style: GoogleFonts.getFont(
                        'Cairo',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 207,
                  top: 550,
                  child: Text(
                    'Find your ideal path',
                    style: GoogleFonts.getFont(
                      'Cairo',
                      color: Colors.black,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ),
                Positioned(
                  left: 194,
                  top: 593,
                  child: Container(
                    width: 165,
                    height: 118,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      border: Border.all(
                        color: const Color(0xFF1D5572),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  left: 206,
                  top: 605,
                  child: Container(
                    width: 40,
                    height: 40,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  left: 207,
                  top: 658,
                  child: SizedBox(
                    width: 112,
                    child: Text(
                      'Find Mentor',
                      style: GoogleFonts.getFont(
                        'Cairo',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 207,
                  top: 680,
                  child: SizedBox(
                    width: 124,
                    child: Text(
                      'Connect with experts',
                      style: GoogleFonts.getFont(
                        'Cairo',
                        color: Colors.black,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 213,
                  top: 616,
                  child: Image.asset(
                    'assets/images/find_mentor_logo.png',
                    width: 27,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_search, color: Color(0xFF1D5572)),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 423,
                  child: SizedBox(
                    height: 36,
                    child: Text(
                      'Quick Actions',
                      style: GoogleFonts.getFont(
                        'Inter',
                        color: const Color(0xFF1D5572),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 593,
                  child: Container(
                    width: 165,
                    height: 118,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      border: Border.all(
                        color: const Color(0xFFF5A100),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 605,
                  child: Container(
                    width: 40,
                    height: 40,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  left: 25,
                  top: 658,
                  child: SizedBox(
                    width: 120,
                    child: Text(
                      'CV Optimizer',
                      style: GoogleFonts.getFont(
                        'Cairo',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 25,
                  top: 680,
                  child: Text(
                    'Polish your resume',
                    style: GoogleFonts.getFont(
                      'Cairo',
                      color: Colors.black,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ),
                Positioned(
                  left: 34,
                  top: 613,
                  child: Image.asset(
                    'assets/images/cv_optimizer_logo.png',
                    width: 20,
                    height: 25,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.description, color: Color(0xFFF5A100)),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 750,
                  child: Container(
                    width: 347,
                    height: 117,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF1D5572),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          spreadRadius: 0,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        )
                      ],
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFAF5FF), Color(0xFFEFF6FF)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 79,
                  top: 792,
                  child: SizedBox(
                    width: 287,
                    child: Text(
                      'Add more details to get better career recommendations and mentor matches.',
                      style: GoogleFonts.getFont(
                        'Cairo',
                        color: Colors.black,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 714,
                  child: SizedBox(
                    width: 237,
                    height: 36,
                    child: Text(
                      'Recommended for You',
                      style: GoogleFonts.getFont(
                        'Inter',
                        color: const Color(0xFF1D5572),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 76,
                  top: 760,
                  child: SizedBox(
                    width: 221,
                    height: 36,
                    child: Text(
                      'Complete Your Profile',
                      style: GoogleFonts.getFont(
                        'Inter',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  top: 766,
                  child: Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D5572),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_add, color: Colors.white, size: 27),
                    ),
                  ),
                ),
                Positioned(
                  left: 226,
                  top: 826,
                  child: Container(
                    width: 118,
                    height: 32,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A100),
                      border: Border.all(
                        color: const Color(0xFFF5A100),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Positioned(
                  left: 235,
                  top: 832,
                  child: SizedBox(
                    width: 101,
                    height: 19,
                    child: Text(
                      'Update Profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(
                        'Inter',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -11,
                  top: 870,
                  child: Container(
                    width: 393,
                    height: 111,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(Icons.home, 'Home', true),
                        _buildNavItem(Icons.assessment, 'assess', false),
                        _buildNavItem(Icons.chat, 'Chat', false),
                        _buildNavItem(Icons.person, 'Profile', false),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: const Color(0xFF001636),
          size: 24,
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.getFont(
            'Poppins',
            color: const Color(0xFF001636),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            height: 1.4,
          ),
        )
      ],
    );
  }
}
