import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assessment_flow.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 71),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profile',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F2937),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
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
                  boxShadow: const [BoxShadow(color: Color(0x3F000000), spreadRadius: 0, offset: Offset(0, 4), blurRadius: 12)],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    Stack(
                      children: [
                        Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(48)),
                          child: Center(
                            child: Text('AM', style: GoogleFonts.inter(color: const Color(0xFF1D5572), fontSize: 32, fontWeight: FontWeight.bold, height: 0.9)),
                          ),
                        ),
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: const Color(0xFF1D5572), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Abdallah Mamdooh', style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold, height: 1.4)),
                    const SizedBox(height: 4),
                    Text('Junior Developer', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14, height: 1.1)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Passionate about web development and eager to grow my career in tech. Love building user-friendly applications.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14, height: 1.1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      },
                      child: Container(
                        width: 124, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit, size: 13, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text('Edit Profile', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14, height: 1.1)),
                          ],
                        ),
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
                _infoRow(Icons.email_outlined, 'Abdallahmamdooh17@gmail.com'),
                _infoRow(Icons.school_outlined, 'Computer Science, SAMS University'),
                _infoRow(Icons.calendar_today_outlined, 'Joined January 2026'),
              ],
            ),
            const SizedBox(height: 16),
            // Skills
            _buildCard(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('Skills'),
                    const Icon(Icons.add, size: 15, color: Color(0xFF1D5572)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['JavaScript', 'React', 'Node.js', 'Python', 'Git', 'HTML/CSS', 'Problem Solving', 'Team Collaboration']
                      .map((s) => _skillTag(s, filled: true)).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Career Interests
            _buildCard(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('Career Interests'),
                    const Icon(Icons.add, size: 15, color: Color(0xFF1D5572)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['Web Development', 'Data Science', 'Cloud Computing', 'UX Design']
                      .map((s) => _skillTag(s, filled: false)).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Recent Achievements
            _buildCard(
              children: [
                _sectionTitle('Recent Achievements'),
                const SizedBox(height: 12),
                _achievementRow(Icons.emoji_events, 'Completed React Roadmap', 'Feb 2026'),
                const Divider(),
                _achievementRow(Icons.people, 'First Mentor Session', 'Feb 2026'),
                const Divider(),
                _achievementRow(Icons.assignment_turned_in, 'Skill Assessment Complete', 'Jan 2026'),
              ],
            ),
            const SizedBox(height: 16),
            // Account
            _buildCard(
              children: [
                _sectionTitle('Account'),
                const SizedBox(height: 12),
                _accountRow(Icons.settings_outlined, 'Settings & Privacy', const Color(0xFF1F2937), const Color(0xFF6B7280), () {}),
                const Divider(),
                _accountRow(Icons.notifications_outlined, 'Notifications', const Color(0xFF1F2937), const Color(0xFF6B7280), () {}),
                const Divider(),
                _accountRow(Icons.logout, 'SignOut', const Color(0xFFDC2626), const Color(0xFFDC2626), () {}),
              ],
            ),
            const SizedBox(height: 20),
            // Bottom Nav
            _buildBottomNav(context, 3),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ===== EDIT PROFILE SCREEN =====
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Abdallah Mamdooh');
  final _roleController = TextEditingController(text: 'Junior Developer');
  final _bioController = TextEditingController(text: 'Passionate about web development and eager to grow my career in tech. Love building user-friendly applications.');

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 71),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Edit Profile', style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 25, fontWeight: FontWeight.bold, height: 1.1)),
              ),
            ),
            const SizedBox(height: 16),
            // Edit Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x3F000000), spreadRadius: 0, offset: Offset(0, 4), blurRadius: 12)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(48)),
                              child: Center(child: Text('AM', style: GoogleFonts.inter(color: const Color(0xFF1D5572), fontSize: 32, fontWeight: FontWeight.bold, height: 0.9))),
                            ),
                            Positioned(
                              right: 0, bottom: 0,
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: const Color(0xFF1D5572), borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(child: Text('Abdallah Mamdooh', style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold, height: 1.4))),
                      const SizedBox(height: 20),
                      _editLabel('Full Name'),
                      _editField(_nameController),
                      const SizedBox(height: 12),
                      _editLabel('Current Role'),
                      _editField(_roleController),
                      const SizedBox(height: 12),
                      _editLabel('Bio'),
                      _editField(_bioController, maxLines: 3),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(color: const Color(0xFF1D5572), borderRadius: BorderRadius.circular(8)),
                                child: Center(child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(color: const Color(0xFF1D5572), borderRadius: BorderRadius.circular(8)),
                                child: Center(child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Contact Information
            _buildCard(
              children: [
                _sectionTitle('Contact Information'),
                const SizedBox(height: 12),
                _infoRow(Icons.email_outlined, 'Abdallahmamdooh17@gmail.com'),
                _infoRow(Icons.school_outlined, 'Computer Science, SAMS University'),
                _infoRow(Icons.calendar_today_outlined, 'Joined January 2026'),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_sectionTitle('Skills'), const Icon(Icons.add, size: 15, color: Color(0xFF1D5572))]),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: ['JavaScript', 'React', 'Node.js', 'Python', 'Git', 'HTML/CSS', 'Problem Solving', 'Team Collaboration'].map((s) => _skillTag(s, filled: true)).toList()),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_sectionTitle('Career Interests'), const Icon(Icons.add, size: 15, color: Color(0xFF1D5572))]),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: ['Web Development', 'Data Science', 'Cloud Computing', 'UX Design'].map((s) => _skillTag(s, filled: false)).toList()),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                _sectionTitle('Recent Achievements'),
                const SizedBox(height: 12),
                _achievementRow(Icons.emoji_events, 'Completed React Roadmap', 'Feb 2026'),
                const Divider(),
                _achievementRow(Icons.people, 'First Mentor Session', 'Feb 2026'),
                const Divider(),
                _achievementRow(Icons.assignment_turned_in, 'Skill Assessment Complete', 'Jan 2026'),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              children: [
                _sectionTitle('Account'),
                const SizedBox(height: 12),
                _accountRow(Icons.settings_outlined, 'Settings & Privacy', const Color(0xFF1F2937), const Color(0xFF6B7280), () {}),
                const Divider(),
                _accountRow(Icons.notifications_outlined, 'Notifications', const Color(0xFF1F2937), const Color(0xFF6B7280), () {}),
                const Divider(),
                _accountRow(Icons.logout, 'SignOut', const Color(0xFFDC2626), const Color(0xFFDC2626), () {}),
              ],
            ),
            const SizedBox(height: 20),
            _buildBottomNav(context, 3),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ===== SHARED HELPERS =====

Widget _buildCard({required List<Widget> children}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 26),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x3F000000), spreadRadius: 0, offset: Offset(0, 4), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    ),
  );
}

Widget _sectionTitle(String title) {
  return Text(title, style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.w600, height: 0.9));
}

Widget _infoRow(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 14, height: 1.1))),
    ]),
  );
}

Widget _skillTag(String label, {required bool filled}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: filled ? const Color(0xFFF5A100) : Colors.white,
      border: filled ? null : Border.all(color: const Color(0xFF1D5572)),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(label, style: GoogleFonts.inter(color: filled ? Colors.white : const Color(0xFF1D5572), fontSize: 12, height: 1.4)),
  );
}

Widget _achievementRow(IconData icon, String title, String date) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: const Color(0xFFF5A100), borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w500, height: 1.1)),
        Text(date, style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 12, height: 1.3)),
      ]),
    ]),
  );
}

Widget _accountRow(IconData icon, String title, Color titleColor, Color iconColor, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.inter(color: titleColor, fontSize: 14, fontWeight: FontWeight.w500, height: 1.1)),
      ]),
    ),
  );
}

Widget _editLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(label, style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 13, fontWeight: FontWeight.w600, height: 1.2)),
  );
}

Widget _editField(TextEditingController controller, {int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF9CA3AF))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 15),
    ),
  );
}

Widget _buildBottomNav(BuildContext context, int currentIndex) {
  return Container(
    width: double.infinity,
    height: 80,
    decoration: const BoxDecoration(
      color: Color(0xFF1D5572),
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navItem(context, Icons.home_outlined, 'Home', currentIndex == 0, () {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
        }),
        _navItem(context, Icons.assignment_outlined, 'assess', currentIndex == 1, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentStartState()));
        }),
        _navItem(context, Icons.chat_bubble_outline, 'Chat', currentIndex == 2, () {}),
        _navItem(context, Icons.person, 'Profile', currentIndex == 3, () {}),
      ],
    ),
  );
}

Widget _navItem(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
      ],
    ),
  );
}
