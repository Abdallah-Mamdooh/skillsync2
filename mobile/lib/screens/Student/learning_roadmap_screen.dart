import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';

// ===== DATA MODELS =====

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

// ===== LEARNING ROADMAP SCREEN =====

class LearningRoadmapScreen extends StatefulWidget {
  final String? careerName;
  final bool fromAssessment;

  const LearningRoadmapScreen({
    super.key,
    this.careerName,
    this.fromAssessment = false,
  });

  @override
  State<LearningRoadmapScreen> createState() => _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends State<LearningRoadmapScreen> {
  // ── Road geometry ──────────────────────────────────────────────────────────
  static const double _roadLeft = 31;
  static const double _roadTop = 226;
  static const double _roadWidth = 331;
  static const double _roadHeight = 800;
  static const double _sw = _roadWidth * 0.07;
  static const double _roadLx = _roadLeft + _sw * 0.5;
  static const double _roadRx = _roadLeft + _roadWidth - _sw * 0.5;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  String _careerName = '';
  List<_Step> _flatSteps = [];
  int _completionPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  String? _token() {
    try {
      return context.read<AuthProvider>().token;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRoadmap() async {
    final token = _token();
    if (token == null || token.isEmpty) {
      _useDummySteps();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ApiService.postWithAuth('/roadmap/generate-resources', {}, token);
      final response = await ApiService.get('/roadmap/my-roadmap', token);

      if (response['success'] != true) {
        _useDummySteps();
        return;
      }

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final careerMap = data['career'] as Map<String, dynamic>? ?? {};
      final careerName =
          careerMap['name']?.toString() ?? widget.careerName ?? '';
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
    } catch (_) {
      _useDummySteps();
    }
  }

  List<_Resource> _buildFallbackResources(String skillTag, String title) {
    final keyword = Uri.encodeComponent(skillTag.isNotEmpty ? skillTag : title);
    return [
      _Resource(
          title: 'YouTube: $skillTag',
          url: 'https://www.youtube.com/results?search_query=$keyword',
          type: 'video'),
      _Resource(
          title: 'Coursera: $skillTag',
          url: 'https://www.coursera.org/search?query=$keyword',
          type: 'course'),
      _Resource(
          title: 'Udemy: $skillTag',
          url: 'https://www.udemy.com/courses/search/?q=$keyword',
          type: 'course'),
      _Resource(
          title: 'Docs: $skillTag',
          url: 'https://www.google.com/search?q=$keyword+documentation',
          type: 'documentation'),
    ];
  }

  void _useDummySteps() {
    setState(() {
      _careerName = widget.careerName ?? 'Full Stack Developer';
      _flatSteps = [
        _Step(
            id: '1',
            title: 'HTML & CSS Fundamentals',
            skillTag: 'html',
            order: 1,
            resources: [],
            isCompleted: true),
        _Step(
            id: '2',
            title: 'JavaScript Essentials',
            skillTag: 'javascript',
            order: 2,
            resources: [],
            isCompleted: false),
        _Step(
            id: '3',
            title: 'React Framework',
            skillTag: 'react',
            order: 3,
            resources: [],
            isCompleted: false),
        _Step(
            id: '4',
            title: 'Backend with Node.js',
            skillTag: 'nodejs',
            order: 4,
            resources: [],
            isCompleted: false),
        _Step(
            id: '5',
            title: 'Full Stack Project',
            skillTag: 'fullstack',
            order: 5,
            resources: [],
            isCompleted: false),
        _Step(
            id: '6',
            title: 'Database Design',
            skillTag: 'database',
            order: 6,
            resources: [],
            isCompleted: false),
        _Step(
            id: '7',
            title: 'API Development',
            skillTag: 'api',
            order: 7,
            resources: [],
            isCompleted: false),
        _Step(
            id: '8',
            title: 'Testing & Debugging',
            skillTag: 'testing',
            order: 8,
            resources: [],
            isCompleted: false),
        _Step(
            id: '9',
            title: 'Deployment',
            skillTag: 'devops',
            order: 9,
            resources: [],
            isCompleted: false),
        _Step(
            id: '10',
            title: 'Interview Preparation',
            skillTag: 'interview',
            order: 10,
            resources: [],
            isCompleted: false),
      ];
      _completionPercent = 10;
      _isLoading = false;
      _error = null;
    });
  }

  Future<void> _toggleStep(int index) async {
    final token = _token();
    if (token == null) return;
    final step = _flatSteps[index];
    setState(() {
      step.isCompleted = !step.isCompleted;
      _recalcPercent();
    });
    try {
      final res = await ApiService.postWithAuth(
          '/roadmap/toggle-step', {'stepId': step.id}, token);
      if (res['success'] == true) {
        final sp = (res['completionPercent'] as num?)?.toInt();
        if (sp != null) setState(() => _completionPercent = sp);
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
    _completionPercent =
        ((_flatSteps.where((s) => s.isCompleted).length / _flatSteps.length) *
                100)
            .round();
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: const Color(0xFF6B7280))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _loadRoadmap, child: const Text('Retry')),
                ]))
              : SingleChildScrollView(
                  child: FittedBox(
                    alignment: Alignment.topCenter,
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 393,
                      height: 1120,
                      child: Stack(
                        children: [
                          // ── Serpentine road ──────────────────────────────
                          Positioned(
                            left: _roadLeft,
                            top: _roadTop,
                            child: SizedBox(
                              width: _roadWidth,
                              height: _roadHeight,
                              child:
                                  CustomPaint(painter: SerpentineRoadPainter()),
                            ),
                          ),

                          // ── Header ───────────────────────────────────────
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Container(
                              width: 393,
                              height: 132,
                              padding: const EdgeInsets.only(
                                  left: 16, right: 20, top: 45, bottom: 15),
                              color: const Color(0xFF1D5572),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      'Learning Roadmap',
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
                                      'Your personalized path to success',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Career title ─────────────────────────────────
                          Positioned(
                            left: 0,
                            top: 142,
                            child: SizedBox(
                              width: 393,
                              child: Text(
                                _careerName.isNotEmpty
                                    ? _careerName
                                    : 'Your Roadmap',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF1F2937),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1),
                              ),
                            ),
                          ),

                          // ── START node ───────────────────────────────────
                          _buildTerminalNode(
                              left: 20, top: 205, label: 'START'),

                          // ── Steps ────────────────────────────────────────
                          ..._buildStepWidgets(),

                          // ── END node ─────────────────────────────────────
                          _buildTerminalNode(left: 20, top: 1005, label: 'END'),

                          // ── Buttons ──────────────────────────────────────
                          Positioned(
                            left: 26,
                            top: 1060,
                            child: GestureDetector(
                              onTap: widget.fromAssessment
                                  ? () {
                                      Navigator.popUntil(
                                          context, (r) => r.isFirst);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Roadmap selected! Start your learning journey.')));
                                    }
                                  : null,
                              child: Container(
                                width: 169,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF1D5572),
                                    borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: Text(
                                    widget.fromAssessment
                                        ? 'Choose This Roadmap'
                                        : 'Continue Learning',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 199,
                            top: 1060,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 169,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFD9D9D9),
                                    borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: Text('Cancel',
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFF1D5572),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.assess),
    );
  }

  // ── Terminal node (START / END) ─────────────────────────────────────────────
  Widget _buildTerminalNode({
    required double left,
    required double top,
    required String label,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 41,
        height: 41,
        decoration: BoxDecoration(
            color: const Color(0xFFF5A100),
            borderRadius: BorderRadius.circular(21)),
        child: Stack(children: [
          Positioned(
              left: 5,
              top: 5,
              child: Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFCFCFC),
                      borderRadius: BorderRadius.circular(16)))),
          Positioned(
              left: 9,
              top: 9,
              child: Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5A100),
                      borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFFCFCFC),
                          fontSize: 6,
                          fontWeight: FontWeight.bold)))),
        ]),
      ),
    );
  }

  // ── Pin / colour layout tables ───────────────────────────────────────────────
  static const List<bool> _onOrange = [
    true, // 1
    false, // 2
    false, // 3
    true, // 4
    true, // 5
    false, // 6
    false, // 7
    true, // 8
    true, // 9
    false, // 10
  ];

  static const List<bool> _onLeft = [
    true, // 1
    false, // 2
    true, // 3
    false, // 4
    true, // 5
    false, // 6
    true, // 7
    false, // 8
    true, // 9
    false, // 10
  ];

  static const double _pinW = 32.0;
  static const double _pinH = _pinW * 1.6;

  List<Widget> _buildStepWidgets() {
    final widgets = <Widget>[];
    const int totalRows = 10;
    const double labelW = 200;
    const double labelH = 36;
    const double aboveGap = 6;

    for (int i = 0; i < _flatSteps.length && i < totalRows; i++) {
      final step = _flatSteps[i];
      final displayNum = i + 1;
      final onOrange = _onOrange[i];
      final onLeft = _onLeft[i];

      final double rowCY = _roadTop + _roadHeight * i / (totalRows - 1);

      // ── Pin ──────────────────────────────────────────────────────────────
      final double pinTop = rowCY - _sw / 2 - _pinH;
      final double pinLeft =
          onLeft ? _roadLx - _pinW / 2 + 20 : _roadRx - _pinW / 2;

      widgets.add(Positioned(
        left: pinLeft,
        top: pinTop,
        child: GestureDetector(
          onTap: () => _toggleStep(i),
          child: _PinImage(
            number: displayNum,
            useYellow: !onOrange,
            size: _pinW,
            completed: step.isCompleted,
          ),
        ),
      ));

      // ── Label above road strip ───────────────────────────────────────────
      final double labelTop = rowCY - _sw / 2 - aboveGap - labelH;

      widgets.add(Positioned(
        left: _roadLeft + _roadWidth / 2 - labelW / 2,
        top: labelTop,
        child: SizedBox(
          width: labelW,
          height: labelH,
          child: Align(
            alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Text(
              step.title,
              maxLines: 2,
              textAlign: onLeft ? TextAlign.left : TextAlign.right,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ));
    }

    return widgets;
  }
}

// ── Pin image widget ─────────────────────────────────────────────────────────
class _PinImage extends StatelessWidget {
  final int number;
  final bool useYellow;
  final double size;
  final bool completed;

  const _PinImage({
    required this.number,
    required this.useYellow,
    this.size = 32,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    final double h = size * 1.6;
    final String asset = completed
        ? 'assets/images/Bluepin.png'
        : (useYellow
            ? 'assets/images/Yellowpin.png'
            : 'assets/images/Bluepin.png');

    return SizedBox(
      width: size,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(asset, fit: BoxFit.fill)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size,
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    number.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 2)
                      ],
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERPENTINE ROAD PAINTER — 10 rows, road reaches END node
// ─────────────────────────────────────────────────────────────────────────────
class SerpentineRoadPainter extends CustomPainter {
  static const Color kOrange = Color(0xFFF5A100);
  static const Color kTeal = Color(0xFF1D5572);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double sw = w * 0.07;

    final double lx = sw * 0.5;
    final double rx = w - sw * 0.5;
    final double mid = w / 2;

    const int rows = 10;
    final List<double> ys = List.generate(rows, (i) => h * i / (rows - 1));
    final double arcR = h / (rows - 1) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rowDefs = <_RowDef>[
      _RowDef(lc: kOrange, rc: kTeal, arcColor: kTeal, arcRight: true), // 0→1
      _RowDef(
          lc: kOrange, rc: kTeal, arcColor: kOrange, arcRight: false), // 1→2
      _RowDef(lc: kTeal, rc: kOrange, arcColor: kTeal, arcRight: true), // 2→3
      _RowDef(
          lc: kTeal, rc: kOrange, arcColor: kOrange, arcRight: false), // 3→4
      _RowDef(lc: kOrange, rc: kTeal, arcColor: kTeal, arcRight: true), // 4→5
      _RowDef(
          lc: kOrange, rc: kTeal, arcColor: kOrange, arcRight: false), // 5→6
      _RowDef(lc: kTeal, rc: kOrange, arcColor: kTeal, arcRight: true), // 6→7
      _RowDef(
          lc: kTeal, rc: kOrange, arcColor: kOrange, arcRight: false), // 7→8
      _RowDef(lc: kOrange, rc: kTeal, arcColor: kTeal, arcRight: true), // 8→9
      _RowDef(
          lc: kOrange, rc: kTeal, arcColor: null, arcRight: false), // 9 (end)
    ];

    for (int i = 0; i < rows; i++) {
      final def = rowDefs[i];
      final double y = ys[i];

      paint.color = def.lc;
      canvas.drawLine(Offset(lx, y), Offset(mid, y), paint);

      paint.color = def.rc;
      canvas.drawLine(Offset(mid, y), Offset(rx, y), paint);

      if (i < rows - 1 && def.arcColor != null) {
        final double nextY = ys[i + 1];
        final double cy = (y + nextY) / 2;
        paint.color = def.arcColor!;

        if (def.arcRight) {
          canvas.drawArc(Rect.fromCircle(center: Offset(rx, cy), radius: arcR),
              -pi / 2, pi, false, paint);
        } else {
          canvas.drawArc(Rect.fromCircle(center: Offset(lx, cy), radius: arcR),
              pi / 2, pi, false, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RowDef {
  final Color lc;
  final Color rc;
  final Color? arcColor;
  final bool arcRight;

  const _RowDef({
    required this.lc,
    required this.rc,
    required this.arcColor,
    required this.arcRight,
  });
}
