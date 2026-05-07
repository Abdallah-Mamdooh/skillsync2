import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/mentor_service.dart';
import '../../models/chat_models.dart';
import '../../widgets/bottom_navigation.dart';
import 'mentor_chatscreen.dart';

class UserOverviewScreen extends StatelessWidget {
  final String sessionId;
  const UserOverviewScreen({super.key, required this.sessionId});

  String getInitials(String name) {
    if (name.isEmpty) return '??';
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '??';
  }

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token;
    return FutureBuilder<Map<String, dynamic>>(
      future: token == null
          ? Future.value({'success': false, 'message': 'Not authenticated'})
          : MentorService.getSessionById(token, sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final response = snapshot.data!;
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : <String, dynamic>{};
        final user = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : <String, dynamic>{};
        final fullName = (user['fullName'] ?? 'Student').toString();
        final role = (user['role'] ?? 'Learner').toString();
        final email = (user['email'] ?? 'N/A').toString();
        final linkedIn = (user['linkedinUrl'] ?? 'Not provided').toString();
        final joinedDate = user['createdAt'] != null
            ? 'Joined ${DateTime.tryParse(user['createdAt'].toString())?.year ?? ''}'
            : 'Joined recently';
        final bio = (user['additionalInfo'] ??
                'User profile details are limited in current payload.')
            .toString();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF1D5572),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'User Overview',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x3F000000),
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                        blurRadius: 12)
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(48),
                      ),
                      child: Center(
                        child: Text(
                          getInitials(fullName),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1D5572),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 0.9,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName,
                      style: GoogleFonts.inter(
                          color: const Color(0xFF1F2937),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.toUpperCase(),
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 14,
                          height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            height: 1.1),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Contact Information
            _buildCard(
              children: [
                _sectionTitle('Contact Information'),
                const SizedBox(height: 12),
                _infoRow(Icons.email, email),
                _infoRow(Icons.link, linkedIn, isLinkedIn: true),
                _infoRow(Icons.calendar_today, joinedDate),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                _sectionTitle('Session Details'),
                const SizedBox(height: 12),
                _infoRow(Icons.timelapse, 'Duration: ${(data['durationMinutes'] ?? 0)} min'),
                _infoRow(Icons.chat, 'Type: ${(data['method'] ?? 'chat').toString().toUpperCase()}'),
                _infoRow(Icons.schedule, 'Start: ${(data['scheduledStartTime'] ?? '').toString()}'),
              ],
            ),
            const SizedBox(height: 24),
            // Go To Session Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MentorChatScreen(
                          user: ChatUser(
                            sessionId: sessionId,
                            name: fullName,
                            isOnline: true,
                            status: (data['status'] ?? 'started').toString(),
                            sessionDuration:
                                '${(data['durationMinutes'] ?? 0).toString()} min',
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5572),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Go To Session',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const MentorBottomNavigation(selectedIndex: MentorBottomNavIndex.none),
            const SizedBox(height: 20),
          ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x3F000000),
                spreadRadius: 0,
                offset: Offset(0, 4),
                blurRadius: 12)
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 0.9));
  }

  Widget _infoRow(IconData icon, String text, {bool isLinkedIn = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF1D5572)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: isLinkedIn
                  ? const Color(0xFF1D5572)
                  : const Color(0xFF1F2937),
              fontSize: 14,
              height: 1.1,
              decoration: isLinkedIn ? TextDecoration.underline : null,
            ),
          ),
        ),
        if (isLinkedIn)
          const Icon(Icons.open_in_new, size: 14, color: Color(0xFF1D5572)),
      ]),
    );
  }

}
