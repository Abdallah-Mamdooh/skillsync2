import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'assessment_flow.dart';

class ChosenRoadmapScreen extends StatefulWidget {
  const ChosenRoadmapScreen({super.key});

  @override
  State<ChosenRoadmapScreen> createState() => _ChosenRoadmapScreenState();
}

class _ChosenRoadmapScreenState extends State<ChosenRoadmapScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _steps = [];
  String _careerName = '';
  int _overallProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadChosenRoadmap();
  }

  String? get _token => context.read<AuthProvider>().token;

  Future<void> _loadChosenRoadmap() async {
    final token = _token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Login required.';
      });
      return;
    }

    try {
      final response = await ApiService.get('/roadmap/my-roadmap', token);
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};

        // Career name
        final careerRaw = data['career'] ?? data['chosenCareer'];
        String careerName = '';
        if (careerRaw is Map<String, dynamic>) {
          careerName = careerRaw['name']?.toString() ?? careerRaw['title']?.toString() ?? '';
        } else if (careerRaw is String) {
          careerName = careerRaw;
        }

        // Steps
        List<dynamic> steps = data['steps'] ?? data['topics'] ?? data['milestones'] ?? [];

        // Progress
        final progress = data['overallProgress'] ?? data['progress'] ?? 0;

        setState(() {
          _careerName = careerName;
          _steps = steps.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _overallProgress = (progress is double) ? progress.round() : (progress as int? ?? 0);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = response['message']?.toString() ?? 'No roadmap found.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  Color _stepColor(int percent) {
    if (percent >= 100) return const Color(0xFF1D5572);
    if (percent > 0) return const Color(0xFFF5A100);
    return const Color(0xFFE5E7EB);
  }

  IconData _stepIcon(int percent) {
    if (percent >= 100) return Icons.check_circle;
    if (percent > 0) return Icons.play_circle_fill;
    return Icons.lock;
  }

  Color _stepTextColor(int percent) {
    if (percent > 0) return const Color(0xFF1F2937);
    return const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D5572),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chosen Roadmap',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Your personalized path to reach your goals',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() { _isLoading = true; _error = null; });
                            _loadChosenRoadmap();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
                    : Column(
                  children: [
                    // Career name
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _careerName.isNotEmpty ? _careerName : 'Your Roadmap',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),

                    // Overall progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Overall Progress',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$_overallProgress%',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: _overallProgress / 100,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D5572)),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Steps list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                          final step = _steps[index];
                          final title = step['title']?.toString() ??
                              step['name']?.toString() ??
                              'Step ${index + 1}';
                          final links = step['links'] as List<dynamic>? ?? [];
                          final progressVal =
                              step['progress'] ?? step['completion'] ?? step['percent'] ?? 0;
                          final percent = progressVal is double
                              ? progressVal.round()
                              : (progressVal as int? ?? 0);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Color(0x1A000000), blurRadius: 4),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _stepIcon(percent),
                                      color: _stepColor(percent),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _stepTextColor(percent),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      percent >= 100
                                          ? Icons.check_box
                                          : percent > 0
                                          ? Icons.indeterminate_check_box
                                          : Icons.check_box_outline_blank,
                                      color: _stepColor(percent),
                                      size: 22,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Links:',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                if (links.isNotEmpty)
                                  ...links.map((link) => Padding(
                                    padding: const EdgeInsets.only(left: 8, top: 2),
                                    child: Text(
                                      '• ${link.toString()}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF1D5572),
                                      ),
                                    ),
                                  )),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
}

BottomNavigationBar _buildBottomNav(BuildContext context) {
  return BottomNavigationBar(
    backgroundColor: const Color(0xFF1D5572),
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    type: BottomNavigationBarType.fixed,
    currentIndex: 1,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
    onTap: (index) {
      if (index == 0) {
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
      } else if (index == 1) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentStartScreen()));
      } else if (index == 3) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assignment), label: 'assess'),
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}