import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // ✅ Add this import for URL launching
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/bottom_navigation.dart';
import '../auth/login_screen.dart';
import 'assessment_flow.dart';
import 'student_homescreen.dart';
import 'report issue.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 20, top: 45, bottom: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Profile',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
          ),
        ],
      ),
    );
  }

  final Map<String, String> _availableInterests = {
    'web': 'Web Development',
    'data_ai': 'Data / AI',
    'security': 'Security',
    'design': 'Design',
    'product': 'Product',
    'devops': 'DevOps',
    'qa': 'QA / Testing',
    'mobile_game': 'Mobile / Game',
  };

  List<String> _parseSkills(dynamic raw) {
    if (raw is List) {
      return raw
          .map((s) {
            if (s is String) return s;
            if (s is Map) {
              final map = Map<String, dynamic>.from(s);
              return map['name']?.toString() ??
                  map['skill']?.toString() ??
                  map['title']?.toString() ??
                  s.toString();
            }
            return s.toString();
          })
          .where((s) => s.trim().isNotEmpty)
          .toList();
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

  String _formatJoinDate(dynamic createdAt) {
    if (createdAt == null) return 'Join date unknown';
    try {
      final dt = DateTime.parse(createdAt.toString());
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return 'Joined ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'Join date unknown';
    }
  }

  String? _getLinkedInUrl(Map<String, dynamic>? user) {
    final rawUrl = user?['linkedinUrl'] ?? user?['linkedInUrl'];
    if (rawUrl == null) return null;

    final trimmed = rawUrl.toString().trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  Future<void> _launchLinkedIn(String? rawUrl) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No LinkedIn URL found for this user')),
        );
      }
      return;
    }

    final Uri linkedInUrl = Uri.parse(rawUrl);
    if (await canLaunchUrl(linkedInUrl)) {
      await launchUrl(linkedInUrl, mode: LaunchMode.externalApplication);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch LinkedIn')),
      );
    }
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
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        final imageUri = 'data:image/jpeg;base64,$base64Image';

        authProvider.setLoading(true);

        final response = await ProfileService.updateProfile(
          token: token,
          updates: {'profileImageUrl': imageUri},
        );

        if (response['success'] == true) {
          authProvider.updateUser(response['data']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profile photo updated successfully!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(response['message'] ?? 'Failed to upload photo')),
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
            decoration: const InputDecoration(
                hintText: 'Skill name (e.g. Flutter, Dart)'),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final skill = skillController.text.trim();
                if (skill.isNotEmpty) {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  final currentSkills =
                      _parseSkills(authProvider.user?['skills']);
                  final exists = currentSkills
                      .any((s) => s.toLowerCase() == skill.toLowerCase());
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

  void _showCareerInterestsDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final List<String> currentInterests =
        _parseSkills(authProvider.user?['selectedInterests']);

    List<String> tempSelected = List.from(currentInterests);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Career Interests'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _availableInterests.entries.map((entry) {
                    final bool isSelected = tempSelected.contains(entry.key);
                    return CheckboxListTile(
                      title: Text(entry.value),
                      value: isSelected,
                      activeColor: const Color(0xFF1D5572),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            if (tempSelected.length < 3) {
                              tempSelected.add(entry.key);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Select up to 3 interests'),
                                    duration: Duration(seconds: 1)),
                              );
                            }
                          } else {
                            tempSelected.remove(entry.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateInterestsOnServer(tempSelected);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _updateInterestsOnServer(List<String> newInterests) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return false;

    authProvider.setLoading(true);

    try {
      final response = await ProfileService.updateProfile(
        token: token,
        updates: {'selectedInterests': newInterests},
      );

      if (response['success'] == true) {
        final currentUser = Map<String, dynamic>.from(authProvider.user ?? {});
        Map<String, dynamic>? updatedUser;
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          final userData = data['user'];
          if (userData is Map<String, dynamic>) {
            updatedUser = Map<String, dynamic>.from(currentUser)
              ..addAll(userData);
          } else {
            updatedUser = Map<String, dynamic>.from(currentUser)..addAll(data);
          }
        }
        updatedUser ??= Map<String, dynamic>.from(currentUser);
        updatedUser['selectedInterests'] = newInterests;
        authProvider.updateUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interests updated successfully')),
          );
        }
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    response['message']?.toString() ?? 'Failed to update')),
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
    } finally {
      authProvider.setLoading(false);
    }
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
            updatedUser = Map<String, dynamic>.from(currentUser)
              ..addAll(userData);
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
          final currentUser =
              Map<String, dynamic>.from(authProvider.user ?? {});
          final updatedUser = Map<String, dynamic>.from(currentUser)
            ..['skills'] = newSkills;
          authProvider.updateUser(updatedUser);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Saved locally. Server profile update is unavailable.'),
              ),
            );
          }
          return true;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    message.isEmpty ? 'Failed to update skills' : message)),
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
    final profilePhoto = user?['profileImageUrl'] as String?;
    final isLoading = authProvider.isLoading;
    final skills = _parseSkills(user?['skills']);
    final linkedInUrl = _getLinkedInUrl(user);

    return Scaffold(
      backgroundColor: const Color(0xFF1D5572),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                              Stack(
                                children: [
                                  GestureDetector(
                                    onTap:
                                        isLoading ? null : _pickAndUploadImage,
                                    child: Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(48),
                                        image: profilePhoto != null &&
                                                profilePhoto.isNotEmpty
                                            ? DecorationImage(
                                                image: _getProfileImage(
                                                    profilePhoto),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: (profilePhoto == null ||
                                              profilePhoto.isEmpty)
                                          ? Center(
                                              child: isLoading
                                                  ? const CircularProgressIndicator()
                                                  : Text(
                                                      getInitials(fullName),
                                                      style: GoogleFonts.inter(
                                                        color: const Color(
                                                            0xFF1D5572),
                                                        fontSize: 32,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        height: 0.9,
                                                      ),
                                                    ),
                                            )
                                          : (isLoading
                                              ? const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: Colors.white))
                                              : null),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: GestureDetector(
                                      onTap: isLoading
                                          ? null
                                          : _pickAndUploadImage,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF1D5572),
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        child: const Icon(Icons.camera_alt,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
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
                                role.toString().toUpperCase(),
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 14,
                                    height: 1.1),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  (user?['bio'] != null &&
                                          (user!['bio'] as String).isNotEmpty)
                                      ? user['bio'] as String
                                      : 'No bio added yet',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 14,
                                      height: 1.1),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const EditProfileScreen()));
                                },
                                child: Container(
                                  width: 124,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset('assets/images/Edits.png',
                                          width: 14, height: 14),
                                      const SizedBox(width: 4),
                                      Text('Edit Profile',
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFF6B7280),
                                              fontSize: 14,
                                              height: 1.1)),
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
                          _infoRow(Icons.email, email),
                          _infoRow(
                            'assets/images/linkedin.png',
                            linkedInUrl ?? 'No LinkedIn URL provided',
                            onTap: () => _launchLinkedIn(linkedInUrl),
                            isLinkedIn: linkedInUrl != null,
                          ),
                          _infoRow(Icons.calendar_today,
                              _formatJoinDate(user?['createdAt'])),
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
                                child: const Icon(Icons.add,
                                    size: 20, color: Color(0xFF1D5572)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (skills.isEmpty)
                            Text(
                              'No skills added yet',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 14,
                                  height: 1.1),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skills
                                  .map((s) => _skillTag(s, filled: true))
                                  .toList(),
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
                              GestureDetector(
                                onTap: _showCareerInterestsDialog,
                                child: const Icon(Icons.add,
                                    size: 20, color: Color(0xFF1D5572)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Builder(builder: (_) {
                            final rawInterests =
                                _parseSkills(user?['selectedInterests']);
                            if (rawInterests.isEmpty) {
                              return Text('No career interests added yet',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF6B7280),
                                      fontSize: 14,
                                      height: 1.1));
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: rawInterests.map((key) {
                                final label = _availableInterests[key] ?? key;
                                return _skillTag(label, filled: false);
                              }).toList(),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Recent Achievements
                      _buildCard(
                        children: [
                          _sectionTitle('Recent Achievements'),
                          const SizedBox(height: 12),
                          _achievementRow(Icons.emoji_events,
                              'Completed React Roadmap', 'Feb 2026'),
                          const Divider(),
                          _achievementRow(
                              Icons.people, 'First Mentor Session', 'Feb 2026'),
                          const Divider(),
                          _achievementRow(Icons.assignment_turned_in,
                              'Skill Assessment Complete', 'Jan 2026'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Account
                      _buildCard(
                        children: [
                          _sectionTitle('Account'),
                          const SizedBox(height: 12),
                          _accountRow(
                            Icons.settings_outlined,
                            'Settings & Privacy',
                            const Color(0xFF1F2937),
                            const Color(0xFF6B7280),
                            () {},
                          ),
                          const Divider(),
                          // ✅ Report an Issue
                          _accountRow(
                            Icons.flag_outlined,
                            'Report an Issue',
                            const Color(0xFF1F2937),
                            const Color(0xFF6B7280),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ReportIssueScreen()),
                              );
                            },
                          ),
                          const Divider(),
                          _accountRow(
                            Icons.logout,
                            'Sign Out',
                            const Color(0xFFDC2626),
                            const Color(0xFFDC2626),
                            () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Sign Out'),
                                  content: const Text(
                                      'Are you sure you want to sign out?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFDC2626)),
                                      child: const Text('Sign Out'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                final navigator = Navigator.of(context);
                                await authProvider.logout();
                                navigator.pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.profile),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 20, top: 40, bottom: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Edit Profile',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    _nameController = TextEditingController(text: user?['fullName'] ?? '');
    _roleController = TextEditingController(
        text: user?['role']?.toString().toUpperCase() ?? '');
    _bioController = TextEditingController(text: user?['bio'] ?? '');
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
    final newBio = _bioController.text.trim();
    if (newName == authProvider.user?['fullName'] &&
        newBio == (authProvider.user?['bio'] ?? '')) {
      Navigator.pop(context);
      return;
    }

    authProvider.setLoading(true);
    authProvider.setError(null);

    try {
      final response = await ProfileService.updateProfile(
        token: token,
        updates: {'fullName': newName, 'bio': newBio},
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
        final errorMsg =
            response['message']?.toString() ?? 'Failed to update profile';
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
      backgroundColor: const Color(0xFF1D5572),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                color: const Color(0xFFF9FAFB),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
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
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFF3E8FF),
                                            borderRadius:
                                                BorderRadius.circular(48)),
                                        child: Center(
                                            child: Text(
                                                getInitials(
                                                    _nameController.text),
                                                style: GoogleFonts.inter(
                                                    color:
                                                        const Color(0xFF1D5572),
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    height: 0.9))),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                              color: const Color(0xFF1D5572),
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          child: const Icon(Icons.camera_alt,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                    child: Text(_nameController.text,
                                        style: GoogleFonts.inter(
                                            color: const Color(0xFF1F2937),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            height: 1.4))),
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
                                          decoration: BoxDecoration(
                                              color: const Color(0xFF1D5572),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Center(
                                            child: isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2))
                                                : Text('Save',
                                                    style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w500)),
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
                                          decoration: BoxDecoration(
                                              color: const Color(0xFF1D5572),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Center(
                                              child: Text('Cancel',
                                                  style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500))),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.profile),
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

Widget _infoRow(dynamic icon, String text,
    {VoidCallback? onTap, bool isLinkedIn = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: isLinkedIn ? onTap : null,
      child: Row(children: [
        if (icon is IconData)
          Icon(icon, size: 16, color: const Color(0xFF1D5572))
        else if (icon is String)
          Image.asset(icon, width: 16, height: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: isLinkedIn
                  ? const Color(0xFF0077B5)
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
    ),
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
    child: Text(label,
        style: GoogleFonts.inter(
            color: filled ? Colors.white : const Color(0xFF1D5572),
            fontSize: 12,
            height: 1.4)),
  );
}

Widget _achievementRow(IconData icon, String title, String date) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: const Color(0xFFF5A100),
            borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.1)),
        Text(date,
            style: GoogleFonts.inter(
                color: const Color(0xFF1F2937), fontSize: 12, height: 1.3)),
      ]),
    ]),
  );
}

Widget _accountRow(IconData icon, String title, Color titleColor,
    Color iconColor, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Text(title,
            style: GoogleFonts.inter(
                color: titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.1)),
      ]),
    ),
  );
}

Widget _editLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(label,
        style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.2)),
  );
}

Widget _editField(TextEditingController controller,
    {int maxLines = 1, bool enabled = true}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? const Color(0xFFF3F4F6) : const Color(0xFFE5E7EB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF9CA3AF))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontSize: 15),
    ),
  );
}
