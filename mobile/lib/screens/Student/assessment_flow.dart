import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/bottom_navigation.dart';
import 'learning_roadmap_screen.dart';

// ===== CAREER MODEL =====
class CareerScore {
  final String title;
  final String description;
  final List<String> skills;
  int score;
  CareerScore(
      {required this.title,
      required this.description,
      required this.skills,
      this.score = 0});
  int get matchPercent => (score * 5).clamp(0, 99);
}

List<CareerScore> calculateMatches(List<int> answers) {
  final careers = [
    CareerScore(
        title: 'Full Stack Developer',
        description:
            'Build end-to-end web applications using modern frameworks.',
        skills: ['JavaScript', 'React', 'Node.js', 'Database']),
    CareerScore(
        title: 'Data Analyst',
        description:
            'Transform data into actionable insights using statistical analysis.',
        skills: ['Python', 'SQL', 'Statistics', 'Tableau']),
    CareerScore(
        title: 'UX/UI Designer',
        description:
            'Design intuitive and beautiful user experiences for digital products.',
        skills: ['Figma', 'Prototyping', 'User Research', 'Design Systems']),
    CareerScore(
        title: 'Cloud Engineer',
        description:
            'Design and manage scalable cloud infrastructure and deployment pipelines.',
        skills: ['AWS', 'Docker', 'CI/CD', 'Linux']),
  ];
  final q1 = [
    [3, 0, 1, 0],
    [0, 0, 3, 0],
    [0, 2, 0, 3],
    [2, 0, 1, 0]
  ];
  final q2 = [
    [1, 2, 1, 2],
    [3, 1, 0, 1],
    [1, 2, 2, 2],
    [2, 2, 1, 1]
  ];
  final q3 = [
    [3, 0, 2, 0],
    [0, 0, 0, 3],
    [1, 0, 1, 0],
    [1, 3, 0, 1]
  ];
  final q4 = [
    [1, 1, 2, 3],
    [0, 3, 2, 1],
    [3, 1, 1, 1],
    [0, 1, 3, 2]
  ];
  final q5 = [
    [2, 1, 3, 2],
    [1, 2, 2, 2],
    [2, 1, 2, 2],
    [1, 3, 2, 2]
  ];
  final matrices = [q1, q2, q3, q4, q5];

  for (int q = 0; q < answers.length; q++) {
    if (q >= matrices.length) break;
    final answerIndex = answers[q];
    if (answerIndex == -1) continue;
    for (int c = 0; c < careers.length; c++) {
      if (c < matrices[q].length && answerIndex < matrices[q][c].length) {
        careers[c].score += matrices[q][c][answerIndex];
      }
    }
  }

  careers.sort((a, b) => b.score.compareTo(a.score));
  return careers;
}

// ===== START SCREEN =====
class AssessmentStartScreen extends StatefulWidget {
  const AssessmentStartScreen({super.key});

  @override
  State<AssessmentStartScreen> createState() => _AssessmentStartScreenState();
}

class _AssessmentStartScreenState extends State<AssessmentStartScreen> {
  bool _isCheckingAssessment = true;
  bool _hasExistingAssessment = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAssessment();
  }

  Future<void> _checkExistingAssessment() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) {
        setState(() => _isCheckingAssessment = false);
        return;
      }
      final response = await ApiService.get('/assessment/result', token);
      setState(() {
        _hasExistingAssessment =
            response['success'] == true && response['data'] != null;
        _isCheckingAssessment = false;
      });
    } catch (_) {
      setState(() => _isCheckingAssessment = false);
    }
  }

  void _handleStartPressed(BuildContext context) {
    if (_hasExistingAssessment) {
      _showRetakeDialog(context);
    } else {
      _navigateToAssessment(context);
    }
  }

  void _showRetakeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => RetakeAssessmentDialog(
        onRetake: () {
          Navigator.of(context).pop();
          _navigateToAssessment(context);
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _navigateToAssessment(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AssessmentQuestion1(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  left: 16, right: 20, top: 40, bottom: 15),
              decoration: const BoxDecoration(
                color: Color(0xFF1D5572),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skill Assessment',
                    style: GoogleFonts.inter(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover Your Strengths',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Image.asset(
                      'assets/images/assessment_start_logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Let\u2019s Get Started!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F3955),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Color(0xFF1D5572)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BulletPoint(
                            text:
                                'Your answers directly influence your career recommendations.',
                          ),
                          SizedBox(height: 12),
                          _BulletPoint(
                            text:
                                'Please respond carefully and honestly to ensure accurate results.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final interests =
                            (auth.user?['selectedInterests'] as List?) ?? [];
                        final hasInterests = interests.isNotEmpty;

                        return Column(
                          children: [
                            if (!hasInterests)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFF59E0B)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        color: Color(0xFFB45309)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Tip: Set your Career Interests in Profile to get specialized technical questions!',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFFB45309),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isCheckingAssessment
                                    ? null
                                    : () => _handleStartPressed(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5A100),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: _isCheckingAssessment
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF001636),
                                        ),
                                      )
                                    : Text(
                                        _hasExistingAssessment
                                            ? 'Retake Assessment'
                                            : 'Start Assessment',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF001636),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.assess),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6.0, right: 10),
          child: Icon(Icons.circle, size: 6, color: Color(0xFF1D5572)),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ===== ASSESSMENT FLOW SCREEN =====
class AssessmentQuestion1 extends StatefulWidget {
  const AssessmentQuestion1({super.key});

  @override
  State<AssessmentQuestion1> createState() => _AssessmentQuestion1State();
}

class _AssessmentQuestion1State extends State<AssessmentQuestion1> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<int> _answers = [];
  List<Map<String, dynamic>> _questions = [];
  bool _isLoadingQuestions = true;
  bool _isSubmitting = false;
  String? _loadError;
  bool _isOverwriteAttempt = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  String? _getToken() {
    try {
      return context.read<AuthProvider>().token;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadQuestions() async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoadingQuestions = false;
        _loadError = 'You need to login before taking the assessment.';
      });
      return;
    }

    setState(() {
      _isLoadingQuestions = true;
      _loadError = null;
    });

    final sectionsResponse =
        await ApiService.get('/assessment/sections', token);
    if (sectionsResponse['success'] != true) {
      setState(() {
        _isLoadingQuestions = false;
        _loadError = sectionsResponse['message'] ??
            'Failed to load assessment sections.';
      });
      return;
    }

    final dynamic sectionsData = sectionsResponse['data'];
    final List<dynamic> sections = sectionsData is List
        ? sectionsData
        : (sectionsData is Map<String, dynamic> &&
                sectionsData['sections'] is List
            ? sectionsData['sections'] as List<dynamic>
            : <dynamic>[]);

    if (sections.isEmpty) {
      setState(() {
        _isLoadingQuestions = false;
        _loadError = 'No assessment sections available.';
      });
      return;
    }

    final List<dynamic> allQuestionsRaw = [];
    for (final section in sections) {
      final sectionMap = section as Map<String, dynamic>;
      final sectionId = sectionMap['_id']?.toString();
      if (sectionId == null || sectionId.isEmpty) continue;

      final questionsResponse =
          await ApiService.get('/assessment/questions/$sectionId', token);
      if (questionsResponse['success'] != true) {
        setState(() {
          _isLoadingQuestions = false;
          _loadError =
              questionsResponse['message'] ?? 'Failed to load questions.';
        });
        return;
      }

      final dynamic questionsData = questionsResponse['data'];
      final List<dynamic> sectionQuestions = questionsData is List
          ? questionsData
          : (questionsData is Map<String, dynamic> &&
                  questionsData['questions'] is List
              ? questionsData['questions'] as List<dynamic>
              : <dynamic>[]);

      allQuestionsRaw.addAll(sectionQuestions);
    }

    if (allQuestionsRaw.isEmpty) {
      setState(() {
        _isLoadingQuestions = false;
        _loadError = 'No assessment questions found.';
      });
      return;
    }

    String extractOptionTitle(Map<String, dynamic> opt) {
      final preferred = [
        opt['text'],
        opt['title'],
        opt['optionText'],
        opt['label'],
        opt['name'],
        opt['value']
      ];
      for (final v in preferred) {
        final s = (v ?? '').toString().trim();
        if (s.isNotEmpty) return s;
      }
      for (final entry in opt.entries) {
        final s = (entry.value ?? '').toString().trim();
        if (s.isNotEmpty && s != '{}' && s != '[]') return s;
      }
      return '';
    }

    List<Map<String, dynamic>> parseOptions(dynamic optionsDynamic) {
      final parsed = <Map<String, dynamic>>[];
      if (optionsDynamic is List) {
        for (final opt in optionsDynamic) {
          if (opt is String) {
            final title = opt.trim();
            if (title.isNotEmpty) {
              parsed.add({'title': title, 'tags': <String>[]});
            }
            continue;
          }
          if (opt is Map<String, dynamic>) {
            final title = extractOptionTitle(opt);
            if (title.isNotEmpty) {
              parsed.add({'title': title, 'tags': <String>[]});
            }
          }
        }
      } else if (optionsDynamic is Map<String, dynamic>) {
        for (final entry in optionsDynamic.entries) {
          if (entry.value is String) {
            final title = (entry.value as String).trim();
            if (title.isNotEmpty) {
              parsed.add({'title': title, 'tags': <String>[]});
            }
          } else if (entry.value is Map<String, dynamic>) {
            final title =
                extractOptionTitle(entry.value as Map<String, dynamic>);
            if (title.isNotEmpty) {
              parsed.add({'title': title, 'tags': <String>[]});
            }
          }
        }
      }
      return parsed;
    }

    final List<Map<String, dynamic>> parsedQuestions = [];
    for (var i = 0; i < allQuestionsRaw.length; i++) {
      final raw = allQuestionsRaw[i];
      if (raw is! Map<String, dynamic>) continue;

      dynamic optionsDynamic = raw['options'];
      final optionsEmpty = optionsDynamic is List && optionsDynamic.isEmpty;
      if (optionsDynamic == null || optionsEmpty) {
        optionsDynamic = raw['answers'] ??
            raw['choices'] ??
            raw['items'] ??
            raw['optionList'] ??
            raw['questionOptions'] ??
            <dynamic>[];
      }
      final parsedOptions = parseOptions(optionsDynamic);

      final questionText = (raw['text'] ??
              raw['question'] ??
              raw['title'] ??
              raw['questionText'] ??
              raw['prompt'] ??
              raw['content'] ??
              '')
          .toString()
          .trim();
      final resolvedQuestionText = questionText.isEmpty
          ? 'Question ${parsedQuestions.length + 1}'
          : questionText;

      if (parsedOptions.isEmpty) {
        for (var n = 1; n <= 10; n++) {
          final fallback = (raw['option$n'] ?? '').toString().trim();
          if (fallback.isNotEmpty) {
            parsedOptions.add({'title': fallback, 'tags': <String>[]});
          }
        }
      }

      if (parsedOptions.isEmpty) continue;

      parsedQuestions.add({
        'id': (raw['_id'] ?? '').toString(),
        'title': 'Assessment - Question ${parsedQuestions.length + 1}',
        'question': resolvedQuestionText,
        'options': parsedOptions,
      });
    }

    if (parsedQuestions.isEmpty) {
      setState(() {
        _isLoadingQuestions = false;
        _loadError =
            'Questions were loaded, but format is invalid (missing text/options).';
      });
      return;
    }

    setState(() {
      _questions = parsedQuestions;
      _answers = List<int>.filled(parsedQuestions.length, -1);
      _currentPage = 0;
      _isLoadingQuestions = false;
      _loadError = null;
    });
  }

  Future<void> _nextPage() async {
    if (_answers[_currentPage] == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an answer before continuing.')),
      );
      return;
    }
    if (_currentPage < _questions.length - 1) {
      await _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      await _submitAssessment();
    }
  }

  Future<void> _submitAssessment({bool forceOverwrite = false}) async {
    if (_isSubmitting) return;

    final token = _getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Login required to submit assessment.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final answersPayload = <Map<String, dynamic>>[];
      final unansweredIndexes = <int>[];
      for (var index = 0; index < _questions.length; index++) {
        final questionId = (_questions[index]['id'] ?? '').toString().trim();
        final selectedOptionIndex = _answers[index];
        if (questionId.isEmpty || selectedOptionIndex < 0) {
          unansweredIndexes.add(index + 1);
          continue;
        }
        answersPayload.add({
          'questionId': questionId,
          'selectedOptionIndex': selectedOptionIndex
        });
      }

      if (answersPayload.isEmpty || unansweredIndexes.isNotEmpty) {
        final message = unansweredIndexes.isEmpty
            ? 'Please answer all questions before completing the assessment.'
            : 'Please answer all questions. Missing: ${unansweredIndexes.take(5).join(', ')}${unansweredIndexes.length > 5 ? '...' : ''}.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      final response = await ApiService.postWithAuth(
          '/assessment/submit',
          forceOverwrite
              ? {'answers': answersPayload, 'overwrite': true}
              : answersPayload,
          token);
      if (!mounted) return;

      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final responseSuccess = response['success'] == true;
      final requiresConfirmation = response['requiresConfirmation'] == true ||
          data['requiresConfirmation'] == true;
      final responseMessage = (response['message'] ??
              data['message'] ??
              data['reason'] ??
              'Submission failed')
          .toString();

      if (responseSuccess && requiresConfirmation) {
        setState(() => _isSubmitting = false);

        if (forceOverwrite || _isOverwriteAttempt) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Assessment overwrite requires backend support and is currently unavailable.')),
          );
          return;
        }

        await showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          builder: (context) => RetakeAssessmentDialog(
            onRetake: () {
              Navigator.of(context).pop();
              _isOverwriteAttempt = true;
              _submitAssessment(forceOverwrite: true);
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        );
        _isOverwriteAttempt = false;
        return;
      }

      if (responseSuccess) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => AssessmentCompleteState(answers: _answers)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(responseMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unexpected error during submission.')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: const Color(0xFF6B7280))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _loadQuestions, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Progress header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.chevron_left,
                        size: 18, color: Color(0xFF6B7280)),
                    Text('Question ${_currentPage + 1} of ${_questions.length}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280))),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      'Total questions are generated dynamically based on your profile.',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF9CA3AF))),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                          begin: 0,
                          end: _questions.isEmpty
                              ? 0
                              : (_currentPage + 1) / _questions.length),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) =>
                          LinearProgressIndicator(
                        value: value,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF1D5572)),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _questions.length,
                itemBuilder: (context, index) =>
                    _buildQuestionPage(_questions[index], index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A100),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          _currentPage == _questions.length - 1
                              ? 'Complete Assessment'
                              : 'Next Question',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF001636)),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.assess),
    );
  }

  Widget _buildQuestionPage(Map<String, dynamic> questionData, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(questionData['question'],
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                  height: 1.4)),
          const SizedBox(height: 20),
          ...List.generate(questionData['options'].length, (optIndex) {
            final isSelected = _answers[index] == optIndex;
            return GestureDetector(
              onTap: () => setState(() => _answers[index] = optIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF5A100)
                          : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: const Color(0xFFF5A100).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : [],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFFF5A100)
                            : Colors.transparent,
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFFF5A100)
                                : const Color(0xFFD1D5DB),
                            width: 2),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(questionData['options'][optIndex]['title'],
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1F2937))),
                          if ((questionData['options'][optIndex]['tags']
                                  as List<dynamic>)
                              .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: (questionData['options'][optIndex]
                                      ['tags'] as List<dynamic>)
                                  .map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Text(tag.toString(),
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color:
                                                    const Color(0xFF6B7280))),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ===== ASSESSMENT COMPLETE =====
class AssessmentCompleteState extends StatelessWidget {
  final List<int> answers;
  const AssessmentCompleteState({super.key, required this.answers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(40)),
                  child: const Icon(Icons.check_circle_outline,
                      color: Color(0xFF1D5572), size: 50),
                ),
                const SizedBox(height: 20),
                Text('Assessment Complete!',
                    style: GoogleFonts.inter(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937))),
                const SizedBox(height: 8),
                Text("We've identified your key strengths and skills",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF6B7280))),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CareerMatchesScreen())),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A100),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: Text('View Career Matches',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF001636))),
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
}

// ===== CAREER MATCHES SCREEN =====
class CareerMatchesScreen extends StatefulWidget {
  const CareerMatchesScreen({super.key});

  @override
  State<CareerMatchesScreen> createState() => _CareerMatchesScreenState();
}

class _CareerMatchesScreenState extends State<CareerMatchesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _suggestions = [];
  String? _choosingCareerId;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  String? _token() {
    try {
      return context.read<AuthProvider>().token;
    } catch (_) {
      return null;
    }
  }

  int _asPercent(dynamic v) {
    if (v == null) return 0;
    final raw = v.toString().replaceAll('%', '').trim();
    double n = double.tryParse(raw) ?? 0;
    if (n >= 0 && n <= 1 && raw.contains('.')) n *= 100;
    final rounded = n.round();
    if (rounded < 0) return 0;
    if (rounded > 100) return 100;
    return rounded;
  }

  String _extractCareerId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final nested = value['_id'] ?? value['id'] ?? value['careerId'];
      return nested?.toString() ?? '';
    }
    return value.toString();
  }

  Future<void> _loadResult() async {
    final token = _token();
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Login required.';
      });
      return;
    }

    final response = await ApiService.get('/assessment/result', token);
    if (response['success'] != true) {
      setState(() {
        _isLoading = false;
        _error = (response['message'] ?? 'Failed to load assessment result.')
            .toString();
      });
      return;
    }

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final suggestionsRaw = data['suggestions'];
    final suggestions = suggestionsRaw is List ? suggestionsRaw : <dynamic>[];

    setState(() {
      _suggestions = suggestions
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _isLoading = false;
      _error = null;
    });
  }

  Future<void> _chooseCareer(String careerId, String careerName) async {
    final token = _token();
    if (token == null || token.isEmpty) return;

    final trimmedId = careerId.trim();
    if (trimmedId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid career id.')));
      return;
    }

    setState(() => _choosingCareerId = trimmedId);

    final response = await ApiService.postWithAuth(
        '/assessment/choose-career', {'careerId': trimmedId}, token);
    if (!mounted) return;

    setState(() => _choosingCareerId = null);

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Career selected and roadmap initialized.')));
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LearningRoadmapScreen(
                  careerName: careerName, fromAssessment: true)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              (response['message'] ?? 'Failed to choose career').toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  left: 16, right: 20, top: 40, bottom: 15),
              decoration: const BoxDecoration(
                color: Color(0xFF1D5572),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Career Matches',
                    style: GoogleFonts.inter(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ' recommendations based on your skills',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_suggestions.isEmpty)
                                Text('No suggestions found yet.',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF6B7280))),
                              ..._suggestions.map(_buildCareerCard),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.assess),
    );
  }

  Widget _buildCareerCard(Map<String, dynamic> suggestion) {
    final careerId =
        _extractCareerId(suggestion['careerId'] ?? suggestion['id']).trim();
    final title = (suggestion['name'] ?? 'Career').toString();
    final percent = _asPercent(suggestion['percentage'] ??
        suggestion['finalScore'] ??
        suggestion['score'] ??
        suggestion['match'] ??
        suggestion['matchPercentage']);
    final breakdown = suggestion['breakdown'] as Map<String, dynamic>? ?? {};
    final isChoosing = _choosingCareerId == careerId;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text('$percent% Match',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF1D5572)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Technical: ${_asPercent(breakdown['technical'] ?? breakdown['technicalScore'])}%   '
            'Personality: ${_asPercent(breakdown['personality'] ?? breakdown['personalityScore'])}%   '
            'Soft: ${_asPercent(breakdown['soft'] ?? breakdown['softSkills'] ?? breakdown['softScore'])}%',
            style:
                GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (careerId.isEmpty || isChoosing)
                  ? null
                  : () => _chooseCareer(careerId, title),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D5572),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
              child: isChoosing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('View Roadmap',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== RETAKE ASSESSMENT DIALOG =====
class RetakeAssessmentDialog extends StatefulWidget {
  final VoidCallback onRetake;
  final VoidCallback onCancel;

  const RetakeAssessmentDialog({
    super.key,
    required this.onRetake,
    required this.onCancel,
  });

  @override
  State<RetakeAssessmentDialog> createState() => _RetakeAssessmentDialogState();
}

class _RetakeAssessmentDialogState extends State<RetakeAssessmentDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular icon with refresh symbol
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF9CA3AF),
              ),
              child: RotationTransition(
                turns: Tween<double>(begin: 1.0, end: 0.0).animate(_controller),
                child: const Icon(
                  Icons.replay_rounded,
                  size: 55,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Retake Assessment?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE6A817),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            const Text(
              'Retaking it will update your career recommendations and replace your current learning roadmap with a new one.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xff1D5572),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons row
            Row(
              children: [
                // Retake button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5572),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: widget.onRetake,
                    child: const Text(
                      'Retake',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Color(0xFFD9D9D9),
                    ),
                    onPressed: widget.onCancel,
                    child: const Text(
                      'No, cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D5572),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
