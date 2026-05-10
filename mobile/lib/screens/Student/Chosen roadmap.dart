import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';

class _Resource {
  final String title;
  final String url;
  final String type;

  const _Resource({required this.title, required this.url, required this.type});

  factory _Resource.fromJson(Map<String, dynamic> j) => _Resource(
        title: j['title']?.toString() ?? '',
        url: j['url']?.toString() ?? '',
        type: j['type']?.toString() ?? 'course',
      );
}

class _Step {
  final String id;
  final String title;
  final String skillTag;
  final int order;
  List<_Resource> resources;
  bool isCompleted;

  _Step({
    required this.id,
    required this.title,
    required this.skillTag,
    required this.order,
    required this.resources,
    required this.isCompleted,
  });

  factory _Step.fromJson(Map<String, dynamic> j) => _Step(
        id: j['_id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        skillTag: j['skillTag']?.toString() ?? '',
        order: (j['order'] as num?)?.toInt() ?? 0,
        isCompleted: j['isCompleted'] == true,
        resources: (j['resources'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(_Resource.fromJson)
            .toList(),
      );
}

class _Phase {
  final String title;
  final int order;
  final List<_Step> steps;

  const _Phase({required this.title, required this.order, required this.steps});

  factory _Phase.fromJson(Map<String, dynamic> j) => _Phase(
        title: j['title']?.toString() ?? '',
        order: (j['order'] as num?)?.toInt() ?? 0,
        steps: (j['steps'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(_Step.fromJson)
            .toList(),
      );
}

class ChosenRoadmapScreen extends StatefulWidget {
  const ChosenRoadmapScreen({super.key});

  @override
  State<ChosenRoadmapScreen> createState() => _ChosenRoadmapScreenState();
}

class _ChosenRoadmapScreenState extends State<ChosenRoadmapScreen> {
  bool _isLoading = true;
  String? _error;

  String _careerName = '';
  List<_Step> _flatSteps = [];
  int _completionPercent = 0;

  static const int _locked = 0;
  static const int _inProgress = 1;
  static const int _completed = 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _token => context.read<AuthProvider>().token;

  Future<void> _load() async {
    final token = _token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Login required.';
      });
      return;
    }

    try {
      await ApiService.postWithAuth('/roadmap/generate-resources', {}, token);

      final response = await ApiService.get('/roadmap/my-roadmap', token);

      if (response['success'] != true) {
        setState(() {
          _isLoading = false;
          _error = response['message']?.toString() ?? 'Failed to load roadmap.';
        });
        return;
      }

      final data = response['data'] as Map<String, dynamic>? ?? {};

      final careerMap = data['career'] as Map<String, dynamic>? ?? {};
      final careerName = careerMap['name']?.toString() ?? '';

      final percent = (data['completionPercent'] as num?)?.toInt() ?? 0;

      final roadmapMap = data['roadmap'] as Map<String, dynamic>? ?? {};
      final rawPhases = roadmapMap['phases'] as List<dynamic>? ?? [];

      final phases = rawPhases
          .whereType<Map<String, dynamic>>()
          .map(_Phase.fromJson)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      final flatSteps = <_Step>[];
      for (final phase in phases) {
        final sorted = [...phase.steps]
          ..sort((a, b) => a.order.compareTo(b.order));
        flatSteps.addAll(sorted);
      }

      for (final step in flatSteps) {
        if (step.resources.isEmpty) {
          step.resources = _buildFallbackResources(step.skillTag, step.title);
        }
      }

      setState(() {
        _careerName = careerName;
        _completionPercent = percent;
        _flatSteps = flatSteps;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  List<_Resource> _buildFallbackResources(String skillTag, String title) {
    final keyword = Uri.encodeComponent(skillTag.isNotEmpty ? skillTag : title);
    return [
      _Resource(
        title: 'YouTube: $skillTag',
        url: 'https://www.youtube.com/results?search_query=$keyword',
        type: 'video',
      ),
      _Resource(
        title: 'Coursera: $skillTag',
        url: 'https://www.coursera.org/search?query=$keyword',
        type: 'course',
      ),
      _Resource(
        title: 'Udemy: $skillTag',
        url: 'https://www.udemy.com/courses/search/?q=$keyword',
        type: 'course',
      ),
      _Resource(
        title: 'Documentation: $skillTag',
        url: 'https://www.google.com/search?q=$keyword+documentation',
        type: 'documentation',
      ),
    ];
  }

  Future<void> _toggleStep(int index) async {
    final token = _token;
    if (token == null) return;

    final step = _flatSteps[index];

    setState(() {
      step.isCompleted = !step.isCompleted;
      _recalcPercent();
    });

    try {
      final response = await ApiService.postWithAuth(
        '/roadmap/toggle-step',
        {'stepId': step.id},
        token,
      );

      if (response['success'] == true) {
        final serverPercent = (response['completionPercent'] as num?)?.toInt();
        if (serverPercent != null) {
          setState(() {
            _completionPercent = serverPercent;
          });
        }
      } else {
        setState(() {
          step.isCompleted = !step.isCompleted;
          _recalcPercent();
        });
      }
    } catch (_) {
      setState(() {
        step.isCompleted = !step.isCompleted;
        _recalcPercent();
      });
    }
  }

  void _recalcPercent() {
    if (_flatSteps.isEmpty) {
      _completionPercent = 0;
      return;
    }
    final done = _flatSteps.where((s) => s.isCompleted).length;
    _completionPercent = ((done / _flatSteps.length) * 100).round();
  }

  int _statusOf(int index) {
    if (_flatSteps[index].isCompleted) return _completed;
    for (int i = 0; i < index; i++) {
      if (!_flatSteps[i].isCompleted) return _locked;
    }
    return _inProgress;
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      // Try in-app browser first (Chrome Custom Tab on Android, SFSafariViewController on iOS)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );

      if (!launched && mounted) {
        // Fallback to platform default
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Last resort fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
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
                color: const Color(0xFFF2F4F6),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildError()
                        : _buildBody(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.assess),
    );
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
              'Chosen Roadmap',
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
              'Your personalized path to reach your goals',
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

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Center(
            child: Text(
              _careerName.isNotEmpty ? _careerName : 'Your Roadmap',
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildProgressCard(),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _flatSteps.isEmpty
              ? Center(
                  child: Text('No steps found.',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: const Color(0xFF6B7280))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: _flatSteps.length,
                  itemBuilder: (context, index) {
                    final step = _flatSteps[index];
                    final status = _statusOf(index);
                    final isLast = index == _flatSteps.length - 1;
                    return _TimelineItem(
                      step: step,
                      status: status,
                      isLast: isLast,
                      onTap: () => _toggleStep(index),
                      onLinkTap: _launchUrl,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 22, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Progress',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1D5572))),
              Text('$_completionPercent%',
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF001636))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _completionPercent / 100,
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF2A7F8F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Color(0xFFF5A623)),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF6B7280))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _load();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D5572)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline Item
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final _Step step;
  final int status;
  final bool isLast;
  final VoidCallback onTap;
  final void Function(String url) onLinkTap;

  static const int _locked = 0;
  static const int _inProgress = 1;
  static const int _completed = 2;

  const _TimelineItem({
    required this.step,
    required this.status,
    required this.isLast,
    required this.onTap,
    required this.onLinkTap,
  });

  Widget _buildCircle() {
    if (status == _completed) {
      return SizedBox(
        width: 60,
        height: 60,
        child: CustomPaint(
          painter: _CompletedCirclePainter(),
        ),
      );
    }
    if (status == _inProgress) {
      return SizedBox(
        width: 60,
        height: 60,
        child: _LoadingCirclePainter(),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD9D9D9)),
      child: Center(
        child: Image.asset(
          'assets/images/lock-outline.png',
          width: 20,
          height: 20,
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    if (status == _completed) {
      return SizedBox(
        width: 42,
        height: 42,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _CompletedCheckboxPainter(),
            size: const Size(42, 42),
          ),
        ),
      );
    }
    if (status == _inProgress) {
      return SizedBox(
        width: 42,
        height: 42,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _InProgressCheckboxPainter(),
            size: const Size(42, 42),
          ),
        ),
      );
    }
    // Locked state checkbox - D9D9D9 background with solid white square
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9), // Same color as background
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Color(0xFF575757), // Black border
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  Color get _cardBg =>
      status == _locked ? const Color(0xFFE8ECF0) : Colors.white;
  Color get _titleColor =>
      status == _locked ? const Color(0xFFAAAAAA) : const Color(0xFF1A1A2E);
  Color get _linksLabelColor =>
      status == _locked ? const Color(0xFFBBBBBB) : const Color(0xFF6B7280);

  IconData _resourceIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'documentation':
        return Icons.menu_book_rounded;
      case 'course':
        return Icons.school_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: circle + line ─────────────────────────────────────────
          SizedBox(
            width: 56,
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: KeyedSubtree(
                      key: ValueKey(status), child: _buildCircle()),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFF1D5572)),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Middle: card + links ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: status == _locked
                          ? []
                          : [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                    ),
                    child: Container(
                      width: double.infinity,
                      child: Text(
                        step.title,
                        textAlign: TextAlign.left,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Links:',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _linksLabelColor)),
                  const SizedBox(height: 4),
                  ...step.resources.map(
                    (r) => GestureDetector(
                      onTap: r.url.isNotEmpty ? () => onLinkTap(r.url) : null,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 4, top: 4, bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                _resourceIcon(r.type),
                                size: 14,
                                color: status == _locked
                                    ? const Color(0xFFBBBBBB)
                                    : const Color(0xFF1D5572),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                r.title,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: status == _locked
                                      ? const Color(0xFFBBBBBB)
                                      : const Color(0xFF1D5572),
                                  decoration: status != _locked
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Right: checkbox outside card ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: status != _locked ? onTap : null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: KeyedSubtree(
                    key: ValueKey(status), child: _buildCheckbox()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter for loading circle (timeline left side)
// Yellow background with white rotating arc (no shadow)
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingCirclePainter extends StatefulWidget {
  @override
  __LoadingCirclePainterState createState() => __LoadingCirclePainterState();
}

class __LoadingCirclePainterState extends State<_LoadingCirclePainter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LoadingCirclePainterWidget(_controller.value),
        );
      },
    );
  }
}

class _LoadingCirclePainterWidget extends CustomPainter {
  final double progress;

  _LoadingCirclePainterWidget(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Yellow background circle
    final bgPaint = Paint()
      ..color = const Color(0xFFF5A623)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // White rotating arc (no shadow)
    final whiteArcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Arc length - 120 degrees (shorter arc)
    const double sweepAngle = 2.0944; // 120 degrees in radians
    final double startAngle = progress * 3.14159 * 2;

    // Draw white arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.68),
      startAngle,
      sweepAngle,
      false,
      whiteArcPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter for in-progress checkbox (right side)
// Yellow background with white square that has the same L-shaped gap as the completed checkbox
// ─────────────────────────────────────────────────────────────────────────────

class _InProgressCheckboxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cornerRadius = 10.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    // Yellow rounded-square background
    final bgPaint = Paint()..color = const Color(0xFFF5A623);
    canvas.drawRRect(rrect, bgPaint);

    // White inner rounded-square outline with the same L-shaped gap as the completed checkbox
    final squarePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Inner square bounds (inset from the outer edges) - same as completed checkbox
    final double inset = size.width * 0.28;
    final double cr = 3.0; // inner corner radius
    final double l = inset;
    final double t = inset;
    final double r = size.width - inset;
    final double b = size.height - inset;

    // Gap boundaries - same as completed checkbox
    final double gapTopStart = l + (r - l) * 0.50;
    final double gapRightEnd = t + (b - t) * 0.50;

    // Draw the square with the L-shaped gap (no checkmark)
    final squarePath = Path();

    squarePath.moveTo(r, gapRightEnd); // resume on right edge (below gap)
    squarePath.lineTo(r, b - cr); // right edge to bottom-right corner
    squarePath.quadraticBezierTo(r, b, r - cr, b);
    squarePath.lineTo(l + cr, b); // bottom edge
    squarePath.quadraticBezierTo(l, b, l, b - cr);
    squarePath.lineTo(l, t + cr); // left edge
    squarePath.quadraticBezierTo(l, t, l + cr, t);
    squarePath.lineTo(gapTopStart, t); // top edge up to gap start

    canvas.drawPath(squarePath, squarePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter for completed circle (timeline left side)
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Green background circle
    final bgPaint = Paint()..color = const Color(0xFF1FAD6A);
    canvas.drawCircle(center, radius, bgPaint);

    // White arc with gap at top-right where checkmark tail exits
    final arcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double gapDegrees = 50.0;
    const double startDeg = 335.0;
    const double sweepDeg = 360.0 - gapDegrees;
    const double toRad = 3.14159265 / 180.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.58),
      startDeg * toRad,
      sweepDeg * toRad,
      false,
      arcPaint,
    );

    // White checkmark poking through the gap
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.36, size.height * 0.50);
    path.lineTo(size.width * 0.46, size.height * 0.60);
    path.lineTo(size.width * 0.74, size.height * 0.20);

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter for completed checkbox (right side) — rounded-square version
// Green bg + white inner rounded-square with gap spanning the top-right corner
// AND the upper half of the right edge + checkmark poking through the gap
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedCheckboxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cornerRadius = 10.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    // Green rounded-square background
    final bgPaint = Paint()..color = const Color(0xFF1FAD6A);
    canvas.drawRRect(rrect, bgPaint);

    // White inner rounded-square outline with a gap that spans:
    //   • the top-right corner (from ~50% of the top edge)
    //   • the upper half of the right edge (down to ~50% of the right edge)
    // This creates an L-shaped opening at the top-right where the checkmark tail exits.
    final squarePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Inner square bounds (inset from the outer edges)
    final double inset = size.width * 0.28;
    final double cr = 3.0; // inner corner radius
    final double l = inset;
    final double t = inset;
    final double r = size.width - inset;
    final double b = size.height - inset;

    // Gap boundaries:
    //   gapTopStart  — gap opens at this x on the top edge (~50% across)
    //   gapRightEnd  — gap closes at this y on the right edge (~50% down)
    final double gapTopStart = l + (r - l) * 0.50;
    final double gapRightEnd = t + (b - t) * 0.50;

    // Draw the remaining three-sided path (clockwise), skipping the
    // top-right corner and upper-right edge:
    //
    //   resume at gapRightEnd on right edge
    //   → bottom-right corner
    //   → bottom edge
    //   → bottom-left corner
    //   → left edge
    //   → top-left corner
    //   → top edge up to gapTopStart
    //   (gap here — top-right corner + upper right edge omitted)
    final squarePath = Path();

    squarePath.moveTo(r, gapRightEnd); // resume on right edge (below gap)
    squarePath.lineTo(r, b - cr); // right edge to bottom-right corner
    squarePath.quadraticBezierTo(r, b, r - cr, b);
    squarePath.lineTo(l + cr, b); // bottom edge
    squarePath.quadraticBezierTo(l, b, l, b - cr);
    squarePath.lineTo(l, t + cr); // left edge
    squarePath.quadraticBezierTo(l, t, l + cr, t);
    squarePath.lineTo(gapTopStart, t); // top edge up to gap start

    canvas.drawPath(squarePath, squarePaint);

    // White checkmark whose tail pokes out through the top-right gap
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path();
    checkPath.moveTo(size.width * 0.40, size.height * 0.50);
    checkPath.lineTo(size.width * 0.44, size.height * 0.64);
    checkPath.lineTo(size.width * 0.73, size.height * 0.20);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
