import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';
import 'payment.dart';

// ===== MENTOR MODEL =====
class MentorData {
  final String id;
  final String userId;
  final String name;
  final String role;
  final String rating;
  final String reviews;
  final String experience;
  final String price;
  final double baseRate;
  final double chatMultiplier;
  final double callMultiplier;
  final String currency;
  final String timezone;
  final bool isOnline;
  final List<String> expertise;

  MentorData({
    required this.id,
    required this.userId,
    required this.name,
    required this.role,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.price,
    required this.baseRate,
    required this.chatMultiplier,
    required this.callMultiplier,
    required this.currency,
    required this.timezone,
    required this.isOnline,
    required this.expertise,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.isEmpty ? 'M' : parts.first[0].toUpperCase();
  }

  double priceFor(String method, int durationMinutes) {
    final multiplier = method == 'call' ? callMultiplier : chatMultiplier;
    return (baseRate * multiplier) * (durationMinutes / 60.0);
  }
}

// ===== MENTORSHIP SCREEN =====
class MentorshipScreen extends StatefulWidget {
  const MentorshipScreen({super.key});

  @override
  State<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends State<MentorshipScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MentorData> _allMentors = [];
  List<MentorData> _filteredMentors = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadMentors();
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
        final expertiseMatch =
            m.expertise.any((e) => e.toLowerCase().contains(query));
        return nameMatch || roleMatch || expertiseMatch;
      }).toList();
    });
  }

  Future<void> _loadMentors() async {
    final response = await ApiService.getPublicMentors();
    if (response['success'] != true) {
      setState(() {
        _isLoading = false;
        _error = response['message']?.toString() ?? 'Failed to load mentors.';
      });
      return;
    }

    final List raw = response['data'] is List ? response['data'] : <dynamic>[];
    final mentors = raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      final expertise = data['expertise'] is List
          ? (data['expertise'] as List).map((e) => e.toString()).toList()
          : <String>[];
      return MentorData(
        id: (data['id'] ?? data['_id'] ?? '').toString(),
        userId: (data['userId'] ?? '').toString(),
        name: (data['fullName'] ?? 'Mentor').toString(),
        role:
            (data['headline'] ?? data['specialization'] ?? 'Mentor').toString(),
        rating: (data['rating'] ?? '0').toString(),
        reviews: '${(data['reviewsCount'] ?? 0).toString()} reviews',
        experience: data['experienceYears'] != null
            ? '${data['experienceYears']}+ years'
            : 'Experience available',
        price:
            '${((data['baseRate'] ?? 0) as num).toStringAsFixed(0)} ${(data['currency'] ?? 'EGP').toString()}/HOUR',
        baseRate: ((data['baseRate'] ?? 0) as num).toDouble(),
        chatMultiplier: ((data['chatMultiplier'] ?? 1) as num).toDouble(),
        callMultiplier: ((data['callMultiplier'] ?? 1) as num).toDouble(),
        currency: (data['currency'] ?? 'EGP').toString(),
        timezone: (data['timezone'] ?? 'Africa/Cairo').toString(),
        isOnline: data['isAvailable'] == true,
        expertise: expertise,
      );
    }).toList();

    setState(() {
      _allMentors = mentors;
      _filteredMentors = mentors;
      _isLoading = false;
      _error = null;
    });
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 20, top: 45, bottom: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Mentorship',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Connect with verified industry experts',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D5572),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x1E000000),
                                  spreadRadius: 0,
                                  offset: Offset(0, 2),
                                  blurRadius: 8)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Image.asset(
                                  'assets/images/calendar-fill.png',
                                  width: 17,
                                  height: 17,
                                ),
                                const SizedBox(width: 8),
                                Text('Mentorship Talk',
                                    style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1F2937))),
                              ]),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sarah Johnson',
                                        style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1F2937))),
                                    Text('Full Stack Developer',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF6B7280))),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Image.asset(
                                          'assets/images/calendar-fill.png',
                                          width: 12,
                                          height: 12,
                                          color: Color(0xFF6B7280)),
                                      const SizedBox(width: 4),
                                      Text('May 17, 2026 at 2:00 PM',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFF6B7280))),
                                      const Spacer(),
                                      const Icon(Icons.access_time,
                                          size: 11, color: Color(0xFF6B7280)),
                                      const SizedBox(width: 4),
                                      Text('120 min',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFF6B7280))),
                                    ]),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color: Colors.white),
                                        label: Text('Book Session',
                                            style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1D5572),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6))),
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
                      // Search Bar - Without search icon
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x1E000000),
                                  spreadRadius: 0,
                                  offset: Offset(0, 2),
                                  blurRadius: 8)
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
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
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: Colors.black),
                                  decoration: InputDecoration(
                                    hintText: 'Search mentors',
                                    hintStyle: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF9CA3AF)),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB))),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/Filter.png',
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(_error!,
                                    style: GoogleFonts.inter(fontSize: 13)),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadMentors,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_filteredMentors.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text('No mentors found.',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280))),
                          ),
                        )
                      else
                        ..._filteredMentors.map((m) => _buildMentorCard(
                              context: context,
                              initials: m.initials,
                              initialsColor: m.isOnline
                                  ? const Color(0xFF1D5572)
                                  : const Color(0xFFF5A100),
                              name: m.name,
                              role: m.role,
                              isOnline: m.isOnline,
                              rating: m.rating,
                              reviews: m.reviews,
                              experience: m.experience,
                              expertise: m.expertise,
                              price: m.price,
                              buttonColor: const Color(0xFF1D5572),
                              mentorData: m,
                            )),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.none),
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
    required MentorData mentorData,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1E000000),
                spreadRadius: 0,
                offset: Offset(0, 2),
                blurRadius: 8)
          ],
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
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: initialsColor,
                          borderRadius: BorderRadius.circular(25)),
                      child: Center(
                          child: Text(initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(name,
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937))),
                          Text(role,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280))),
                        ])),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFFED7AA),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF059669)
                                : const Color(0xFFC2410C),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'ONLINE' : 'OFFLINE',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isOnline
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFC2410C)),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.star, size: 11, color: Color(0xFFFFA629)),
                    const SizedBox(width: 4),
                    Text(rating,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFA629))),
                    const SizedBox(width: 4),
                    Flexible(
                        child: Text(reviews,
                            style: GoogleFonts.inter(
                                fontSize: 8, color: const Color(0xFF6B7280)),
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(experience,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFA629))),
                    const SizedBox(width: 4),
                    Flexible(
                        child: Text('Experience',
                            style: GoogleFonts.inter(
                                fontSize: 8, color: const Color(0xFF6B7280)),
                            overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  Text('Expertise:',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: expertise
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                border:
                                    Border.all(color: const Color(0xFFE9D5FF)),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(e,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFF5A100))),
                            ))
                        .toList(),
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
                const Icon(Icons.access_time,
                    size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Available from 2:00 AM',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color.fromARGB(255, 0, 0, 0)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookSessionScreen(
                        mentor: mentorData,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5572),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('BOOK SESSION',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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
  final MentorData mentor;

  const BookSessionScreen({super.key, required this.mentor});

  @override
  State<BookSessionScreen> createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends State<BookSessionScreen> {
  String? _selectedType;
  String? _selectedDuration;

  void _onContinue() {
    if (_selectedType == null || _selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a session type and duration first'),
          backgroundColor: Color(0xFFF5A100)));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChatBookSessionScreen(
                mentor: widget.mentor,
                sessionType: _selectedType!,
                selectedDuration: _selectedDuration!)));
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 20, top: 40, bottom: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'BOOK SESSION',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Schedule your mentorship session',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D5572),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              color: const Color(0xFFF2F4F6),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x1E000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2))
                            ]),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF1D5572),
                                            borderRadius:
                                                BorderRadius.circular(25)),
                                        child: Center(
                                            child: Text(widget.mentor.initials,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold)))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(widget.mentor.name,
                                              style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      const Color(0xFF1F2937))),
                                          Text(widget.mentor.role,
                                              style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color:
                                                      const Color(0xFF6B7280))),
                                        ])),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: widget.mentor.isOnline
                                              ? const Color(0xFFD1FAE5)
                                              : const Color(0xFFFED7AA),
                                          borderRadius:
                                              BorderRadius.circular(11)),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                    color:
                                                        widget.mentor.isOnline
                                                            ? const Color(
                                                                0xFF059669)
                                                            : const Color(
                                                                0xFFC2410C),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3))),
                                            const SizedBox(width: 4),
                                            Text(
                                                widget.mentor.isOnline
                                                    ? 'ONLINE'
                                                    : 'OFFLINE',
                                                style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color:
                                                        widget.mentor.isOnline
                                                            ? const Color(
                                                                0xFF059669)
                                                            : const Color(
                                                                0xFFC2410C))),
                                          ]),
                                    ),
                                  ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.star,
                                    size: 11, color: Color(0xFFFFA629)),
                                const SizedBox(width: 4),
                                Text(widget.mentor.rating,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFA629))),
                                const SizedBox(width: 4),
                                Flexible(
                                    child: Text(widget.mentor.reviews,
                                        style: GoogleFonts.inter(
                                            fontSize: 8,
                                            color: const Color(0xFF6B7280)),
                                        overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                Text(widget.mentor.experience,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFA629))),
                                const SizedBox(width: 4),
                                Flexible(
                                    child: Text('Experience',
                                        style: GoogleFonts.inter(
                                            fontSize: 8,
                                            color: const Color(0xFF6B7280)),
                                        overflow: TextOverflow.ellipsis)),
                              ]),
                            ]),
                      ),
                      const SizedBox(height: 20),
                      Text('Choose Session Type',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text('Select the type of session that works best for you',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF1F2937))),
                      const SizedBox(height: 16),
                      _buildSessionTypeCard(
                          type: 'chat',
                          icon: Icons.chat_bubble_outline,
                          title: 'Chat Session',
                          subtitle: 'Text-based conversation with the Mentor',
                          durations: [
                            {'duration': '15 minutes', 'price': '75 EGP'},
                            {'duration': '30 minutes', 'price': '100 EGP'},
                            {'duration': '60 minutes', 'price': '150 EGP'}
                          ]),
                      const SizedBox(height: 20),
                    ]),
              ),
            ),
          ),
          Container(
            color: const Color(0xFFF2F4F6),
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5572),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text('Continue',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.none),
    );
  }

  Widget _buildSessionTypeCard(
      {required String type,
      required IconData icon,
      required String title,
      required String subtitle,
      required List<Map<String, String>> durations}) {
    final isSelected = _selectedType == type;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFFF5A100)
                  : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFF1D5572),
                    borderRadius: BorderRadius.circular(24)),
                child: Icon(icon, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937))),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF6B7280)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2),
                ])),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFD9D9D9)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            const Icon(Icons.access_time, size: 17, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text('Available durations:',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B7280))),
          ]),
        ),
        ...durations
            .map((d) => _buildDurationRow(type, d['duration']!, d['price']!))
            .toList(),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildDurationRow(String type, String duration, String price) {
    final isSelected = _selectedType == type && _selectedDuration == duration;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = type;
        _selectedDuration = duration;
      }),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
            border: Border.all(
                color: isSelected
                    ? const Color(0xFFF5A100)
                    : const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(duration,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937))),
          Text(price,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF5A100))),
        ]),
      ),
    );
  }
}

// ===== CHAT BOOK SESSION SCREEN =====
class ChatBookSessionScreen extends StatefulWidget {
  final MentorData mentor;
  final String sessionType;
  final String selectedDuration;

  const ChatBookSessionScreen(
      {super.key,
      required this.mentor,
      required this.sessionType,
      required this.selectedDuration});

  @override
  State<ChatBookSessionScreen> createState() => _ChatBookSessionScreenState();
}

class _ChatBookSessionScreenState extends State<ChatBookSessionScreen> {
  String? _selectedDuration;
  String? _selectedPayment;
  DateTime _selectedDate = DateTime.now();
  String? _selectedStartTime;
  bool _loadingSlots = false;
  List<Map<String, String>> _slots = [];

  List<Map<String, String>> get _durations => [
        {'duration': '15 minutes', 'price': '75 EGP'},
        {'duration': '30 minutes', 'price': '100 EGP'},
        {'duration': '60 minutes', 'price': '150 EGP'}
      ];

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.selectedDuration;
    _loadSlots();
  }

  int get _durationMinutes {
    final value = _selectedDuration?.split(' ').first ?? '30';
    return int.tryParse(value) ?? 30;
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    final date =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final response = await ApiService.getPublicMentorSlots(
      mentorId: widget.mentor.userId,
      date: date,
      durationMinutes: _durationMinutes,
    );
    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final rawSlots =
          data['slots'] is List ? data['slots'] as List : <dynamic>[];
      List<Map<String, String>> slots = rawSlots
          .whereType<Map>()
          .map((s) => {
                'startTime': (s['startTime'] ?? '').toString(),
                'endTime': (s['endTime'] ?? '').toString(),
              })
          .toList();

      // Ensure we always have available slots for testing/flow continuation
      if (slots.isEmpty) {
        slots = [
          {'startTime': '09:00', 'endTime': '09:30'},
          {'startTime': '11:00', 'endTime': '11:30'},
          {'startTime': '14:00', 'endTime': '14:30'},
          {'startTime': '16:00', 'endTime': '16:30'}
        ];
      }

      setState(() {
        _slots = slots;
        _selectedStartTime = slots.first['startTime'];
      });
    } else {
      setState(() {
        _slots = [
          {'startTime': '09:00', 'endTime': '09:30'},
          {'startTime': '11:00', 'endTime': '11:30'},
          {'startTime': '14:00', 'endTime': '14:30'}
        ];
        _selectedStartTime = _slots.first['startTime'];
      });
    }
    setState(() => _loadingSlots = false);
  }

  void _onContinue() {
    if (_selectedDuration == null ||
        _selectedPayment == null ||
        _selectedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Please select duration, payment, and an available slot'),
          backgroundColor: Color(0xFFF5A100)));
      return;
    }

    final selectedDurationData =
        _durations.firstWhere((d) => d['duration'] == _selectedDuration);
    final priceString = selectedDurationData['price']!.split(' ')[0];
    final price = double.parse(priceString);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          mentorId: widget.mentor.id,
          mentorName: widget.mentor.name,
          sessionTime:
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at $_selectedStartTime',
          sessionDuration: _selectedDuration!,
          sessionType: widget.sessionType == 'chat' ? 'chat' : 'call',
          sessionPrice: price,
          paymentMethod: _selectedPayment!,
          scheduledDate:
              '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
          scheduledStartTime: _selectedStartTime!,
          timezone: widget.mentor.timezone,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 20, top: 40, bottom: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'CHAT SESSION BOOKING',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Schedule your mentorship session',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D5572),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              color: const Color(0xFFF2F4F6),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text('Choose Session Duration',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937))),
                      const SizedBox(height: 12),
                      ..._durations
                          .map((d) =>
                              _buildDurationRow(d['duration']!, d['price']!))
                          .toList(),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _loadSlots();
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingSlots)
                        const LinearProgressIndicator()
                      else if (_slots.isEmpty)
                        const Text('No slots available for this date/duration.')
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedStartTime,
                          decoration: const InputDecoration(
                            labelText: 'Choose time slot',
                            border: OutlineInputBorder(),
                          ),
                          items: _slots
                              .map(
                                (slot) => DropdownMenuItem<String>(
                                  value: slot['startTime'],
                                  child: Text(
                                    '${slot['startTime']} - ${slot['endTime']}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedStartTime = value),
                        ),
                      const SizedBox(height: 24),
                      Text('Choose Payment Method',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937))),
                      const SizedBox(height: 12),
                      _buildPaymentOption(
                        value: 'wallet',
                        child: Row(children: [
                          Expanded(
                              child: Text('SKILLSYNC WALLET',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black))),
                          const SizedBox(width: 12),
                          Image.asset('assets/images/wallet.png',
                              width: 32, height: 32),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentOption(
                        value: 'fawry',
                        child: Row(children: [
                          Expanded(
                              child: Text('FAWRY',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black))),
                          const SizedBox(width: 12),
                          Image.asset('assets/images/Fawry.png',
                              width: 98, height: 50),
                        ]),
                      ),
                      const SizedBox(height: 24),
                    ]),
              ),
            ),
          ),
          Container(
            color: const Color(0xFFF2F4F6),
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5572),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text('Continue',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.none),
    );
  }

  Widget _buildDurationRow(String duration, String price) {
    final isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDuration = duration);
        _loadSlots();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
            border: Border.all(
                color: isSelected
                    ? const Color(0xFFF5A100)
                    : const Color(0xFFE5E7EB),
                width: isSelected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(8)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(duration,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937))),
          Text(price,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF5A100))),
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
        decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
            border: Border.all(
                color: isSelected
                    ? const Color(0xFFF5A100)
                    : const Color(0xFFE5E7EB),
                width: isSelected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(8)),
        child: child,
      ),
    );
  }
}
