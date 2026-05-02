import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/bottom_navigation.dart';
import '../Mentor/Mentor homescreen.dart';
import '../Mentor/profile_screen.dart';

class ChatUser {
  final String sessionId;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final String date;
  final int unread;
  final String status;
  final bool isOnline;
  final String sessionDuration;

  const ChatUser({
    required this.sessionId,
    required this.name,
    this.avatarUrl = '',
    this.lastMessage = '',
    this.time = '',
    this.date = '',
    this.unread = 0,
    this.status = '',
    this.isOnline = false,
    this.sessionDuration = '',
  });

  factory ChatUser.fromSession(Map<String, dynamic> s) {
    final mentor = s['mentor'] is Map
        ? s['mentor']
        : (s['mentorId'] is Map ? s['mentorId'] : {});

    String formattedTime = '';
    String formattedDate = '';
    if (s['updatedAt'] != null) {
      try {
        final dt = DateTime.parse(s['updatedAt']).toLocal();
        formattedTime = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
        formattedDate = "${dt.day}/${dt.month}";
      } catch (_) {}
    }

    return ChatUser(
      sessionId: s['id'] ?? s['_id'] ?? '',
      // Normalized service includes id and _id.
      // Keep fallback for older payloads.
      name: mentor['fullName'] ?? 'Mentor',
      avatarUrl: mentor['profileImageUrl'] ?? '',
      lastMessage: s['lastMessage'] ?? '',
      status: s['status'] ?? 'scheduled',
      unread: s['unreadCount'] ?? 0,
      time: formattedTime,
      date: formattedDate,
      isOnline: mentor['isAvailable'] ?? false,
      sessionDuration: s['sessionDuration'] ?? '${s['durationMinutes'] ?? ''}',
    );
  }
}

class ChatAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;

  const ChatAvatar({
    super.key,
    this.url,
    required this.name,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      if (url!.startsWith('data:image')) {
        try {
          final base64Str = url!.split(',').last;
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(base64Decode(base64Str)),
          );
        } catch (_) {}
      } else if (url!.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(url!),
        );
      }
    }

    String initials = '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      initials = parts[0][0] + parts[parts.length - 1][0];
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0][0];
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD8DCF0),
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF1B2B4B),
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ChatBadge extends StatelessWidget {
  final int count;
  const ChatBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Color(0xFFF5A623),
        shape: BoxShape.circle,
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

enum ChatAttachmentType { none, image, file }

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final bool isRead;
  final String? filePath;       // local path for display
  final String? fileName;       // original file name
  final ChatAttachmentType attachmentType;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = false,
    this.filePath,
    this.fileName,
    this.attachmentType = ChatAttachmentType.none,
  });
}

class ChatWithMentorScreen extends StatefulWidget {
  final ChatUser user;
  const ChatWithMentorScreen({super.key, required this.user});

  @override
  State<ChatWithMentorScreen> createState() => _ChatWithMentorScreenState();
}

class _ChatWithMentorScreenState extends State<ChatWithMentorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String _sessionTimerLabel = '';

  @override
  void initState() {
    super.initState();
    if (widget.user.sessionId.isNotEmpty &&
        !widget.user.sessionId.startsWith('temp')) {
      _fetchMessages();
      _fetchSessionTimer();
    } else {
      _messages = [
        const ChatMessage(
          text: "Hi! I saw your profile and I'm interested in getting career guidance.",
          isMe: true,
          time: "10:30 AM",
          isRead: true,
        ),
        const ChatMessage(
          text:
          "Hello! I'd be happy to help you. What specific area would you like to focus on?",
          isMe: false,
          time: "10:32 AM",
        ),
      ];
    }
  }

  Future<void> _fetchSessionTimer() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null || widget.user.sessionId.isEmpty) return;
    final response = await ApiService.getSessionTimer(
      token: token,
      sessionId: widget.user.sessionId,
    );
    if (response['success'] == true && mounted) {
      final seconds = (response['data']?['remainingSessionSeconds'] ?? 0) as num;
      final mm = (seconds ~/ 60).toString().padLeft(2, '0');
      final ss = (seconds % 60).toString().padLeft(2, '0');
      setState(() => _sessionTimerLabel = '$mm:$ss');
    }
  }

  Future<void> _fetchMessages() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    setState(() => _isLoading = true);
    try {
      final response =
      await ChatService.getChatMessages(token, widget.user.sessionId);
      if (response['success'] == true) {
        final List msgs = response['data'] ?? [];
        setState(() {
          _messages = msgs.map((m) {
            final dt = DateTime.parse(m['createdAt']).toLocal();
            return ChatMessage(
              text: m['content'] ?? '',
              isMe: m['senderId'] == auth.user?['_id'],
              time: "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}",
              isRead: m['isRead'] ?? false,
            );
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    _controller.clear();
    final now = DateTime.now();
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isMe: true,
        time: "${now.hour}:${now.minute.toString().padLeft(2, '0')}",
        isRead: false,
      ));
    });

    _scrollToBottom();

    if (widget.user.sessionId.isNotEmpty &&
        !widget.user.sessionId.startsWith('temp')) {
      try {
        await ChatService.sendMessage(token, widget.user.sessionId, text);
      } catch (_) {}
    }
  }

  Future<void> _pickImage() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      final now = DateTime.now();
      setState(() => _isUploading = true);

      // Add optimistic message with local path
      setState(() {
        _messages.add(ChatMessage(
          text: '',
          isMe: true,
          time: "${now.hour}:${now.minute.toString().padLeft(2, '0')}",
          isRead: false,
          filePath: picked.path,
          fileName: picked.name,
          attachmentType: ChatAttachmentType.image,
        ));
      });
      _scrollToBottom();

      // Upload to backend if session is real
      if (widget.user.sessionId.isNotEmpty &&
          !widget.user.sessionId.startsWith('temp')) {
        try {
          await ChatService.sendFile(
            token,
            widget.user.sessionId,
            File(picked.path),
            picked.name,
          );
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Image error: \$e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickFile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;

      final pf = result.files.first;
      if (pf.path == null) return;

      final now = DateTime.now();
      setState(() => _isUploading = true);

      setState(() {
        _messages.add(ChatMessage(
          text: '',
          isMe: true,
          time: "${now.hour}:${now.minute.toString().padLeft(2, '0')}",
          isRead: false,
          filePath: pf.path,
          fileName: pf.name,
          attachmentType: ChatAttachmentType.file,
        ));
      });
      _scrollToBottom();

      if (widget.user.sessionId.isNotEmpty &&
          !widget.user.sessionId.startsWith('temp')) {
        try {
          await ChatService.sendFile(
            token,
            widget.user.sessionId,
            File(pf.path!),
            pf.name,
          );
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('File error: \$e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isMentor =
        auth.user?['role']?.toString().toLowerCase() == 'mentor';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: _messages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildDateChip("Today");
                final msg = _messages[index - 1];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          _buildInputBar(),
          if (!isMentor)
            const BottomNavigation(selectedIndex: BottomNavIndex.chat)
          else
            _buildMentorBottomNav(context, 2),
        ],
      ),
    );
  }

  /// ─── HEADER ──────────────────────────────────────────────────────────────
  /// [back] | Expanded col: [name ── avatar] / [full-width pill]
  Widget _buildHeader() {
    final duration = widget.user.sessionDuration.isNotEmpty
        ? widget.user.sessionDuration
        : (_sessionTimerLabel.isNotEmpty ? _sessionTimerLabel : "00:00");

    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1B2B4B)),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 4,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Expanded column owns BOTH the name+avatar row and the pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name and avatar on the same vertical level
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.user.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChatAvatar(
                      url: widget.user.avatarUrl,
                      name: widget.user.name,
                      radius: 24,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Pill stretches full width of this Expanded column
                _buildCombinedStatusPill(duration),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One full-width pill: ⏱ duration on the left, ● Online/Offline on the right
  Widget _buildCombinedStatusPill(String duration) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: clock + duration
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded,
                  color: Colors.white70, size: 13),
              const SizedBox(width: 5),
              Text(
                duration,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Right: dot + Online/Offline
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.user.isOnline
                      ? const Color(0xFF4CD080)
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.user.isOnline ? "Online" : "Offline",
                style: GoogleFonts.inter(
                  color: widget.user.isOnline
                      ? const Color(0xFF4CD080)
                      : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ─── DATE CHIP ───────────────────────────────────────────────────────────
  Widget _buildDateChip(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF8A8A9A),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// ─── MESSAGE BUBBLE ──────────────────────────────────────────────────────
  /// Time + read ticks are placed INSIDE the bubble, bottom-right aligned.
  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            ChatAvatar(
              url: widget.user.avatarUrl,
              name: widget.user.name,
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.only(
                left: 14,
                right: 14,
                top: 11,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1B2B4B) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Image attachment ──
                  if (msg.attachmentType == ChatAttachmentType.image &&
                      msg.filePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(msg.filePath!),
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),

                  // ── File attachment ──
                  if (msg.attachmentType == ChatAttachmentType.file &&
                      msg.filePath != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          color: isMe ? Colors.white70 : const Color(0xFF1B2B4B),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            msg.fileName ?? 'File',
                            style: GoogleFonts.inter(
                              color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  // ── Text (if any) ──
                  if (msg.text.isNotEmpty) ...[
                    if (msg.attachmentType != ChatAttachmentType.none)
                      const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        msg.text,
                        style: GoogleFonts.inter(
                          color: isMe
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 5),
                  // Time + ticks row, right-aligned inside bubble
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.time,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.6)
                              : const Color(0xFFAAAAAA),
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead ? Icons.done_all : Icons.done,
                          size: 15,
                          color: msg.isRead
                              ? const Color(0xFFF5A623)
                              : Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ─── INPUT BAR ───────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: _isUploading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.attach_file, color: Color(0xFF9090A0)),
            onPressed: _isUploading ? null : _pickFile,
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Color(0xFF9090A0)),
            onPressed: _isUploading ? null : _pickImage,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  hintStyle:
                  TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF5A623),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// ─── MENTOR BOTTOM NAV ───────────────────────────────────────────────────
  Widget _buildMentorBottomNav(BuildContext context, int selectedIndex) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.account_balance_wallet_outlined, 'label': 'Wallet'},
      {'icon': Icons.send_rounded, 'label': 'Chat'},
      {'icon': Icons.notifications_outlined, 'label': 'Notification'},
      {'icon': Icons.person_search_outlined, 'label': 'Request'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff1D5572),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => _handleMentorNav(context, index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[index]['icon'] as IconData,
                      color: isSelected
                          ? const Color(0xFFF5A623)
                          : Colors.white60,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index]['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFF5A623)
                            : Colors.white60,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _handleMentorNav(BuildContext context, int index) {
    if (index == 2) return;
    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MentorHomeScreen()),
              (route) => false,
        );
        break;
      case 5:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')));
    }
  }
}