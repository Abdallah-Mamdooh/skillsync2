import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

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
class AssessmentStartScreen extends StatelessWidget {
  const AssessmentStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1D5572)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        Image.asset(
                          'assets/images/assessment_start_logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Career Skill Assessment",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
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
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
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
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const AssessmentQuestion1(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOut;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child);
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5A100),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Start Assessment',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF001636),
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
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNav(1),
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
              fontWeight: FontWeight.w500,
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
            if (title.isNotEmpty)
              parsed.add({'title': title, 'tags': <String>[]});
            continue;
          }
          if (opt is Map<String, dynamic>) {
            final title = extractOptionTitle(opt);
            if (title.isNotEmpty)
              parsed.add({'title': title, 'tags': <String>[]});
          }
        }
      } else if (optionsDynamic is Map<String, dynamic>) {
        for (final entry in optionsDynamic.entries) {
          if (entry.value is String) {
            final title = (entry.value as String).trim();
            if (title.isNotEmpty)
              parsed.add({'title': title, 'tags': <String>[]});
          } else if (entry.value is Map<String, dynamic>) {
            final title =
                extractOptionTitle(entry.value as Map<String, dynamic>);
            if (title.isNotEmpty)
              parsed.add({'title': title, 'tags': <String>[]});
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
          if (fallback.isNotEmpty)
            parsedOptions.add({'title': fallback, 'tags': <String>[]});
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
          '/assessment/submit', answersPayload, token);
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

        final shouldOverwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Overwrite Assessment?'),
            content: Text(responseMessage.isEmpty
                ? 'You already completed the assessment. Overwrite old results?'
                : responseMessage),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Overwrite')),
            ],
          ),
        );

        if (shouldOverwrite == true) {
          _isOverwriteAttempt = true;
          await _submitAssessment(forceOverwrite: true);
          _isOverwriteAttempt = false;
        }
        return;
      }

      if (responseSuccess) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AssessmentCompleteState(answers: _answers)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(responseMessage)));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unexpected error during submission.')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D5572),
          elevation: 0,
          title: const Text('Assessment',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1D5572),
          elevation: 0,
          title: const Text('Assessment',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
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
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5572),
        elevation: 0,
        title: Text(_questions[_currentPage]['title'],
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _previousPage),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    builder: (context, value, child) => LinearProgressIndicator(
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
      bottomNavigationBar: buildBottomNav(1),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5572),
        title: const Text('Assessment Complete',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
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
                onPressed: () => Navigator.push(
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
      bottomNavigationBar: buildBottomNav(1),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5572),
        title: const Text('Career Matches',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Career Matches',
                          style: GoogleFonts.inter(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Text('Recommendations based on your assessment result',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: const Color(0xFF6B7280))),
                      const SizedBox(height: 20),
                      if (_suggestions.isEmpty)
                        Text('No suggestions found yet.',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: const Color(0xFF6B7280))),
                      ..._suggestions.map(_buildCareerCard),
                    ],
                  ),
                ),
      bottomNavigationBar: buildBottomNav(1),
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

// ===== LEARNING ROADMAP SCREEN (REDESIGNED) =====
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
  bool _isLoading = true;
  String? _error;
  List<RoadmapStep> _steps = [];

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
      final response = await ApiService.get('/roadmap/my-roadmap', token);

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> stepsRaw = data is Map
            ? (data['steps'] ?? data['milestones'] ?? [])
            : (data is List ? data : []);

        if (stepsRaw.isNotEmpty) {
          final parsed = <RoadmapStep>[];
          for (var i = 0; i < stepsRaw.length; i++) {
            final s = stepsRaw[i];
            if (s is Map<String, dynamic>) {
              final title =
                  (s['title'] ?? s['name'] ?? s['label'] ?? 'Step ${i + 1}')
                      .toString();
              final completed = s['completed'] == true ||
                  s['isCompleted'] == true ||
                  s['status'] == 'completed';
              parsed.add(RoadmapStep(
                  number: i + 1, title: title, isCompleted: completed));
            }
          }
          setState(() {
            _steps = parsed;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // ignore, fall through to dummy
    }

    _useDummySteps();
  }

  void _useDummySteps() {
    setState(() {
      _steps = const [
        RoadmapStep(
            number: 1, title: 'HTML & CSS Fundamentals', isCompleted: true),
        RoadmapStep(
            number: 2, title: 'JavaScript Essentials', isCompleted: false),
        RoadmapStep(number: 3, title: 'React Framework', isCompleted: false),
        RoadmapStep(
            number: 4, title: 'Backend with Node.js', isCompleted: false),
        RoadmapStep(number: 5, title: 'Full Stack Project', isCompleted: false),
        RoadmapStep(number: 6, title: 'Database Design', isCompleted: false),
        RoadmapStep(number: 7, title: 'API Development', isCompleted: false),
        RoadmapStep(
            number: 8, title: 'Testing & Debugging', isCompleted: false),
        RoadmapStep(number: 9, title: 'Deployment', isCompleted: false),
        RoadmapStep(
            number: 10, title: 'Interview Preparation', isCompleted: false),
      ];
      _isLoading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: const Color(0xFF6B7280))),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadRoadmap, child: const Text('Retry')),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Background serpentine road (custom painted)
                    Positioned(
                      left: 31,
                      top: 212,
                      child: SizedBox(
                        width: 331,
                        height: 629,
                        child: CustomPaint(
                          painter: SerpentineRoadPainter(),
                        ),
                      ),
                    ),

                    // Header Section
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: 393,
                        height: 132,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D5572),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 31,
                              top: 71,
                              child: Text(
                                'Learning Roadmap',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 31,
                              top: 103,
                              child: Text(
                                widget.careerName != null
                                    ? '${widget.careerName} - Your personalized path to success'
                                    : 'Your personalized path to success',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            // Back button
                            Positioned(
                              left: 10,
                              top: 50,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Career Title
                    Positioned(
                      left: 71,
                      top: 149,
                      child: Text(
                        widget.careerName ?? 'Full Stack Developer',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1F2937),
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),

                    // START Node
                    Positioned(
                      left: 19,
                      top: 205,
                      child: Container(
                        width: 41,
                        height: 41,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A100),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 5,
                              top: 5,
                              child: Container(
                                width: 31,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCFCFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 9,
                              top: 9,
                              child: Container(
                                width: 23,
                                height: 23,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5A100),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'START',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFFCFCFC),
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Roadmap Steps
                    ..._buildStepWidgets(),

                    // END Node
                    Positioned(
                      left: 26,
                      top: 833,
                      child: Container(
                        width: 41,
                        height: 41,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D5572),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 5,
                              top: 5,
                              child: Container(
                                width: 31,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCFCFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 9,
                              top: 9,
                              child: Container(
                                width: 23,
                                height: 23,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D5572),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'END',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFFCFCFC),
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Choose This Roadmap Button
                    Positioned(
                      left: 26,
                      top: 889,
                      child: GestureDetector(
                        onTap: widget.fromAssessment
                            ? () {
                                Navigator.popUntil(
                                    context, (route) => route.isFirst);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Roadmap selected! Start your learning journey.')),
                                );
                              }
                            : null,
                        child: Container(
                          width: 169,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D5572),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              widget.fromAssessment
                                  ? 'Choose This Roadmap'
                                  : 'Continue Learning',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Cancel Button
                    Positioned(
                      left: 199,
                      top: 889,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 169,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1D5572),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildStepWidgets() {
    final List<Widget> widgets = [];

    // Define positions for all 10 steps based on Figma design
    final List<Map<String, dynamic>> stepPositions = [
      {
        'number': 1,
        'top': 190,
        'left': 67,
        'textTop': 194,
        'textLeft': 101,
        'isLeft': true
      },
      {
        'number': 2,
        'top': 255,
        'left': 300,
        'textTop': 264,
        'textLeft': 140,
        'isLeft': false
      },
      {
        'number': 3,
        'top': 326,
        'left': 67,
        'textTop': 333,
        'textLeft': 101,
        'isLeft': true
      },
      {
        'number': 4,
        'top': 396,
        'left': 300,
        'textTop': 401,
        'textLeft': 136,
        'isLeft': false
      },
      {
        'number': 5,
        'top': 467,
        'left': 67,
        'textTop': 470,
        'textLeft': 101,
        'isLeft': true
      },
      {
        'number': 6,
        'top': 537,
        'left': 300,
        'textTop': 545,
        'textLeft': 308,
        'isLeft': false
      },
      {
        'number': 7,
        'top': 603,
        'left': 67,
        'textTop': 606,
        'textLeft': 101,
        'isLeft': true
      },
      {
        'number': 8,
        'top': 673,
        'left': 300,
        'textTop': 681,
        'textLeft': 308,
        'isLeft': false
      },
      {
        'number': 9,
        'top': 744,
        'left': 67,
        'textTop': 747,
        'textLeft': 101,
        'isLeft': true
      },
      {
        'number': 10,
        'top': 814,
        'left': 300,
        'textTop': 822,
        'textLeft': 308,
        'isLeft': false
      },
    ];

    for (int i = 0; i < _steps.length && i < stepPositions.length; i++) {
      final step = _steps[i];
      final Map<String, dynamic> pos = stepPositions[i];
      final Color fillColor =
          step.isCompleted ? const Color(0xFFF5A100) : const Color(0xFF1D5572);

      // Extract values with proper type casting
      final double top = (pos['top'] as num).toDouble();
      final double left = (pos['left'] as num).toDouble();
      final double textTop = (pos['textTop'] as num).toDouble();
      final double textLeft = (pos['textLeft'] as num).toDouble();

      // Add the pin
      widgets.add(_buildStepPin(
        number: step.number,
        fillColor: fillColor,
        top: top,
        left: left,
      ));

      // Add the text label
      widgets.add(_buildStepText(
        title: step.title,
        top: textTop,
        left: textLeft,
      ));

      // Add connecting tail (except for last step)
      if (i < _steps.length - 1) {
        final double tailTop = (pos['top'] as num).toDouble() + 23;
        final double tailLeft = (pos['left'] as num).toDouble() + 9;
        widgets.add(_buildTail(
          fillColor: fillColor,
          top: tailTop,
          left: tailLeft,
        ));
      }
    }

    return widgets;
  }

  Widget _buildStepPin({
    required int number,
    required Color fillColor,
    required double top,
    required double left,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 3,
              top: 3,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFC),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            Positioned(
              left: 5,
              top: 5,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  number.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFCFCFC),
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepText({
    required String title,
    required double top,
    required double left,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: 200,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 15,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTail({
    required Color fillColor,
    required double top,
    required double left,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: CustomPaint(
        size: const Size(7, 20),
        painter: _RoadmapTailPainter(color: fillColor),
      ),
    );
  }
}

// Tail painter for connecting lines
class _RoadmapTailPainter extends CustomPainter {
  final Color color;
  const _RoadmapTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _RoadmapTailPainter && oldDelegate.color != color;
  }
}

// ===== DATA MODEL =====
class RoadmapStep {
  final int number;
  final String title;
  final bool isCompleted;

  const RoadmapStep({
    required this.number,
    required this.title,
    this.isCompleted = false,
  });
}

// ===== SHARED BOTTOM NAV BAR =====
BottomNavigationBar buildBottomNav(int currentIndex) {
  return BottomNavigationBar(
    backgroundColor: const Color(0xFF1D5572),
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedLabelStyle:
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
    items: const [
      BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home'),
      BottomNavigationBarItem(
          icon: Icon(Icons.assessment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'assess'),
      BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Chat'),
      BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile'),
    ],
  );
}

// ===== SERPENTINE ROAD PAINTER =====
/// Paints a serpentine (snake-like) road with two alternating colors:
/// orange (#F5A623) and dark teal (#2A5F7A), switching at the midpoint
/// of each horizontal segment.
class SerpentineRoadPainter extends CustomPainter {
  static const Color kOrange = Color(0xFFF5A623);
  static const Color kTeal = Color(0xFF2A5F7A);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Stroke width (road thickness)
    final double sw = w * 0.07;

    // Horizontal extents
    final double lx = sw * 0.5;       // left endpoint x
    final double rx = w - sw * 0.5;   // right endpoint x
    final double mid = midX(w);         // color-switch x

    // 7 horizontal rows, evenly spaced
    const int rows = 7;
    final double rowH = h / rows;
    final List<double> ys = List.generate(rows, (i) => rowH * i + rowH / 2);

    // Radius of each U-turn arc = half the vertical gap between rows
    final double arcR = rowH / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Per-row: left-half color, right-half color, arc color, arc side
    final rowDefs = <_RowDef>[
      _RowDef(lc: kOrange, rc: kTeal,   arcColor: kTeal,   arcRight: true),
      _RowDef(lc: kOrange, rc: kTeal,   arcColor: kOrange, arcRight: false),
      _RowDef(lc: kTeal,   rc: kOrange, arcColor: kTeal,   arcRight: true),
      _RowDef(lc: kTeal,   rc: kOrange, arcColor: kOrange, arcRight: false),
      _RowDef(lc: kOrange, rc: kTeal,   arcColor: kTeal,   arcRight: true),
      _RowDef(lc: kOrange, rc: kTeal,   arcColor: kOrange, arcRight: false),
      _RowDef(lc: kTeal,   rc: kOrange, arcColor: null,    arcRight: false),
    ];

    for (int i = 0; i < rows; i++) {
      final def = rowDefs[i];
      final double y = ys[i];

      // Left half of horizontal
      paint.color = def.lc;
      canvas.drawLine(Offset(lx, y), Offset(mid, y), paint);

      // Right half of horizontal
      paint.color = def.rc;
      canvas.drawLine(Offset(mid, y), Offset(rx, y), paint);

      // Arc connecting this row to the next
      if (i < rows - 1 && def.arcColor != null) {
        final double nextY = ys[i + 1];
        final double cy = (y + nextY) / 2;
        paint.color = def.arcColor!;

        if (def.arcRight) {
          // Right-side U-turn (opens left): center at (rx, cy)
          final rect = Rect.fromCircle(center: Offset(rx, cy), radius: arcR);
          canvas.drawArc(rect, -pi / 2, pi, false, paint);
        } else {
          // Left-side U-turn (opens right): center at (lx, cy)
          final rect = Rect.fromCircle(center: Offset(lx, cy), radius: arcR);
          canvas.drawArc(rect, pi / 2, pi, false, paint);
        }
      }
    }
  }

  double midX(double w) => w / 2;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
