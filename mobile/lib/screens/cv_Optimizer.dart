import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CV Optimizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const CVOptimizerScreen(),
    );
  }
}

// First Screen - CV Upload Screen
class CVOptimizerScreen extends StatefulWidget {
  const CVOptimizerScreen({super.key});

  @override
  State<CVOptimizerScreen> createState() => _CVOptimizerScreenState();
}

class _CVOptimizerScreenState extends State<CVOptimizerScreen> {
  final TextEditingController _cvTextController = TextEditingController();
  String? _uploadedFileName;
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _cvTextController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
          _uploadedFileName = _pickedFile!.name;
        });

        if (_pickedFile!.bytes != null) {
          debugPrint('File size: ${_pickedFile!.bytes!.length} bytes');
        } else if (_pickedFile!.path != null) {
          debugPrint('File path: ${_pickedFile!.path}');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File uploaded: ${_pickedFile!.name}',
              style: const TextStyle(color: Color(0xFF1A3A5C)),
            ),
            backgroundColor: Colors.white,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error picking file. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _analyzeCV() {
    final text = _cvTextController.text;

    if (_pickedFile != null || text.isNotEmpty) {
      // Navigate to results screen
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CVResultsScreen(
            fileName: _pickedFile?.name,
            cvText: text.isNotEmpty ? text : null,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a file or paste text first'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Row(
                children: [
                   IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1A3A5C)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'CV Optimizer',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'resume analysis and optimization',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upload Icon + Title
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5E7EB),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/cv upload logo.png',
                                    width: 70,
                                    height: 78,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.upload_rounded,
                                      color: Color(0xFF7C5CBF),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Upload Your CV',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3A5C),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Get instant AI-powered feedback\nand optimization suggestions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1F2937),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Upload File Label
                        const Text(
                          'Upload File (PDF, DOC)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3A5C),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Dashed Upload Box
                        GestureDetector(
                          onTap: _pickFile,
                          child: DashedBorderBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/cv upload logo.png',
                                  height: 40,
                                  color: _uploadedFileName != null
                                      ? const Color(0xFF1A3A5C)
                                      : const Color(0xFF9DB0C8),
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.upload_file,
                                    size: 40,
                                    color: _uploadedFileName != null
                                        ? const Color(0xFF1A3A5C)
                                        : const Color(0xFF9DB0C8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _uploadedFileName ?? 'PDF, DOC up to 10MB',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _uploadedFileName != null
                                        ? const Color(0xFF1A3A5C)
                                        : const Color(0xFF9DB0C8),
                                    fontWeight: _uploadedFileName != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Or divider
                        const Center(
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Paste CV Text Label
                        const Text(
                          'Paste Your CV Text',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3A5C),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Text Area
                        TextField(
                          controller: _cvTextController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: 'Paste your resume content here...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9DB0C8),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Analyze CV Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _analyzeCV,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5572),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/analyze cv logo.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Analyze CV',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(0),
    );
  }
}

// Second Screen - CV Results Screen
class CVResultsScreen extends StatelessWidget {
  final String? fileName;
  final String? cvText;

  const CVResultsScreen({
    super.key,
    this.fileName,
    this.cvText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4F3),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2E2A)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'CV Optimizer Score',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2E2A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'resume analysis and optimization',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7A9490),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // CV Score Card
                    _buildScoreCard(),
                    const SizedBox(height: 14),

                    // Strengths Card
                    _buildStrengthsCard(),
                    const SizedBox(height: 14),

                    // Suggested Improvements Card
                    _buildImprovementsCard(),
                    const SizedBox(height: 14),

                    // Keywords Analysis Card
                    _buildKeywordsCard(),
                    const SizedBox(height: 20),

                    // Action Buttons
                    _buildActionButtons(context),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CV Score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E2A),
                ),
              ),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: '72',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8A020),
                      ),
                    ),
                    TextSpan(
                      text: ' / 100',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7A9490),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Text(
            'Based on industry standards',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7A9490),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8EEE0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE8A020)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.trending_up, color: Color(0xFF2A7A6A), size: 16),
              SizedBox(width: 6),
              Text(
                'Good start! Follow suggestions to improve',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2A7A6A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsCard() {
    final strengths = [
      'Clear work experience section',
      'Relevant technical skills listed',
      'Education details well-structured',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Color(0xFF2A7A6A), size: 20),
              SizedBox(width: 8),
              Text(
                'Strengths',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...strengths.map((s) => _buildStrengthItem(s)).toList(),
        ],
      ),
    );
  }

  Widget _buildStrengthItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF2A7A6A), size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3A38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementsCard() {
    final improvements = [
      "Add quantifiable achievements\n(e.g., 'Increased sales by 30%')",
      'Include action verbs in descriptions',
      'Optimize for ATS (Applicant Tracking\nSystems)',
      'Add a professional summary section',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline, color: Color(0xFFE05C20), size: 20),
              SizedBox(width: 8),
              Text(
                'Suggested Improvements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...improvements.map((s) => _buildImprovementItem(s)).toList(),
        ],
      ),
    );
  }

  Widget _buildImprovementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, color: Color(0xFFE05C20), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3A38),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordsCard() {
    final presentKeywords = ['JavaScript', 'Team Leadership', 'React', 'Problem Solving'];
    final missingKeywords = ['TypeScript', 'Agile', 'Unit Testing', 'CI/CD'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF1D5572), size: 20),
              SizedBox(width: 8),
              Text(
                'Keywords Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E2A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Text(
            'Present Keywords:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2E2A),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presentKeywords
                .map((k) => _buildKeywordChip(k, isPresent: true))
                .toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Missing Keywords:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2E2A),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missingKeywords
                .map((k) => _buildKeywordChip(k, isPresent: false))
                .toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Consider adding these keywords if relevant to your experience',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordChip(String label, {required bool isPresent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPresent ? const Color(0xFFE6F4EF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent ? Colors.white : const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPresent) ...[
            const Icon(Icons.check_circle_outline, color: Color(0xFF2A7A6A), size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isPresent ? const Color(0xFF2A7A6A) : const Color(0xFFC2410C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming soon!'),
                  backgroundColor: Color(0xFF1D5572),
                ),
              );
            },
            icon: Image.asset(
              'assets/images/export button logo.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 20,
              ),
            ),
            label: const Text(
              'Export',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D5572),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate back to upload screen
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const CVOptimizerScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(-1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
                    (route) => false,
              );
            },
            icon: Image.asset(
              'assets/images/analyze cv logo.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 20,
              ),
            ),
            label: const Text(
              'Analyze New CV',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D5572),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// Bottom Navigation Bar Widget
Widget _buildBottomNav(int currentIndex) {
  return Container(
    decoration: const BoxDecoration(
      color: Color(0xFF1D5572),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(0),
        topRight: Radius.circular(0),
      ),
    ),
    child: BottomNavigationBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'assess',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}

/// A widget that paints a dashed border around its child.
class DashedBorderBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const DashedBorderBox({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.color = const Color(0xFFB0C4D8),
    this.strokeWidth = 1.5,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        borderRadius: borderRadius,
        color: color,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: Container(
        width: double.infinity,
        height: 110,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double borderRadius;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.borderRadius,
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(
          distance,
          distance + dashWidth,
        );
        dashedPath.addPath(extractPath, Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
