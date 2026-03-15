import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../services/profile_service.dart';
import 'assessment_flow.dart';
import 'student_homescreen.dart';
import 'auth/login_screen.dart';
import 'Notifications screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  List<String> _parseSkills(dynamic raw) {
    if (raw is List) {
      return raw.map((s) {
        if (s is String) return s;
        if (s is Map) {
          final map = Map<String, dynamic>.from(s);
          return map['name']?.toString() ??
              map['skill']?.toString() ??
              map['title']?.toString() ??
              s.toString();
        }
        return s.toString();
      }).where((s) => s.trim().isNotEmpty).toList();
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

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

  Future<void> _pickAndUploadImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 50, 
      );

      if (pickedFile != null) {
        // Convert image to Base64 string
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        final imageUri = 'data:image/jpeg;base64,$base64Image';

        authProvider.setLoading(true);
        
        // Send to backend
        final response = await ProfileService.updateProfile(
          token: token,
          updates: {'profilePhoto': imageUri},
        );

        if (response['success'] == true) {
          authProvider.updateUser(response['data']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated successfully!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Failed to upload photo')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      authProvider.setLoading(false);
    }
  }

  ImageProvider _getProfileImage(String? photoData) {
    if (photoData != null && photoData.startsWith('data:image')) {
      try {
        final base64Str = photoData.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return const AssetImage('assets/images/logo.png');
      }
    }
    return const AssetImage('assets/images/logo.png'); 
  }

  void _showAddSkillDialog() {
    final TextEditingController skillController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Skill'),
          content: TextField(
            controller: skillController,
            decoration: const InputDecoration(hintText: 'Skill name (e.g. Flutter, Dart)'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final skill = skillController.text.trim();
                if (skill.isNotEmpty) {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final currentSkills = _parseSkills(authProvider.user?['skills']);
                  final exists = currentSkills.any((s) => s.toLowerCase() == skill.toLowerCase());
                  if (!exists) {
                    currentSkills.add(skill);
                    final success = await _updateSkillsOnServer(currentSkills);
                    if (success && mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _updateSkillsOnServer(List<String> newSkills) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return false;

    try {
      final response = await ProfileService.updateProfile(
        token: token,
        updates: {'skills': newSkills},
      );
      if (response['success'] == true) {
        final currentUser = Map<String, dynamic>.from(authProvider.user ?? {});
        Map<String, dynamic>? updatedUser;
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          final userData = data['user'];
          if (userData is Map<String, dynamic>) {
            updatedUser = Map<String, dynamic>.from(currentUser)..addAll(userData);
          } else {
            updatedUser = Map<String, dynamic>.from(currentUser)..addAll(data);
          }
        }
        updatedUser ??= Map<String, dynamic>.from(currentUser);
        updatedUser['skills'] = newSkills;
        authProvider.updateUser(updatedUser);
        return true;
      } else {
        final message = response['message']?.toString() ?? '';
        final lower = message.toLowerCase();
        final isProfileEndpointBroken =
            lower.contains('updateprofile is not a function') ||
            lower.contains('profileservice.updateprofile');

        if (isProfileEndpointBroken) {
          final currentUser = Map<String, dynamic>.from(authProvider.user ?? {});
          final updatedUser = Map<String, dynamic>.from(currentUser)..['skills'] = newSkills;
          authProvider.updateUser(updatedUser);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved locally. Server profile update is unavailable.'),
              ),
            );
          }
          return true;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.isEmpty ? 'Failed to update skills' : message)),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final fullName = user?['fullName'] ?? 'User';
    final email = user?['email'] ?? 'No email';
    final role = user?['role'] ?? 'Member';
    final profilePhoto = user?['profilePhoto'] as String?;
    final isLoading = authProvider.isLoading;
    final skills = _parseSkills(user?['skills']);

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
                        GestureDetector(
                          onTap: isLoading ? null : _pickAndUploadImage,
                          child: Container(
                            width: 96, height: 96,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(48),
                              image: profilePhoto != null && profilePhoto.isNotEmpty
                                  ? DecorationImage(
                                      image: _getProfileImage(profilePhoto),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (profilePhoto == null || profilePhoto.isEmpty)
                                ? Center(
                                    child: isLoading 
                                      ? const CircularProgressIndicator()
                                      : Text(
                                          getInitials(fullName),
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF1D5572),
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            height: 0.9,
                                          ),
                                        ),
                                  )
                                : (isLoading ? const Center(child: CircularProgressIndicator(color: Colors.white)) : null),
                          ),
                        ),
                        Positioned(
                          right: 0, bottom: 0,
                          child: GestureDetector(
                            onTap: isLoading ? null : _pickAndUploadImage,
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: const Color(0xFF1D5572), borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName,
                      style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.toString().toUpperCase(),
                      style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Passionate about web development and eager to grow my career in tech. Love building user-friendly applications.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.1),
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
                _infoRow(Icons.email_outlined, email),
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
                    GestureDetector(
                      onTap: _showAddSkillDialog,
                      child: const Icon(Icons.add, size: 20, color: Color(0xFF1D5572)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (skills.isEmpty)
                  Text(
                    'No skills added yet',
                    style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14, height: 1.1),
                  )
                else
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: skills.map((s) => _skillTag(s, filled: true)).toList(),
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
                _accountRow(Icons.notifications_outlined, 'Notifications', const Color(0xFF1F2937), const Color(0xFF6B7280), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                }),
                const Divider(),
                _accountRow(Icons.logout, 'Sign Out', const Color(0xFFDC2626), const Color(0xFFDC2626), () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    final navigator = Navigator.of(context);
                    await authProvider.logout();
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }),
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
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    _nameController = TextEditingController(text: user?['fullName'] ?? '');
    _roleController = TextEditingController(text: user?['role']?.toString().toUpperCase() ?? '');
    _bioController = TextEditingController(text: 'Passionate about web development and eager to grow my career in tech. Love building user-friendly applications.');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

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

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Not authenticated')),
      );
      return;
    }

    final newName = _nameController.text.trim();
    if (newName == authProvider.user?['fullName']) {
      Navigator.pop(context);
      return;
    }

    authProvider.setLoading(true);
    authProvider.setError(null);

    try {
      final response = await ProfileService.updateProfile(
        token: token,
        updates: {'fullName': newName},
      );

      if (response['success'] == true) {
        authProvider.updateUser(response['data']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        final errorMsg = response['message']?.toString() ?? 'Failed to update profile';
        authProvider.setError(errorMsg);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    } catch (e) {
      authProvider.setError(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      authProvider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

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
                              child: Center(child: Text(getInitials(_nameController.text), style: GoogleFonts.inter(color: const Color(0xFF1D5572), fontSize: 32, fontWeight: FontWeight.bold, height: 0.9))),
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
                      Center(child: Text(_nameController.text, style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold, height: 1.4))),
                      const SizedBox(height: 20),
                      _editLabel('Full Name'),
                      _editField(_nameController),
                      const SizedBox(height: 12),
                      _editLabel('Current Role'),
                      _editField(_roleController, enabled: false),
                      const SizedBox(height: 12),
                      _editLabel('Bio'),
                      _editField(_bioController, maxLines: 3),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: isLoading ? null : _saveProfile,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(color: const Color(0xFF1D5572), borderRadius: BorderRadius.circular(8)),
                                child: Center(
                                  child: isLoading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text('Save', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500))
                                ),
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

Widget _editField(TextEditingController controller, {int maxLines = 1, bool enabled = true}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? const Color(0xFFF3F4F6) : const Color(0xFFE5E7EB),
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
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()), (route) => false);
        }),
        _navItem(context, Icons.assignment_outlined, 'assess', currentIndex == 1, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentStartScreen()));
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
