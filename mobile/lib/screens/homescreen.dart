import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 395,
        height: 968,
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
                    width: 393,
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
                              textAlign: TextAlign.center,
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
                          left: 64,
                          top: 29,
                          child: SizedBox(
                            width: 275,
                            height: 36,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.getFont(
                                  'Inter',
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                                children: const [
                                  TextSpan(text: 'Welcome back'),
                                  TextSpan(
                                    text: ', ',
                                    style: TextStyle(
                                      color: Color(0xFFF5A100),
                                    ),
                                  ),
                                  TextSpan(text: 'Abdallah'),
                                  TextSpan(
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
                          child: Image.network(
                            'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0RtgVWh8wVg1fysBxIg4%2Fd6d1aa32d2f717c9e6e38da17fd050184da98181logo.png?alt=media&token=22831f0a-7023-4407-93eb-f7c6e713d346',
                            width: 61,
                            height: 62,
                            fit: BoxFit.none,
                            alignment: Alignment.topLeft,
                            scale: 52.852,
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
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 48,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: 8,
                                          top: 4,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Positioned(
                                                  left: 4,
                                                  top: 4,
                                                  child: Image.network(
                                                    'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0RtgVWh8wVg1fysBxIg4%2F034e53e7a145dd083dc5c66d2703feec29e4fc96Wallet%20filled%20money%20tool.png?alt=media&token=290ddaac-4e57-49ed-81a6-140599007dd4',
                                                    width: 25,
                                                    height: 25,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        const Positioned(
                                          left: 6,
                                          top: 35,
                                          child: Text(
                                            'Wallet',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color(0xFF333333),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.hardEdge,
                    child: Image.network(
                      'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2F9ea7ef1f-54f3-4bb1-b1c3-0bde93732f0f.png',
                      width: 345,
                      height: 168,
                      fit: BoxFit.contain,
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
                Positioned(
                  left: 26,
                  top: 258,
                  child: Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2Fd8bbf075-0b05-48d9-8ec8-a8a23b1bcfe8.png',
                    width: 20,
                    height: 12,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 463,
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
                  left: 24,
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
                  left: 32,
                  top: 483,
                  child: Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2Fa491b64a-67cb-400d-995a-c536db274663.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 25,
                  top: 528,
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
                  left: 25,
                  top: 550,
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
                  child: Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2F7fa89667-81ae-4000-a1e5-8fd19fd52bb0.png',
                    width: 23,
                    height: 23,
                    fit: BoxFit.contain,
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
                  child: Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2F0144c33b-1d7e-4921-9c4a-b43f856b9f96.png',
                    width: 27,
                    height: 18,
                    fit: BoxFit.contain,
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
                  child: Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2F64035a62-ab91-4562-a572-9e0bf9dad5cf.png',
                    width: 20,
                    height: 25,
                    fit: BoxFit.contain,
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
                  ),
                ),
                Positioned(
                  left: 34,
                  top: 778,
                  child: Image.network(
                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2F752a6a1e-e7cd-4846-9574-3effac04420f.png',
                    width: 27,
                    height: 27,
                    fit: BoxFit.contain,
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 32,
                          top: 16,
                          child: Container(
                            width: 56,
                            height: 48,
                            color: Colors.white,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 20,
                                  top: 4,
                                  child: Image.network(
                                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2Fcd8177a7-9412-4369-bf79-6ff6337d3551.png',
                                    width: 16,
                                    height: 17,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  left: -1,
                                  top: 27,
                                  child: SizedBox(
                                    width: 58,
                                    child: Text(
                                      'Home',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.getFont(
                                        'Poppins',
                                        color: const Color(0xFF001636),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 123,
                          top: 16,
                          child: Container(
                            width: 56,
                            height: 48,
                            color: Colors.white,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 21,
                                  top: 3,
                                  child: Image.network(
                                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2F2a714c54-5173-4d2e-b6de-4e853deaaa40.png',
                                    width: 14,
                                    height: 18,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  left: -1,
                                  top: 27,
                                  child: SizedBox(
                                    width: 58,
                                    child: Text(
                                      'assess',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.getFont(
                                        'Poppins',
                                        color: const Color(0xFF001636),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 214,
                          top: 16,
                          child: Container(
                            width: 56,
                            height: 48,
                            color: Colors.white,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 23,
                                  top: 9,
                                  child: Container(
                                    width: 2,
                                    height: 2,
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF001636),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 27,
                                  top: 9,
                                  child: Container(
                                    width: 2,
                                    height: 2,
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF001636),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 31,
                                  top: 9,
                                  child: Container(
                                    width: 2,
                                    height: 2,
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF001636),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 18,
                                  top: 2,
                                  child: Image.network(
                                    'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2F94f57c70-b8d9-4188-9b45-019ff26c11ed.png',
                                    width: 20,
                                    height: 19,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  left: -1,
                                  top: 27,
                                  child: SizedBox(
                                    width: 58,
                                    child: Text(
                                      'Chat',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.getFont(
                                        'Poppins',
                                        color: const Color(0xFF001636),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 305,
                          top: 16,
                          child: Container(
                            width: 56,
                            height: 48,
                            color: Colors.white,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 19,
                                  top: 12,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    clipBehavior: Clip.hardEdge,
                                    child: Image.network(
                                      'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0RtgVWh8wVg1fysBxIg4%2Fb4ae77c1-7cea-4acc-857e-1de8e3d221ba.png',
                                      width: 18,
                                      height: 9,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 24,
                                  top: 3,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                        color: const Color(0xFF001636),
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -1,
                                  top: 27,
                                  child: SizedBox(
                                    width: 58,
                                    child: Text(
                                      'Profile',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.getFont(
                                        'Poppins',
                                        color: const Color(0xFF001636),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
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
}