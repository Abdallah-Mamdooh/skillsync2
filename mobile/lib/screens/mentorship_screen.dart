import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorshipScreen extends StatelessWidget {
  const MentorshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5572),
        title: const Text('Mentorship', style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mentorship',
                    style: GoogleFonts.inter(fontSize: 25, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text('Connect with verified industry experts',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1F2937))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Upcoming Session Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x3F1D5572),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x1E000000), spreadRadius: 0, offset: Offset(0, 2), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.calendar_today, size: 17, color: Color(0xFF1F2937)),
                      const SizedBox(width: 8),
                      Text('Mentorship Talk', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                    ]),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sarah Johnson', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                          Text('Full Stack Developer', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.access_time, size: 12, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text('Feb 17, 2026 at 2:00 PM', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                            const Spacer(),
                            const Icon(Icons.timer_outlined, size: 11, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text('120 min', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                          ]),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.video_call, size: 16, color: Colors.white),
                              label: Text('Book Session', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D5572), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 8),
                      Text('Search mentors', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: const Icon(Icons.filter_list, size: 18, color: Color(0xFF6B7280)),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Mentor Cards
            _buildMentorCard(
              initials: 'SJ', initialsColor: const Color(0xFFF5A100),
              name: 'Sarah Johnson', role: 'Full Stack Developer',
              isOnline: true, rating: '4.9', reviews: '127 reviews', experience: '8+ years',
              expertise: ['Node.js', 'System Design', 'React', 'Career Coaching'],
              price: '150 EGP/HOUR', buttonColor: const Color(0xFFF5A100),
            ),
            _buildMentorCard(
              initials: 'MC', initialsColor: const Color(0xFF1D5572),
              name: 'Michael Chen', role: 'Data Science Lead',
              isOnline: true, rating: '4.8', reviews: '94 reviews', experience: '6+ years',
              expertise: ['Python', 'Machine Learning', 'Analytics', 'Interview Prep'],
              price: '75 EGP/HOUR', buttonColor: const Color(0xFF1D5572),
            ),
            _buildMentorCard(
              initials: 'ER', initialsColor: const Color(0xFFF5A100),
              name: 'Emily Rodriguez', role: 'UI/UX Designer',
              isOnline: false, rating: '5', reviews: '82 reviews', experience: '6+ years',
              expertise: ['UI/UX', 'Figma', 'Design Systems', 'Portfolio Review'],
              price: '150 EGP/HOUR', buttonColor: const Color(0xFFF5A100),
            ),
            _buildMentorCard(
              initials: 'DK', initialsColor: const Color(0xFF1D5572),
              name: 'David Kim', role: 'Product Manager',
              isOnline: true, rating: '4.7', reviews: '65 reviews', experience: '7+ years',
              expertise: ['Product Strategy', 'Agile', 'Case Studies', 'Leadership'],
              price: '75 EGP/HOUR', buttonColor: const Color(0xFF1D5572),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1D5572),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'assess'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMentorCard({
    required String initials, required Color initialsColor,
    required String name, required String role,
    required bool isOnline, required String rating,
    required String reviews, required String experience,
    required List<String> expertise,
    required String price, required Color buttonColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x1E000000), spreadRadius: 0, offset: Offset(0, 2), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: initialsColor, borderRadius: BorderRadius.circular(25)),
                  child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                      Text(role, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFFD1FAE5) : const Color(0xFFFED7AA),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF059669) : const Color(0xFFC2410C),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(isOnline ? 'ONLINE' : 'OFFLINE',
                      style: GoogleFonts.inter(fontSize: 12, color: isOnline ? const Color(0xFF059669) : const Color(0xFFC2410C))),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.star, size: 11, color: Color(0xFFFFA629)),
              const SizedBox(width: 4),
              Text(rating, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFFA629))),
              const SizedBox(width: 4),
              Text(reviews, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF6B7280))),
              const SizedBox(width: 16),
              Text(experience, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFFA629))),
              const SizedBox(width: 4),
              Text('Experience', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF6B7280))),
            ]),
            const SizedBox(height: 8),
            Text('Expertise:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: expertise.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(e, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFF5A100))),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.monetization_on_outlined, size: 14, color: Colors.black),
              const SizedBox(width: 4),
              Text(price, style: GoogleFonts.inter(fontSize: 12, color: Colors.black)),
              const SizedBox(width: 16),
              const Icon(Icons.timer_outlined, size: 14, color: Colors.black),
              const SizedBox(width: 4),
              Text('Max. 2 hours', style: GoogleFonts.inter(fontSize: 12, color: Colors.black)),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('BOOK SESSION', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
