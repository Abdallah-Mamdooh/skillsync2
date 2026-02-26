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
  final q1 = [[3,0,1,0],[0,0,3,0],[0,2,0,3],[2,0,1,0]];
  final q2 = [[1,2,1,2],[3,1,0,1],[1,2,2,2],[2,2,1,1]];
  final q3 = [[3,0,2,0],[0,0,0,3],[1,0,1,0],[1,3,0,1]];
  final q4 = [[1,1,2,3],[0,3,2,1],[3,1,1,1],[0,1,3,2]];
  final q5 = [[2,1,3,2],[1,2,2,2],[2,1,2,2],[1,3,2,2]];
  final matrices = [q1,q2,q3,q4,q5];
  for (int q = 0; q < answers.length; q++) {
    for (int c = 0; c < careers.length; c++) {
      careers[c].score += matrices[q][c][answers[q]];
    }
  }
  careers.sort((a, b) => b.score.compareTo(a.score));
  return careers;
}

// ===== ASSESSMENT QUESTIONS =====
class AssessmentQuestion1 extends StatefulWidget {
  const AssessmentQuestion1({super.key});
  @override
  State<AssessmentQuestion1> createState() => _AssessmentQuestion1State();
}
class _AssessmentQuestion1State extends State<AssessmentQuestion1> {
  int selectedIndex = 0;
  final options = [
    {'title': 'Building software and apps', 'tags': ['Programming', 'Problem Solving']},
    {'title': 'Presenting and communicating ideas', 'tags': ['Communication', 'Leadership']},
    {'title': 'Analyzing data and patterns', 'tags': ['Analytics', 'Critical Thinking']},
    {'title': 'Creating visual designs', 'tags': ['Design', 'Creativity']},
  ];
  @override
  Widget build(BuildContext context) => _buildScaffold(
    context, 'Assessment - Question 1', 'Which activity do you enjoy\nmost?', 1, options,
    selectedIndex, (i) => setState(() => selectedIndex = i),
        () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AssessmentQuestion2(prevAnswers: [selectedIndex]))),
    'Next Question',
  );
}

class AssessmentQuestion2 extends StatefulWidget {
  final List<int> prevAnswers;
  const AssessmentQuestion2({super.key, required this.prevAnswers});
  @override
  State<AssessmentQuestion2> createState() => _AssessmentQuestion2State();
}
class _AssessmentQuestion2State extends State<AssessmentQuestion2> {
  int selectedIndex = 0;
  final options = [
    {'title': 'Working independently', 'tags': ['Self-motivated', 'Focus']},
    {'title': 'Mix of both', 'tags': ['Adaptability', 'Flexibility']},
    {'title': 'Leading and mentoring others', 'tags': ['Leadership', 'Mentoring']},
    {'title': 'Collaborating with teams', 'tags': ['Teamwork', 'Collaboration']},
  ];
  @override
  Widget build(BuildContext context) => _buildScaffold(
    context, 'Assessment - Question 2', "What's your preferred working\nstyle?", 2, options,
    selectedIndex, (i) => setState(() => selectedIndex = i),
        () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AssessmentQuestion3(prevAnswers: [...widget.prevAnswers, selectedIndex]))),
    'Next Question',
  );
}

class AssessmentQuestion3 extends StatefulWidget {
  final List<int> prevAnswers;
  const AssessmentQuestion3({super.key, required this.prevAnswers});
  @override
  State<AssessmentQuestion3> createState() => _AssessmentQuestion3State();
}
class _AssessmentQuestion3State extends State<AssessmentQuestion3> {
  int selectedIndex = 0;
  final options = [
    {'title': 'Web Development', 'tags': ['HTML/CSS', 'JavaScript', 'React']},
    {'title': 'Cloud & DevOps', 'tags': ['AWS', 'Docker', 'CI/CD']},
    {'title': 'Mobile App Development', 'tags': ['Swift', 'Kotlin', 'Flutter']},
    {'title': 'Data Science', 'tags': ['Python', 'Statistics', 'ML']},
  ];
  @override
  Widget build(BuildContext context) => _buildScaffold(
    context, 'Assessment - Question 3', 'Which technical skill interests\nyou most?', 3, options,
    selectedIndex, (i) => setState(() => selectedIndex = i),
        () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AssessmentQuestion4(prevAnswers: [...widget.prevAnswers, selectedIndex]))),
    'Next Question',
  );
}

class AssessmentQuestion4 extends StatefulWidget {
  final List<int> prevAnswers;
  const AssessmentQuestion4({super.key, required this.prevAnswers});
  @override
  State<AssessmentQuestion4> createState() => _AssessmentQuestion4State();
}
class _AssessmentQuestion4State extends State<AssessmentQuestion4> {
  int selectedIndex = 0;
  final options = [
    {'title': 'Creative and innovative', 'tags': ['Innovation', 'Creative Thinking']},
    {'title': 'Research-based approach', 'tags': ['Research', 'Structured Thinking']},
    {'title': 'Systematic and methodical', 'tags': ['Analytical', 'Critical Thinking']},
    {'title': 'Hands-on and practical', 'tags': ['Practical', 'Execution']},
  ];
  @override
  Widget build(BuildContext context) => _buildScaffold(
    context, 'Assessment - Question 4', 'How do you approach problem\nsolving?', 4, options,
    selectedIndex, (i) => setState(() => selectedIndex = i),
        () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AssessmentQuestion5(prevAnswers: [...widget.prevAnswers, selectedIndex]))),
    'Next Question',
  );
}

class AssessmentQuestion5 extends StatefulWidget {
  final List<int> prevAnswers;
  const AssessmentQuestion5({super.key, required this.prevAnswers});
  @override
  State<AssessmentQuestion5> createState() => _AssessmentQuestion5State();
}
class _AssessmentQuestion5State extends State<AssessmentQuestion5> {
  int selectedIndex = 0;
  final options = [
    {'title': 'Making a positive impact', 'tags': ['Purpose-driven', 'Impact']},
    {'title': 'Stability and security', 'tags': ['Reliability', 'Consistency']},
    {'title': 'Creating new solutions', 'tags': ['Innovation', 'Entrepreneurship']},
    {'title': 'Learning and growth', 'tags': ['Growth Mindset', 'Learning']},
  ];
  @override
  Widget build(BuildContext context) => _buildScaffold(
    context, 'Assessment - Question 5', 'What motivates you in your\ncareer?', 5, options,
    selectedIndex, (i) => setState(() => selectedIndex = i),
        () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AssessmentCompleteState(answers: [...widget.prevAnswers, selectedIndex]))),
    'Complete Assessment',
  );
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(40)),
              child: const Icon(Icons.check_circle_outline, color: Color(0xFF1D5572), size: 50),
            ),
            const SizedBox(height: 20),
            Text('Assessment Complete!', style: GoogleFonts.inter(fontSize: 25, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text("We've identified your key strengths and skills", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CareerMatchesScreen(answers: answers))),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A100), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text('View Career Matches', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF001636))),
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
            Text('Career Matches', style: GoogleFonts.inter(fontSize: 25, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text('Recommendations based on your skills', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
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
        boxShadow: const [BoxShadow(color: Color(0x1E000000), spreadRadius: 0, offset: Offset(0, 2), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(career.title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text('${career.matchPercent}% Match', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
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
          Text(career.description, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
          const SizedBox(height: 12),
          Text('Key Skills:', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: career.skills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: const Color(0xFFE9D5FF)),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(skill, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFFF5A100))),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D5572), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  child: Text('View Roadmap', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD9D9D9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  child: Text('Learn More', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1D5572))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== SHARED WIDGETS =====
Widget _buildScaffold(BuildContext context, String title, String question, int questionNum,
    List<Map<String, dynamic>> options, int selectedIndex, Function(int) onSelect,
    VoidCallback onNext, String buttonText) {
  return Scaffold(
    backgroundColor: const Color(0xFFF9FAFB),
    appBar: AppBar(
      backgroundColor: const Color(0xFF1D5572),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.chevron_left, size: 18, color: Color(0xFF6B7280)),
                  Text('Question $questionNum of 5',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: questionNum / 5,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D5572)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 20),
                Text(question, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937), height: 1.4)),
                const SizedBox(height: 20),
                ...List.generate(options.length, (index) {
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () => onSelect(index),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: isSelected ? const Color(0xFFF5A100) : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22, height: 22,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFFF5A100) : Colors.transparent,
                              border: Border.all(color: isSelected ? const Color(0xFFF5A100) : const Color(0xFFD1D5DB), width: 2),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(options[index]['title'], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1F2937))),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: (options[index]['tags'] as List<String>).map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
                                    child: Text(tag, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                                  )).toList(),
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A100), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(buttonText, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF001636))),
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: _buildBottomNav(1),
  );
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
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'assess'),
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}