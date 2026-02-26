import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    for (int c = 0; c < careers.length; c++) {
      if (q < answers.length) {
        careers[c].score += matrices[q][c][answers[q]];
      }
    }
  }
  careers.sort((a, b) => b.score.compareTo(a.score));
  return careers;
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
  final List<int> _answers = List.filled(5, 0);

  final List<Map<String, dynamic>> _questions = [
    {
      'title': 'Assessment - Question 1',
      'question': 'Which activity do you enjoy\nmost?',
      'options': [
        {'title': 'Building software and apps', 'tags': ['Programming', 'Problem Solving']},
        {'title': 'Presenting and communicating ideas', 'tags': ['Communication', 'Leadership']},
        {'title': 'Analyzing data and patterns', 'tags': ['Analytics', 'Critical Thinking']},
        {'title': 'Creating visual designs', 'tags': ['Design', 'Creativity']},
      ]
    },
    {
      'title': 'Assessment - Question 2',
      'question': "What's your preferred working\nstyle?",
      'options': [
        {'title': 'Working independently', 'tags': ['Self-motivated', 'Focus']},
        {'title': 'Mix of both', 'tags': ['Adaptability', 'Flexibility']},
        {'title': 'Leading and mentoring others', 'tags': ['Leadership', 'Mentoring']},
        {'title': 'Collaborating with teams', 'tags': ['Teamwork', 'Collaboration']},
      ]
    },
    {
      'title': 'Assessment - Question 3',
      'question': 'Which technical skill interests\nyou most?',
      'options': [
        {'title': 'Web Development', 'tags': ['HTML/CSS', 'JavaScript', 'React']},
        {'title': 'Cloud & DevOps', 'tags': ['AWS', 'Docker', 'CI/CD']},
        {'title': 'Mobile App Development', 'tags': ['Swift', 'Kotlin', 'Flutter']},
        {'title': 'Data Science', 'tags': ['Python', 'Statistics', 'ML']},
      ]
    },
    {
      'title': 'Assessment - Question 4',
      'question': 'How do you approach problem\nsolving?',
      'options': [
        {'title': 'Creative and innovative', 'tags': ['Innovation', 'Creative Thinking']},
        {'title': 'Research-based approach', 'tags': ['Research', 'Structured Thinking']},
        {'title': 'Systematic and methodical', 'tags': ['Analytical', 'Critical Thinking']},
        {'title': 'Hands-on and practical', 'tags': ['Practical', 'Execution']},
      ]
    },
    {
      'title': 'Assessment - Question 5',
      'question': 'What motivates you in your\ncareer?',
      'options': [
        {'title': 'Making a positive impact', 'tags': ['Purpose-driven', 'Impact']},
        {'title': 'Stability and security', 'tags': ['Reliability', 'Consistency']},
        {'title': 'Creating new solutions', 'tags': ['Innovation', 'Entrepreneurship']},
        {'title': 'Learning and growth', 'tags': ['Growth Mindset', 'Learning']},
      ]
    },
  ];

  void _nextPage() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentCompleteState(answers: _answers),
        ),
      );
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
          // Progress bar moved here to stay fixed and animate smoothly
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.chevron_left, size: 18, color: Color(0xFF6B7280)),
                  Text('Question ${_currentPage + 1} of 5',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: (_currentPage + 1) / 5),
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
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _currentPage == _questions.length - 1 ? 'Complete Assessment' : 'Next Question',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF001636)),
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
          const SizedBox(height: 4), // Small offset since progress bar is above
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
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: (questionData['options'][optIndex]['tags'] as List<String>)
                                .map((tag) => Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(20)),
                                      child: Text(tag,
                                          style: GoogleFonts.inter(
                                              fontSize: 12, color: const Color(0xFF6B7280))),
                                    ))
                                .toList(),
                          ),
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
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => CareerMatchesScreen(answers: answers))),
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
class CareerMatchesScreen extends StatelessWidget {
  final List<int> answers;
  const CareerMatchesScreen({super.key, required this.answers});

  @override
  Widget build(BuildContext context) {
    final matches = calculateMatches(answers);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5572),
        title: const Text('Career Matches', style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Career Matches',
                style: GoogleFonts.inter(
                    fontSize: 25, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text('Recommendations based on your skills',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
            const SizedBox(height: 20),
            ...matches.map((career) => _buildCareerCard(career)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  Widget _buildCareerCard(CareerScore career) {
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
          Text(career.title,
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text('${career.matchPercent}% Match',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: career.matchPercent / 100,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D5572)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Text(career.description,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
          const SizedBox(height: 12),
          Text('Key Skills:',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: career.skills
                .map((skill) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(skill,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFF5A100))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5572),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  child: Text('View Roadmap',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9D9D9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  child: Text('Learn More',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1D5572))),
                ),
              ),
            ],
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
