import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment.dart';

// ===== MENTOR MODEL =====
class MentorData {
  final String initials, name, role, rating, reviews, experience, price;
  final Color initialsColor, buttonColor;
  final bool isOnline;
  final List<String> expertise;

  MentorData({
    required this.initials,
    required this.name,
    required this.role,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.price,
    required this.initialsColor,
    required this.buttonColor,
    required this.isOnline,
    required this.expertise,
  });
}

// ===== MENTORSHIP SCREEN =====
class MentorshipScreen extends StatefulWidget {
  const MentorshipScreen({super.key});

  @override
  State<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends State<MentorshipScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<MentorData> _allMentors = [
    MentorData(
      initials: 'SJ', initialsColor: const Color(0xFFF5A100),
      name: 'Sarah Johnson', role: 'Full Stack Developer',
      isOnline: true, rating: '4.9', reviews: '127 reviews', experience: '8+ years',
      expertise: ['Node.js', 'System Design', 'React', 'Career Coaching'],
      price: '150 EGP/HOUR', buttonColor: const Color(0xFFF5A100),
    ),
    MentorData(
      initials: 'MC', initialsColor: const Color(0xFF1D5572),
      name: 'Michael Chen', role: 'Data Science Lead',
      isOnline: true, rating: '4.8', reviews: '94 reviews', experience: '6+ years',
      expertise: ['Python', 'Machine Learning', 'Analytics', 'Interview Prep'],
      price: '75 EGP/HOUR', buttonColor: const Color(0xFF1D5572),
    ),
    MentorData(
      initials: 'ER', initialsColor: const Color(0xFFF5A100),
      name: 'Emily Rodriguez', role: 'UI/UX Designer',
      isOnline: false, rating: '5', reviews: '82 reviews', experience: '6+ years',
      expertise: ['UI/UX', 'Figma', 'Design Systems', 'Portfolio Review'],
      price: '150 EGP/HOUR', buttonColor: const Color(0xFFF5A100),
    ),
    MentorData(
      initials: 'DK', initialsColor: const Color(0xFF1D5572),
      name: 'David Kim', role: 'Product Manager',
      isOnline: true, rating: '4.7', reviews: '65 reviews', experience: '7+ years',
      expertise: ['Product Strategy', 'Agile', 'Case Studies', 'Leadership'],
      price: '75 EGP/HOUR', buttonColor: const Color(0xFF1D5572),
    ),
  ];

  List<MentorData> _filteredMentors = [];

  @override
  void initState() {
    super.initState();
    _filteredMentors = _allMentors;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMentors = _allMentors.where((m) {
        final nameMatch = m.name.toLowerCase().contains(query);
        final roleMatch = m.role.toLowerCase().contains(query);
        final expertiseMatch = m.expertise.any((e) => e.toLowerCase().contains(query));
        return nameMatch || roleMatch || expertiseMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              // Featured Section
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
                              Text('May 17, 2026 at 2:00 PM', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Search mentors',
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
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
              // List of Mentors
              if (_filteredMentors.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text('No mentors found.', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                  ),
                )
              else
                ..._filteredMentors.map((m) => _buildMentorCard(
                  context: context,
                  initials: m.initials,
                  initialsColor: m.initialsColor,
                  name: m.name,
                  role: m.role,
                  isOnline: m.isOnline,
                  rating: m.rating,
                  reviews: m.reviews,
                  experience: m.experience,
                  expertise: m.expertise,
                  price: m.price,
                  buttonColor: m.buttonColor,
                )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(2),
    );
  }

  Widget _buildMentorCard({
    required BuildContext context,
    required String initials,
    required Color initialsColor,
    required String name,
    required String role,
    required bool isOnline,
    required String rating,
    required String reviews,
    required String experience,
    required List<String> expertise,
    required String price,
    required Color buttonColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x1E000000), spreadRadius: 0, offset: Offset(0, 2), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card body (padding) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: initialsColor, borderRadius: BorderRadius.circular(25)),
                      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                      Text(role, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                    ])),
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
                        Text(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          style: GoogleFonts.inter(fontSize: 12, color: isOnline ? const Color(0xFF059669) : const Color(0xFFC2410C)),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.star, size: 11, color: Color(0xFFFFA629)),
                    const SizedBox(width: 4),
                    Text(rating, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFFA629))),
                    const SizedBox(width: 4),
                    Flexible(child: Text(reviews, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(experience, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFFA629))),
                    const SizedBox(width: 4),
                    Flexible(child: Text('Experience', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)),
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
                ],
              ),
            ),

            // ── Footer bar (matches image) ──
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                const Icon(Icons.access_time, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Available from 2:00 AM',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookSessionScreen(
                        mentorName: name,
                        mentorRole: role,
                        mentorInitials: initials,
                        mentorColor: initialsColor,
                        isOnline: isOnline,
                        rating: rating,
                        reviews: reviews,
                        experience: experience,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5572),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('BOOK SESSION', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== BOOK SESSION SCREEN =====
class BookSessionScreen extends StatefulWidget {
  final String mentorName, mentorRole, mentorInitials, rating, reviews, experience;
  final Color mentorColor;
  final bool isOnline;

  const BookSessionScreen({super.key, required this.mentorName, required this.mentorRole, required this.mentorInitials, required this.mentorColor, required this.isOnline, required this.rating, required this.reviews, required this.experience});

  @override
  State<BookSessionScreen> createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends State<BookSessionScreen> {
  String? _selectedType;
  String? _selectedDuration;

  void _onContinue() {
    if (_selectedType == null || _selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a session type and duration first'), backgroundColor: Color(0xFFF5A100)));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatBookSessionScreen(mentorName: widget.mentorName, mentorRole: widget.mentorRole, mentorInitials: widget.mentorInitials, mentorColor: widget.mentorColor, isOnline: widget.isOnline, sessionType: _selectedType!, selectedDuration: _selectedDuration!)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: Color(0xFF1F2937))),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BOOK SESSION', style: GoogleFonts.inter(fontSize: 25, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                    Text('Schedule your mentorship session', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1F2937))),
                  ]),
                ]),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x1E000000), blurRadius: 8, offset: Offset(0, 2))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 50, height: 50, decoration: BoxDecoration(color: widget.mentorColor, borderRadius: BorderRadius.circular(25)), child: Center(child: Text(widget.mentorInitials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.mentorName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                        Text(widget.mentorRole, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: widget.isOnline ? const Color(0xFFD1FAE5) : const Color(0xFFFED7AA), borderRadius: BorderRadius.circular(11)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: widget.isOnline ? const Color(0xFF059669) : const Color(0xFFC2410C), borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 4),
                          Text(widget.isOnline ? 'ONLINE' : 'OFFLINE', style: GoogleFonts.inter(fontSize: 11, color: widget.isOnline ? const Color(0xFF059669) : const Color(0xFFC2410C))),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.star, size: 11, color: Color(0xFFFFA629)),
                      const SizedBox(width: 4),
                      Text(widget.rating, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFFA629))),
                      const SizedBox(width: 4),
                      Flexible(child: Text(widget.reviews, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text(widget.experience, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFFA629))),
                      const SizedBox(width: 4),
                      Flexible(child: Text('Experience', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                Text('Choose Session Type', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text('Select the type of session that works best for you', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1F2937))),
                const SizedBox(height: 16),
                _buildSessionTypeCard(type: 'chat', icon: Icons.chat_bubble_outline, title: 'Chat Session', subtitle: 'Text-based conversation with the mentor', durations: [{'duration': '15 minutes', 'price': '75 EGP'}, {'duration': '30 minutes', 'price': '100 EGP'}, {'duration': '60 minutes', 'price': '150 EGP'}]),
                const SizedBox(height: 16),
                _buildSessionTypeCard(type: 'call', icon: Icons.phone_outlined, title: 'Call Session', subtitle: 'Voice call with the mentor', durations: [{'duration': '15 minutes', 'price': '125 EGP'}, {'duration': '30 minutes', 'price': '175 EGP'}, {'duration': '60 minutes', 'price': '200 EGP'}]),
                const SizedBox(height: 20),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 16),
            child: SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D5572), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text('Continue', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSessionTypeCard({required String type, required IconData icon, required String title, required String subtitle, required List<Map<String, String>> durations}) {
    final isSelected = _selectedType == type;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFFF5A100) : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF1D5572), borderRadius: BorderRadius.circular(24)), child: Icon(icon, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)), overflow: TextOverflow.ellipsis, maxLines: 2),
            ])),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFD9D9D9)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text('Available durations:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280))),
          ]),
        ),
        ...durations.map((d) => _buildDurationRow(type, d['duration']!, d['price']!)).toList(),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildDurationRow(String type, String duration, String price) {
    final isSelected = _selectedType == type && _selectedDuration == duration;
    return GestureDetector(
      onTap: () => setState(() { _selectedType = type; _selectedDuration = duration; }),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFFFF7ED) : Colors.white, border: Border.all(color: isSelected ? const Color(0xFFF5A100) : const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(duration, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
          Text(price, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFF5A100))),
        ]),
      ),
    );
  }
}

// ===== CHAT BOOK SESSION SCREEN =====
class ChatBookSessionScreen extends StatefulWidget {
  final String mentorName, mentorRole, mentorInitials, sessionType, selectedDuration;
  final Color mentorColor;
  final bool isOnline;

  const ChatBookSessionScreen({super.key, required this.mentorName, required this.mentorRole, required this.mentorInitials, required this.mentorColor, required this.isOnline, required this.sessionType, required this.selectedDuration});

  @override
  State<ChatBookSessionScreen> createState() => _ChatBookSessionScreenState();
}

class _ChatBookSessionScreenState extends State<ChatBookSessionScreen> {
  String? _selectedDuration;
  String? _selectedPayment;

  List<Map<String, String>> get _durations => widget.sessionType == 'chat'
      ? [{'duration': '15 minutes', 'price': '75 EGP'}, {'duration': '30 minutes', 'price': '100 EGP'}, {'duration': '60 minutes', 'price': '150 EGP'}]
      : [{'duration': '15 minutes', 'price': '125 EGP'}, {'duration': '30 minutes', 'price': '175 EGP'}, {'duration': '60 minutes', 'price': '200 EGP'}];

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.selectedDuration;
  }

  void _onContinue() {
    if (_selectedDuration == null || _selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a duration and payment method'), backgroundColor: Color(0xFFF5A100)));
      return;
    }

    final selectedDurationData = _durations.firstWhere((d) => d['duration'] == _selectedDuration);
    final priceString = selectedDurationData['price']!.split(' ')[0];
    final price = double.parse(priceString);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          mentorName: widget.mentorName,
          sessionTime: "May 17, 2026 at 2:00 PM",
          sessionDuration: _selectedDuration!,
          sessionType: widget.sessionType == 'chat' ? 'Chat Session' : 'Call Session',
          sessionPrice: price,
          walletBalance: 1200.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: Color(0xFF1F2937))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.sessionType == 'chat' ? 'CHAT SESSION BOOKING' : 'CALL SESSION BOOKING', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                    Text('Schedule your mentorship session', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1F2937))),
                  ])),
                ]),
                const SizedBox(height: 24),
                if (widget.sessionType == 'call') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4400).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'NOTE:\n',
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFF5A100)),
                          ),
                          TextSpan(
                            text: 'A meeting link will be sent to your email after booking .',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text('Choose Session Duration', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                const SizedBox(height: 12),
                ..._durations.map((d) => _buildDurationRow(d['duration']!, d['price']!)).toList(),
                const SizedBox(height: 24),
                Text('Choose Payment Method', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                const SizedBox(height: 12),
                _buildPaymentOption(
                  value: 'wallet',
                  child: Row(children: [
                    Expanded(child: Text('SKILLSYNC WALLET', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black))),
                    const SizedBox(width: 12),
                    Image.asset('assets/images/wallet.png', width: 26, height: 26),
                  ]),
                ),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  value: 'mobile',
                  child: Row(children: [
                    Expanded(child: Text('MOBILE WALLET', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black))),
                    const SizedBox(width: 6),
                    Image.asset('assets/images/vodafone.png', width: 32, height: 32),
                    const SizedBox(width: 6),
                    Image.asset('assets/images/etisalat.png', width: 32, height: 32),
                    const SizedBox(width: 6),
                    Image.asset('assets/images/orange.png', width: 32, height: 32),
                    const SizedBox(width: 6),
                    Image.asset('assets/images/phone wallet.png', width: 32, height: 32),
                  ]),
                ),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  value: 'card',
                  child: Row(children: [
                    Expanded(child: Text('VISA / MASTERCARD', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black))),
                    const SizedBox(width: 12),
                    Image.asset('assets/images/visa.png', width: 50, height: 35),
                    const SizedBox(width: 8),
                    Image.asset('assets/images/mastercard.png', width: 48, height: 30),
                  ]),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 16),
            child: SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D5572), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text('Continue', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _buildBottomNav(2),
    );
  }

  Widget _buildDurationRow(String duration, String price) {
    final isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = duration),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFFFF7ED) : Colors.white, border: Border.all(color: isSelected ? const Color(0xFFF5A100) : const Color(0xFFE5E7EB), width: isSelected ? 1.5 : 1), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(duration, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
          Text(price, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFF5A100))),
        ]),
      ),
    );
  }

  Widget _buildPaymentOption({required String value, required Widget child}) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFFFF7ED) : Colors.white, border: Border.all(color: isSelected ? const Color(0xFFF5A100) : const Color(0xFFE5E7EB), width: isSelected ? 1.5 : 1), borderRadius: BorderRadius.circular(8)),
        child: child,
      ),
    );
  }
}

// ===== SHARED BOTTOM NAV =====
BottomNavigationBar _buildBottomNav(int currentIndex) {
  return BottomNavigationBar(
    backgroundColor: const Color(0xFF1D5572),
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'assess'),
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}