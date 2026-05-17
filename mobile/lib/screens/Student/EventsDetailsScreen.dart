import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event_model.dart';
import '../../widgets/bottom_navigation.dart';
import 'Confirmregistrationdialog.dart';

class EventsDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventsDetailsScreen({super.key, required this.event});

  // ── Helpers to get display text with fallbacks ──────────────────────────
  String get _descriptionText {
    if (event.description != null && event.description!.isNotEmpty) {
      return event.description!;
    }
    return 'Join this ${event.type.toLowerCase()} on ${event.category} and gain valuable insights from industry experts. This event covers essential topics and practical skills to help you advance in your career.';
  }

  String get _targetAudienceText {
    if (event.targetAudience != null && event.targetAudience!.isNotEmpty) {
      return event.targetAudience!;
    }
    return 'Students and professionals interested in ${event.category} who want to expand their knowledge and network with like-minded individuals.';
  }

  List<String> get _agendaItems {
    if (event.agenda != null && event.agenda!.isNotEmpty) {
      return event.agenda!.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    return [
      'Introduction and welcome overview',
      'Core concepts and key principles',
      'Hands-on practice and exercises',
      'Real-world case studies and examples',
      'Interactive Q&A session',
    ];
  }

  List<String> get _learningOutcomeItems {
    if (event.learningOutcomes.isNotEmpty) {
      return event.learningOutcomes;
    }
    return [
      'Practical skills in ${event.category}',
      'Industry best practices and patterns',
      'How to apply concepts in real projects',
      'Networking with peers and mentors',
    ];
  }

  List<String> get _requirementItems {
    if (event.requirements != null && event.requirements!.isNotEmpty) {
      return event.requirements!.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    return [
      'Basic understanding of the field',
      'A laptop with internet access',
      'Enthusiasm to learn and participate',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(context),

            // ── Main Content ──
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Event Info Card ──
                      _buildInfoCard(),

                      const SizedBox(height: 12),

                      // ── About Section ──
                      _buildSection(
                        title: 'About This Event',
                        child: Text(
                          _descriptionText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Speaker / Mentor Section ──
                      _buildSpeakerSection(),

                      const SizedBox(height: 12),

                      // ── Target Audience ──
                      _buildSection(
                        title: 'Target Audience',
                        child: Text(
                          _targetAudienceText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Event Agenda ──
                      _buildSection(
                        title: 'Event Agenda',
                        child: _buildBulletList(_agendaItems),
                      ),

                      const SizedBox(height: 12),

                      // ── What You'll Learn ──
                      _buildSection(
                        title: "What You'll Learn",
                        child: _buildBulletList(_learningOutcomeItems),
                      ),

                      const SizedBox(height: 12),

                      // ── Requirements ──
                      _buildSection(
                        title: 'Requirements',
                        child: _buildBulletList(_requirementItems),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // ── Register Button ──
            _buildRegisterButton(context),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.none),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 8, right: 20, top: 25, bottom: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events Details',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'View all the information about this event',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Card ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E000000),
            spreadRadius: 0,
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ──
          _buildBanner(),

          // ── Details ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),

                // Type + Category chips
                Row(
                  children: [
                    _TypeChip(label: event.type),
                    const SizedBox(width: 8),
                    Text(
                      event.category,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 12),

                // Mentor + Price row
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      event.mentor,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF4B5563)),
                    ),
                    const SizedBox(width: 16),
                    Image.asset(
                      'assets/images/Money.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.price} EGP',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4B5563),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Date + Registered + Seats left row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      event.date,
                      style: GoogleFonts.inter(
                          fontSize: 8, color: const Color(0xFF4B5563)),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.people,
                        size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 8),
                        children: [
                          TextSpan(
                            text: '${event.registered}/${event.total}',
                            style: const TextStyle(color: Color(0xFF4B5563)),
                          ),
                          const TextSpan(
                            text: ' registered',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      event.isFull
                          ? '0 seats left'
                          : '${event.seatsLeft} seats left',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: event.isFull
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner ─────────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    final bool isResume = event.title.contains('Resume');

    return Stack(
      children: [
        Container(
          height: 130,
          width: double.infinity,
          color: event.bannerColor,
          child: isResume ? _resumeBannerContent() : _defaultBannerContent(),
        ),

        // FULL badge
        if (event.isFull)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'FULL',
                style: GoogleFonts.inter(
                  color: const Color(0xFFDC2626),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _defaultBannerContent() {
    return Row(
      children: [
        const SizedBox(width: 20),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sports_martial_arts,
              color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            event.title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _resumeBannerContent() {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _DotGridPainter()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resume',
                style: GoogleFonts.inter(
                  color: const Color(0xFFEF4444),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)
                  ],
                ),
              ),
              Text(
                'MASTER CLASS',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 10,
          bottom: 0,
          child: Icon(Icons.people,
              size: 70, color: const Color(0xFF1F2937).withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  // ── Speaker Section ────────────────────────────────────────────────────────
  Widget _buildSpeakerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E000000),
            spreadRadius: 0,
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speaker',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFE5E7EB),
                child: ClipOval(
                  child: Container(
                    color: const Color(0xFF1D5572).withValues(alpha: 0.3),
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Color(0xFF1D5572),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.mentor,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    event.category,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section Builder ────────────────────────────────────────────────────────
  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E000000),
            spreadRadius: 0,
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ── Bullet List ────────────────────────────────────────────────────────────
  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Register Button ────────────────────────────────────────────────────────
  Widget _buildRegisterButton(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      child: event.isFull
          ? OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8989),
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                disabledForegroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Event is full',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            )
          : ElevatedButton(
              onPressed: () => showConfirmRegistrationDialog(context, event),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5572),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: Text(
                'Register with wallet - ${event.price} EGP',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}

// ─── Type Chip ────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  const _TypeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }
}

// ─── Dot Grid Painter ─────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const spacing = 14.0;
    const radius = 2.0;

    for (double x = spacing; x < size.width * 0.55; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}
