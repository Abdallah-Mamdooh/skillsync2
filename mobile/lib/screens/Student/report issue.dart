import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String? _selectedIssueType;
  bool _isDropdownOpen = false;
  final TextEditingController _descriptionController = TextEditingController();
  File? _attachedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  final List<String> _issueTypes = [
    'Mentor did not attend session',
    'Technical or connection issue',
    'Unsatisfied with service quality',
    'Payment or billing problem',
    'Mentor was late',
    'Audio/video quality issue',
    'Other issue',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _attachedImage = File(file.path);
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (_selectedIssueType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue type')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the problem')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: connect to backend
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint submitted successfully!'),
          backgroundColor: Color(0xFF1D5572),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 55),

            // Back + Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios,
                        size: 16, color: Color(0xFF1D5572)),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1D5572),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Report an Issue',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "We're here to help resolve your concern",
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // How it works info box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF3B82F6), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How it works:',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1E3A5F),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'If you have a payment issue, submit your complaint and our support team will investigate within 24-48 hours. If eligible, you\'ll get a full refund to your wallet within 3-5 business days.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1E3A5F),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Issue Details Card
            _buildSectionCard(
              title: 'Issue Details',
              children: [
                _fieldLabel('Type of Issue *'),
                const SizedBox(height: 8),
                // Custom inline dropdown
                GestureDetector(
                  onTap: () =>
                      setState(() => _isDropdownOpen = !_isDropdownOpen),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: _isDropdownOpen
                            ? const Color(0xFF1D5572)
                            : const Color(0xFFD1D5DB),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(8),
                        topRight: const Radius.circular(8),
                        bottomLeft: Radius.circular(_isDropdownOpen ? 0 : 8),
                        bottomRight: Radius.circular(_isDropdownOpen ? 0 : 8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedIssueType ?? 'Select issue category',
                          style: GoogleFonts.inter(
                            color: _selectedIssueType != null
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isDropdownOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down,
                              color: Color(0xFF6B7280), size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                // Dropdown list (opens inline inside card)
                if (_isDropdownOpen)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF1D5572)),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _issueTypes.map((type) {
                        final isSelected = _selectedIssueType == type;
                        final isLast = type == _issueTypes.last;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedIssueType = type;
                            _isDropdownOpen = false;
                          }),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 13),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF0F7FF)
                                  : Colors.white,
                              borderRadius: isLast
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                    )
                                  : null,
                              border: isLast
                                  ? null
                                  : const Border(
                                      bottom:
                                          BorderSide(color: Color(0xFFF3F4F6))),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.inter(
                                color: isSelected
                                    ? const Color(0xFF1D5572)
                                    : const Color(0xFF1F2937),
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 16),

                _fieldLabel('Describe the Problem *'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Please provide details about the issue...',
                    hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1D5572)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937), fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Attachments Card
            _buildSectionCard(
              title: 'Attachments (Optional)',
              children: [
                Text(
                  'Upload screenshots or other evidence to support your complaint.',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.4),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickScreenshot,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _attachedImage != null
                        ? Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(_attachedImage!,
                                    height: 100, fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to change',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 12),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.upload_outlined,
                                  color: Color(0xFF6B7280), size: 24),
                              const SizedBox(height: 6),
                              Text(
                                'Upload Screenshot',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1D5572),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Refund Policy Card
            _buildSectionCard(
              title: 'Refund Policy',
              children: [
                // Eligible box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You May Be Eligible For A Refund In The Following Cases:',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF166534),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...[
                        'The session did not start.',
                        'The session was interrupted or not completed.',
                        'You were unable to join due to a system issue.',
                        'Users must submit a complaint within 24-48 hours after the session ends.',
                        'If the issue is confirmed, the full amount will be refunded to the user\'s wallet.',
                        'No refunds will be issued for completed sessions without a valid reason.',
                        'Users are responsible for providing accurate details when submitting a complaint.',
                        'Repeated misuse of the refund system may result in account restrictions.',
                      ].map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: Color(0xFF16A34A), fontSize: 13)),
                              Expanded(
                                child: Text(
                                  point,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF166534),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Non-refundable box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Non-Refundable Cases:',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF991B1B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...[
                        'If you did not attend the session.',
                        'If you left the session voluntarily before it ended.',
                        'If the issue was caused by your own internet connection or device.',
                      ].map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: Color(0xFFDC2626), fontSize: 13)),
                              Expanded(
                                child: Text(
                                  point,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF991B1B),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _isSubmitting ? null : _submitComplaint,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D5572),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Submit Complaint',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000),
                spreadRadius: 0,
                offset: Offset(0, 2),
                blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: const Color(0xFF1F2937),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
