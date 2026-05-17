import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/event_model.dart';
import '../../services/group_event_service.dart';
import '../../widgets/bottom_navigation.dart';
import 'EventsDetailsScreen.dart';
import 'Confirmregistrationdialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Public Events',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      home: const PublicEventsScreen(),
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PublicEventsScreen extends StatefulWidget {
  const PublicEventsScreen({super.key});

  @override
  State<PublicEventsScreen> createState() => _PublicEventsScreenState();
}

class _PublicEventsScreenState extends State<PublicEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await GroupEventService.getPublicEvents();
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        if (mounted) {
          setState(() {
            _events = data
                .map((e) => EventModel.fromMap(e as Map<String, dynamic>))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                response['message']?.toString() ?? 'Failed to load events';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D5572),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(),

            // ── Main Content ──
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // ── Search Bar ──
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    // ── Event List ──
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF1D5572)),
                            )
                          : _errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_errorMessage!,
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFFEF4444),
                                              fontSize: 14),
                                          textAlign: TextAlign.center),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _fetchEvents,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1D5572),
                                        ),
                                        child: const Text('Retry',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                )
                              : _events.isEmpty
                                  ? Center(
                                      child: Text('No events available',
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFF9CA3AF),
                                              fontSize: 14)),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: _fetchEvents,
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 26, vertical: 8),
                                        itemCount: _events.length,
                                        itemBuilder: (ctx, i) =>
                                            EventCard(event: _events[i]),
                                      ),
                                    ),
                    ),
                  ],
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

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 20, top: 25, bottom: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Public Events',
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
              'Connect and chat with your mentors anytime',
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

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        children: [
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
                  hintText: 'Search events, mentors, topics...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/Filter.png',
                width: 18,
                height: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class EventCard extends StatelessWidget {
  final EventModel event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                          fontSize: 12, color: const Color(0xFF4B5563)),
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
                const SizedBox(height: 14),

                // Action buttons
                _buildButtons(context),
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
        // Dot grid background
        Positioned.fill(
          child: CustomPaint(painter: _DotGridPainter()),
        ),
        // Resume text
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
                    Shadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)
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
        // Illustration figures (right side)
        Positioned(
          right: 10,
          bottom: 0,
          child: Icon(Icons.people,
              size: 70, color: const Color(0xFF1F2937).withValues(alpha: 0.3)),
        ),
      ],
    );
  }

  // ── Buttons ────────────────────────────────────────────────────────────────
  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        // View Details
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventsDetailsScreen(event: event),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF1D5572),
              foregroundColor: const Color(0xFF1D5572),
              side: const BorderSide(color: Color(0xFF1D5572), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'View Details',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Register / Event is full
        Expanded(
          child: event.isFull
              ? OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8989),
                    foregroundColor: const Color(0xFFDC2626),
                    side:
                        const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    disabledForegroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Event is full',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                )
              : ElevatedButton(
                  onPressed: () =>
                      showConfirmRegistrationDialog(context, event),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    foregroundColor: const Color(0xFF1D5572),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Register',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
        ),
      ],
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
