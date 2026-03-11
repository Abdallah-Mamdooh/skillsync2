import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/roadmap_screen.dart';
import '../services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assessment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      home: const AssessmentStartScreen(),
    );
  }
}

// ===== CAREER MODEL =====
class CareerScore {
  final String title;
  final String description;
  final List<String> skills;
  int score;
  CareerScore({required this.title, required this.description, required this.skills, this.score = 0});
  int get matchPercent => (score * 5).clamp(0, 99);
}

List<CareerScore> calculateMatches(List<int> answers) {
  final careers = [
    CareerScore(title: 'Full Stack Developer', description: 'Build end-to-end web applications using modern frameworks.', skills: ['JavaScript', 'React', 'Node.js', 'Database']),
    CareerScore(title: 'Data Analyst', description: 'Transform data into actionable insights using statistical analysis.', skills: ['Python', 'SQL', 'Statistics', 'Tableau']),
    CareerScore(title: 'UX/UI Designer', description: 'Design intuitive and beautiful user experiences for digital products.', skills: ['Figma', 'Prototyping', 'User Research', 'Design Systems']),
    CareerScore(title: 'Cloud Engineer', description: 'Design and manage scalable cloud infrastructure and deployment pipelines.', skills: ['AWS', 'Docker', 'CI/CD', 'Linux']),
  ];
  final q1 = [[3, 0, 1, 0], [0, 0, 3, 0], [0, 2, 0, 3], [2, 0, 1, 0]];
  final q2 = [[1, 2, 1, 2], [3, 1, 0, 1], [1, 2, 2, 2], [2, 2, 1, 1]];
  final q3 = [[3, 0, 2, 0], [0, 0, 0, 3], [1, 0, 1, 0], [1, 3, 0, 1]];
  final q4 = [[1, 1, 2, 3], [0, 3, 2, 1], [3, 1, 1, 1], [0, 1, 3, 2]];
  final q5 = [[2, 1, 3, 2], [1, 2, 2, 2], [2, 1, 2, 2], [1, 3, 2, 2]];
  final matrices = [q1, q2, q3, q4, q5];
  
  for (int q = 0; q < answers.length; q++) {
    // If we have more answers than hardcoded matrices, stop or use a default
    if (q >= matrices.length) break;
    
    final answerIndex = answers[q];
    if (answerIndex == -1) continue;

    for (int c = 0; c < careers.length; c++) {
      // Safety check: ensure career index exists in matrix and answer index exists in career scores
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
            // Back Button
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
                        // Assessment Logod
                        Image.asset(
                          'assets/images/assessment_start_logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),

                        // Title
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

                        // Info Box
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

                        // Start Button directly under the Info Box with smooth navigationn
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      const AssessmentQuestion1(),
                                  transitionsBuilder:
                                      (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOut;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 400),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5A100),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
      bottomNavigationBar: _buildBottomNav(1),
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
          child: Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFF1D5572),
          ),
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

    final sectionsResponse = await ApiService.get('/assessment/sections', token);
    debugPrint('[Assessment] /sections success=${sectionsResponse['success']}');
    debugPrint('[Assessment] sectionsResponse=$sectionsResponse');
    if (sectionsResponse['success'] != true) {
      debugPrint('[Assessment] /sections error=${sectionsResponse['message']}');
      setState(() {
        _isLoadingQuestions = false;
        _loadError = sectionsResponse['message'] ?? 'Failed to load assessment sections.';
      });
      return;
    }

    final dynamic sectionsData = sectionsResponse['data'];
    final List<dynamic> sections = sectionsData is List
        ? sectionsData
        : (sectionsData is Map<String, dynamic> && sectionsData['sections'] is List
            ? sectionsData['sections'] as List<dynamic>
            : <dynamic>[]);
    debugPrint('[Assessment] sections count=${sections.length}');
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
      final sectionTitle = (sectionMap['title'] ?? '').toString();
      debugPrint('[Assessment] section id=$sectionId title="$sectionTitle"');
      if (sectionId == null || sectionId.isEmpty) continue;

      final questionsResponse =
          await ApiService.get('/assessment/questions/$sectionId', token);
      debugPrint('[Assessment] /questions/$sectionId success=${questionsResponse['success']}');
      debugPrint('[Assessment] questionsResponse(sectionId=$sectionId)=$questionsResponse');
      if (questionsResponse['success'] != true) {
        debugPrint('[Assessment] /questions/$sectionId error=${questionsResponse['message']}');
        setState(() {
          _isLoadingQuestions = false;
          _loadError = questionsResponse['message'] ?? 'Failed to load questions.';
        });
        return;
      }

      final dynamic questionsData = questionsResponse['data'];
      final List<dynamic> sectionQuestions = questionsData is List
          ? questionsData
          : (questionsData is Map<String, dynamic> && questionsData['questions'] is List
              ? questionsData['questions'] as List<dynamic>
              : <dynamic>[]);
      debugPrint('[Assessment] section id=$sectionId questions=${sectionQuestions.length}');

      allQuestionsRaw.addAll(sectionQuestions);
    }

    debugPrint('[Assessment] total questions=${allQuestionsRaw.length}');
    if (allQuestionsRaw.isNotEmpty) {
      debugPrint('[Assessment] allQuestionsRaw.first=${allQuestionsRaw.first}');
    }
    if (allQuestionsRaw.isEmpty) {
      setState(() {
        _isLoadingQuestions = false;
        _loadError = 'No assessment questions found.';
      });
      return;
    }

    String _extractOptionTitle(Map<String, dynamic> opt) {
      final preferred = [
        opt['text'],
        opt['title'],
        opt['optionText'],
        opt['label'],
        opt['name'],
        opt['value'],
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

    List<Map<String, dynamic>> _parseOptions(dynamic optionsDynamic) {
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
            final title = _extractOptionTitle(opt);
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
            final title = _extractOptionTitle(entry.value as Map<String, dynamic>);
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
      debugPrint('[Assessment] raw question keys=${raw.keys.toList()}');

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
      final parsedOptions = _parseOptions(optionsDynamic);

      final questionText = (raw['text'] ??
              raw['question'] ??
              raw['title'] ??
              raw['questionText'] ??
              raw['prompt'] ??
              raw['content'] ??
              '')
          .toString()
          .trim();

      final resolvedQuestionText =
          questionText.isEmpty ? 'Question ${parsedQuestions.length + 1}' : questionText;

      if (parsedOptions.isEmpty) {
        // Last fallback for flattened schemas like option1/option2/option3...
        for (var n = 1; n <= 10; n++) {
          final fallback = (raw['option$n'] ?? '').toString().trim();
          if (fallback.isNotEmpty) {
            parsedOptions.add({'title': fallback, 'tags': <String>[]});
          }
        }
      }

      if (parsedOptions.isEmpty) {
        debugPrint(
          '[Assessment] skipped invalid question id=${raw['_id']} text="$resolvedQuestionText" options=${parsedOptions.length}',
        );
        continue;
      }

      parsedQuestions.add({
        'id': (raw['_id'] ?? '').toString(),
        'title': 'Assessment - Question ${parsedQuestions.length + 1}',
        'question': resolvedQuestionText,
        'options': parsedOptions,
      });
    }

    debugPrint('[Assessment] valid parsed questions=${parsedQuestions.length}');
    if (parsedQuestions.isEmpty) {
      setState(() {
        _isLoadingQuestions = false;
        _loadError = 'Questions were loaded, but format is invalid (missing text/options).';
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
        const SnackBar(content: Text('Please select an answer before continuing.')),
      );
      return;
    }

    if (_currentPage < _questions.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _submitAssessment();
    }
  }

  Future<void> _submitAssessment({bool forceOverwrite = false}) async {
    if (_isSubmitting) return;

    final token = _getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to submit assessment.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final answersPayload = List<Map<String, dynamic>>.generate(
        _questions.length,
        (index) => {
          'questionId': _questions[index]['id'],
          'selectedOptionIndex': _answers[index],
        },
      );

      final response = await ApiService.postWithAuth(
        '/assessment/submit',
        {
          'answers': answersPayload,
          if (forceOverwrite) 'forceOverwrite': true,
        },
        token,
      );

      if (!mounted) return;

      if (response['success'] == true &&
          response['requiresConfirmation'] == true) {
        setState(() {
          _isSubmitting = false;
        });

        final shouldOverwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Overwrite Assessment?'),
            content: Text(
              (response['message'] ??
                      'You already completed the assessment. Overwrite old results?')
                  .toString(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Overwrite'),
              ),
            ],
          ),
        );

        if (shouldOverwrite == true) {
          await _submitAssessment(forceOverwrite: true);
        }
        return;
      }

      if (response['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentCompleteState(answers: _answers),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((response['message'] ?? 'Submission failed').toString())),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected error during submission.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
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
          title: const Text('Assessment', style: TextStyle(color: Colors.white, fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
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
          title: const Text('Assessment', style: TextStyle(color: Colors.white, fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadQuestions,
                  child: const Text('Retry'),
                ),
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
          onPressed: _previousPage,
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.chevron_left, size: 18, color: Color(0xFF6B7280)),
                  Text('Question ${_currentPage + 1} of ${_questions.length}',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: _questions.isEmpty ? 0 : (_currentPage + 1) / _questions.length,
                    ),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D5572)),
                        minHeight: 6,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                return _buildQuestionPage(_questions[index], index);
              },
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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
      bottomNavigationBar: _buildBottomNav(1),
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
                  fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937), height: 1.4)),
          const SizedBox(height: 20),
          ...List.generate(questionData['options'].length, (optIndex) {
            final isSelected = _answers[index] == optIndex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _answers[index] = optIndex;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: isSelected ? const Color(0xFFF5A100) : const Color(0xFFE5E7EB),
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
                        color: isSelected ? const Color(0xFFF5A100) : Colors.transparent,
                        border: Border.all(
                            color: isSelected ? const Color(0xFFF5A100) : const Color(0xFFD1D5DB),
                            width: 2),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(questionData['options'][optIndex]['title'],
                              style: GoogleFonts.inter(
                                  fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1F2937))),
                          if ((questionData['options'][optIndex]['tags'] as List<dynamic>).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: (questionData['options'][optIndex]['tags'] as List<dynamic>)
                                  .map((tag) => Container(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(20)),
                                        child: Text(tag.toString(),
                                            style: GoogleFonts.inter(
                                                fontSize: 12, color: const Color(0xFF6B7280))),
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

class AssessmentCompleteState extends StatelessWidget {
  final List<int> answers;
  const AssessmentCompleteState({super.key, required this.answers});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5572),
        title: const Text('Assessment Complete', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
                  color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(40)),
              child: const Icon(Icons.check_circle_outline, color: Color(0xFF1D5572), size: 50),
            ),
            const SizedBox(height: 20),
            Text('Assessment Complete!',
                style: GoogleFonts.inter(
                    fontSize: 25, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text("We've identified your key strengths and skills",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CareerMatchesScreen())),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text('View Career Matches',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF001636))),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(1),
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
    if (n >= 0 && n <= 1 && raw.contains('.')) {
      n *= 100;
    }
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
        _error = (response['message'] ?? 'Failed to load assessment result.').toString();
      });
      return;
    }

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final suggestionsRaw = data['suggestions'];
    final suggestions = suggestionsRaw is List ? suggestionsRaw : <dynamic>[];

    setState(() {
      _suggestions =
          suggestions.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      _isLoading = false;
      _error = null;
    });
  }

  Future<void> _chooseCareer(String careerId) async {
    final token = _token();
    if (token == null || token.isEmpty) return;

    final trimmedId = careerId.trim();
    if (trimmedId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid career id.')),
      );
      return;
    }

    setState(() {
      _choosingCareerId = trimmedId;
    });

    final requestBodies = <Object>[
      trimmedId,
      {'careerId': trimmedId},
      {'id': trimmedId},
      {'_id': trimmedId},
    ];

    Map<String, dynamic>? lastResponse;
    bool hasChosenCareer = false;
    for (final body in requestBodies) {
      final response = await ApiService.postWithAuth('/assessment/choose-career', body, token);
      lastResponse = response;

      if (response['success'] == true) {
        final verify = await ApiService.get('/assessment/result', token);
        final data = verify['data'] as Map<String, dynamic>? ?? {};
        final chosenCareer = data['chosenCareer'];
        final chosenId = _extractCareerId(chosenCareer);
        hasChosenCareer = chosenId.isNotEmpty;
        if (hasChosenCareer) break;
      }
    }

    if (!mounted) return;

    setState(() {
      _choosingCareerId = null;
    });

    if (hasChosenCareer) {
      if (mounted) {
        await _loadResult();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Career selected and roadmap initialized.')),
      );
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RoadmapScreen()));
      }
    } else {
      final fallbackMessage = (lastResponse?['message'] ?? 'Failed to choose career').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fallbackMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5572),
        title: const Text('Career Matches', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
                      const SizedBox(height: 20),
                      if (_suggestions.isEmpty)
                        Text('No suggestions found yet.',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
                      ..._suggestions.map(_buildCareerCard),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  Widget _buildCareerCard(Map<String, dynamic> suggestion) {
    final careerId = _extractCareerId(suggestion['careerId'] ?? suggestion['id']).trim();
    final title = (suggestion['name'] ?? 'Career').toString();
    final percent = _asPercent(
      suggestion['percentage'] ??
          suggestion['finalScore'] ??
          suggestion['score'] ??
          suggestion['match'] ??
          suggestion['matchPercentage'],
    );
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
          BoxShadow(color: Color(0x1E000000), spreadRadius: 0, offset: Offset(0, 2), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text('$percent% Match',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D5572)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Technical: ${_asPercent(breakdown['technical'] ?? breakdown['technicalScore'])}%   Personality: ${_asPercent(breakdown['personality'] ?? breakdown['personalityScore'])}%   Soft: ${_asPercent(breakdown['soft'] ?? breakdown['softSkills'] ?? breakdown['softScore'])}%',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (careerId.isEmpty || isChoosing) ? null : () => _chooseCareer(careerId),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D5572),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              child: isChoosing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Choose Roadmap',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

BottomNavigationBar _buildBottomNav(int currentIndex) {
  return BottomNavigationBar(
    backgroundColor: const Color(0xFF1D5572),
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
    items: const [
      BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(
          icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assignment), label: 'assess'),
      BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
      BottomNavigationBarItem(
          icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}
