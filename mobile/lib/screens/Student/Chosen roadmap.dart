import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

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

  const _Phase(
      {required this.title, required this.order, required this.steps});

  factory _Phase.fromJson(Map<String, dynamic> j) => _Phase(
    title: j['title']?.toString() ?? '',
    order: (j['order'] as num?)?.toInt() ?? 0,
    steps: (j['steps'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_Step.fromJson)
        .toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Load: generate resources first, then fetch roadmap ────────────────────
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
      // Step 1: trigger resource generation on the backend so steps have links.
      // This is safe to call every time — backend only updates empty steps.
      await ApiService.postWithAuth('/roadmap/generate-resources', {}, token);

      // Step 2: fetch the roadmap (steps now have resources populated)
      final response = await ApiService.get('/roadmap/my-roadmap', token);

      if (response['success'] != true) {
        setState(() {
          _isLoading = false;
          _error =
              response['message']?.toString() ?? 'Failed to load roadmap.';
        });
        return;
      }

      final data = response['data'] as Map<String, dynamic>? ?? {};

      // Career name
      final careerMap = data['career'] as Map<String, dynamic>? ?? {};
      final careerName = careerMap['name']?.toString() ?? '';

      // Overall completion
      final percent = (data['completionPercent'] as num?)?.toInt() ?? 0;

      // Flatten phases → steps
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

      // If any step still has no resources, build fallback search links locally
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

  /// Fallback: build YouTube / Coursera / Udemy search links if DB has none.
  List<_Resource> _buildFallbackResources(String skillTag, String title) {
    final keyword = Uri.encodeComponent(
        skillTag.isNotEmpty ? skillTag : title);
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
        url:
        'https://www.google.com/search?q=$keyword+documentation',
        type: 'documentation',
      ),
    ];
  }

  // ── Toggle step ────────────────────────────────────────────────────────────
  Future<void> _toggleStep(int index) async {
    final token = _token;
    if (token == null) return;

    final step = _flatSteps[index];

    // Optimistic update
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
        final serverPercent =
        (response['completionPercent'] as num?)?.toInt();
        if (serverPercent != null) {
          setState(() {
            _completionPercent = serverPercent;
          });
        }
      } else {
        // Revert
        setState(() {
          step.isCompleted = !step.isCompleted;
          _recalcPercent();
        });
      }
    } catch (_) {
      // Revert
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chosen Roadmap',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text('Your personalized path to reach your goals',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.white70)),
            ],
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
                  fontSize: 20,
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
                    fontSize: 14,
                    color: const Color(0xFF6B7280))),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Progress',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333))),
              Text('$_completionPercent%',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D5572))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _completionPercent / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFCDD3DA),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2A7F8F)),
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
      return Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2DBE6C),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF2DBE6C).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 30),
      );
    }
    if (status == _inProgress) {
      return Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF5A623),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFF5A623).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Center(
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 46, height: 46,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: Color(0xFFCDD3DA)),
      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _buildCheckbox() {
    if (status == _completed) {
      return Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
            color: const Color(0xFF2DBE6C),
            borderRadius: BorderRadius.circular(6)),
        child:
        const Icon(Icons.check_rounded, color: Colors.white, size: 18),
      );
    }
    if (status == _inProgress) {
      return Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
            color: const Color(0xFFF5A623),
            borderRadius: BorderRadius.circular(6)),
        child: Center(
          child: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5)),
          ),
        ),
      );
    }
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCDD3DA), width: 1.5),
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
      case 'video':         return Icons.play_circle_outline_rounded;
      case 'documentation': return Icons.menu_book_rounded;
      case 'course':        return Icons.school_rounded;
      default:              return Icons.link_rounded;
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
            width: 60,
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
                    child: Container(
                        width: 2, color: const Color(0xFFCDD3DA)),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Right: card ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card row
                  GestureDetector(
                    onTap: status != _locked ? onTap : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _cardBg,
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(step.title,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _titleColor)),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: status != _locked ? onTap : null,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                      scale: animation, child: child),
                              child: KeyedSubtree(
                                  key: ValueKey(status),
                                  child: _buildCheckbox()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Links label
                  Text('Links:',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _linksLabelColor)),

                  const SizedBox(height: 4),

                  // Resource links
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
        ],
      ),
    );
  }
}