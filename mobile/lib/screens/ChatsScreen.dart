import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class ChatUser {
  final String sessionId;
  final String name;
  final String lastMessage;
  final String time;
  final String date;
  final int unread;
  final String avatarUrl;
  final bool isOnline;
  final String status; // accepted, active, completed, etc.

  const ChatUser({
    required this.sessionId,
    required this.name,
    this.lastMessage = '',
    this.time = '',
    this.date = '',
    this.unread = 0,
    this.avatarUrl = '',
    this.isOnline = false,
    this.status = '',
  });

  factory ChatUser.fromSession(Map<String, dynamic> session) {
    final mentor = session['mentor'] ?? {};
    final fullName = mentor['fullName'] ?? 'Unknown Mentor';
    final status = session['status'] ?? '';

    // Parse date from requestedAt or acceptedAt
    String time = '';
    String date = '';
    final rawDate = session['acceptedAt'] ?? session['requestedAt'] ?? '';
    if (rawDate.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        date = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return ChatUser(
      sessionId: session['id']?.toString() ?? '',
      name: fullName,
      lastMessage: '',
      time: time,
      date: date,
      unread: 0,
      avatarUrl: '',
      isOnline: status == 'active',
      status: status,
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderRole;
  final bool isMe;
  final String time;
  final bool isRead;

  const ChatMessage({
    this.id = '',
    required this.text,
    this.senderId = '',
    this.senderRole = '',
    required this.isMe,
    required this.time,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    String time = '';
    final rawDate = json['createdAt'] ?? '';
    if (rawDate.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return ChatMessage(
      id: json['_id']?.toString() ?? '',
      text: json['content']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      isMe: json['senderId']?.toString() == currentUserId,
      time: time,
      isRead: true,
    );
  }
}

// ── Chats Screen ──────────────────────────────────────────────────────────────

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  int _selectedIndex = 2;
  bool _isLoading = true;
  String? _error;

  List<ChatUser> _activeSessions = [];
  List<ChatUser> _historySessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;

    if (token == null) {
      setState(() {
        _error = 'You must be logged in to view chats.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ChatService.getMyChatSessions(token);

      if (response['success'] == true) {
        final List sessions = response['data'] ?? [];

        // Filter to chat-method sessions only
        final chatSessions = sessions
            .where((s) => s['method'] == 'chat')
            .map((s) => ChatUser.fromSession(s))
            .toList();

        setState(() {
          _activeSessions = chatSessions
              .where((s) => s.status == 'accepted' || s.status == 'active')
              .toList();
          _historySessions = chatSessions
              .where((s) => s.status == 'completed')
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load sessions.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  void _openChat(ChatUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatWithMentorScreen(user: user)),
    ).then((_) => _fetchSessions()); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'CHATS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'Connect and chat with your mentors anytime',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A7A9D),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: Color(0xFF7A7A9D)),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF7A7A9D),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchSessions,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _activeSessions.isEmpty && _historySessions.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline,
                                        size: 64,
                                        color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No chat sessions yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Book a chat session with a mentor to start chatting!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF7A7A9D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchSessions,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Active / booked sessions
                                    if (_activeSessions.isNotEmpty) ...[
                                      ..._activeSessions.map((user) =>
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: GestureDetector(
                                              onTap: () => _openChat(user),
                                              child: _BookedSessionCard(
                                                  user: user),
                                            ),
                                          )),
                                      const SizedBox(height: 2),
                                      const Divider(
                                        height: 17,
                                        thickness: 2,
                                        color: Color(0xFFD9D9D9),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // Chat history
                                    if (_historySessions.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.only(
                                            left: 4, bottom: 12),
                                        child: Text(
                                          'Chat History',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _historySessions.length,
                                          itemBuilder: (context, index) =>
                                              GestureDetector(
                                            onTap: () => _openChat(
                                                _historySessions[index]),
                                            child: _ChatHistoryTile(
                                                user:
                                                    _historySessions[index]),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ── Booked Session Card ───────────────────────────────────────────────────────

class _BookedSessionCard extends StatelessWidget {
  final ChatUser user;
  const _BookedSessionCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCDD5DF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BOOKED SESSION CHAT',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _Avatar(url: user.avatarUrl, name: user.name, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.lastMessage.isNotEmpty
                            ? user.lastMessage
                            : 'Tap to start chatting',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A827F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (user.time.isNotEmpty || user.date.isNotEmpty)
                      Text(
                        '${user.time}  ${user.date}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7A7A9D),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (user.unread > 0) _Badge(count: user.unread),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat History Tile ─────────────────────────────────────────────────────────

class _ChatHistoryTile extends StatelessWidget {
  final ChatUser user;
  const _ChatHistoryTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Avatar(url: user.avatarUrl, name: user.name, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.lastMessage.isNotEmpty
                      ? user.lastMessage
                      : 'Session completed',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A827F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (user.time.isNotEmpty || user.date.isNotEmpty)
                Text(
                  '${user.time}  ${user.date}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A7A9D),
                  ),
                ),
              const SizedBox(height: 4),
              if (user.unread > 0) _Badge(count: user.unread),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chat With Mentor Screen ───────────────────────────────────────────────────

class ChatWithMentorScreen extends StatefulWidget {
  final ChatUser user;
  const ChatWithMentorScreen({super.key, required this.user});

  @override
  State<ChatWithMentorScreen> createState() => _ChatWithMentorScreenState();
}

class _ChatWithMentorScreenState extends State<ChatWithMentorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _pollTimer;

  String _currentUserId = '';
  String _token = '';

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _token = auth.token ?? '';
    _currentUserId = auth.user?['_id']?.toString() ?? '';
    _loadMessages();

    // Poll for new messages every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadMessages(silent: true);
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_token.isEmpty) {
      setState(() {
        _error = 'Authentication required.';
        _isLoading = false;
      });
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ChatService.getChatMessages(
        _token,
        widget.user.sessionId,
      );

      if (response['success'] == true) {
        final List data = response['data'] ?? [];
        final newMessages = data
            .map((m) => ChatMessage.fromJson(m, _currentUserId))
            .toList();

        setState(() {
          _messages = newMessages;
          _isLoading = false;
        });

        // Scroll to bottom after messages load
        if (!silent || newMessages.length != _messages.length) {
          _scrollToBottom();
        }
      } else {
        if (!silent) {
          setState(() {
            _error = response['message'] ?? 'Failed to load messages.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _error = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();

    // Optimistic UI: add message immediately
    final optimisticMsg = ChatMessage(
      text: text,
      isMe: true,
      time: TimeOfDay.now().format(context),
      isRead: false,
    );
    setState(() {
      _messages.add(optimisticMsg);
    });
    _scrollToBottom();

    try {
      final response = await ChatService.sendMessage(
        _token,
        widget.user.sessionId,
        text,
      );

      if (response['success'] != true) {
        // Remove optimistic message on failure
        setState(() {
          _messages.remove(optimisticMsg);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to send message'),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      } else {
        // Refresh to get the real message from backend
        await _loadMessages(silent: true);
      }
    } catch (e) {
      setState(() {
        _messages.remove(optimisticMsg);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Teal block at top so the clipped header corner is teal not grey
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(color: const Color(0xFF1D5572)),
          ),
          Column(
            children: [
              // ── Header ────────────────────────────────────────────
              _ChatHeader(user: widget.user),

              // ── Messages ──────────────────────────────────────────
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 48,
                                        color: Color(0xFF7A7A9D)),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF7A7A9D),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadMessages,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _messages.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No messages yet.\nSay hello! 👋',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF7A7A9D),
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  itemCount: _messages.length + 1, // +1 date
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return const _DateLabel(label: 'Today');
                                    }
                                    final msg = _messages[index - 1];
                                    return _MessageBubble(
                                      message: msg,
                                      mentorName: widget.user.name,
                                    );
                                  },
                                ),
                ),
              ),

              // ── Input Bar (only for active/accepted sessions) ──
              if (widget.user.status == 'accepted' ||
                  widget.user.status == 'active')
                _MessageInputBar(
                  controller: _controller,
                  onSend: _sendMessage,
                  isSending: _isSending,
                )
              else
                Container(
                  color: const Color(0xFFF2F4F7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: const Text(
                    'This session has ended. You can no longer send messages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7A7A9D),
                      fontSize: 13,
                    ),
                  ),
                ),

              // ── Bottom Nav ────────────────────────────────────────
              _BottomNav(
                selectedIndex: 2,
                onTap: (_) {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chat Header ───────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final ChatUser user;
  const _ChatHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Teal background clipped to shape ──
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            color: const Color(0xFF1D5572),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 8),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    'CHAT WITH MENTOR',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Stack(
                        children: [
                          _Avatar(
                              url: user.avatarUrl,
                              name: user.name,
                              radius: 24),
                          if (user.isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF1D5572),
                                      width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (user.isOnline)
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Yellow border drawn on top following the curve ──
        Positioned.fill(
          child: CustomPaint(painter: _HeaderBorderPainter()),
        ),

        // ── White decorative arc in bottom-right corner ──
        Positioned(
          bottom: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(100, 100),
            painter: _WhiteCornerPainter(),
          ),
        ),
      ],
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double radius = 70.0;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(
        Offset(size.width - radius, size.height),
        radius: const Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeaderBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 70.0;
    final borderPaint = Paint()
      ..color = const Color(0xFFF5A623)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width - radius, size.height)
      ..arcToPoint(
        Offset(size.width, size.height - radius),
        radius: const Radius.circular(radius),
        clockwise: false,
      );

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WhiteCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..arcToPoint(
        Offset(size.width, 0),
        radius: Radius.circular(size.width * 1.1),
        clockwise: false,
      )
      ..close();

    // White fill
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);

    // Yellow border along the arc only
    final arcPath = Path()
      ..moveTo(0, size.height)
      ..arcToPoint(
        Offset(size.width, 0),
        radius: Radius.circular(size.width * 1.1),
        clockwise: false,
      );

    canvas.drawPath(
        arcPath,
        Paint()
          ..color = const Color(0xFFF5A623)
          ..strokeWidth = 10.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Date Label ────────────────────────────────────────────────────────────────

class _DateLabel extends StatelessWidget {
  final String label;
  const _DateLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFDDE1E7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7A7A9D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String mentorName;
  const _MessageBubble({required this.message, this.mentorName = ''});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mentor avatar (left side)
          if (!isMe) ...[
            _Avatar(url: '', name: mentorName, radius: 16),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF1B3A4B)
                        : const Color(0xFFE8EAED),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isMe ? Colors.white : const Color(0xFF1A1A2E),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.time,
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : const Color(0xFF9E9E9E),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Input Bar ─────────────────────────────────────────────────────────

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  const _MessageInputBar({
    required this.controller,
    required this.onSend,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Attachment icon
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.attach_file_rounded,
                color: Color(0xFF9E9E9E), size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          // Image icon
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.image_outlined,
                color: Color(0xFF9E9E9E), size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(21),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Color(0xFFBBBBCC),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSending
                    ? const Color(0xFFD4A84A)
                    : const Color(0xFFF5A623),
                borderRadius: BorderRadius.circular(21),
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  final double radius;
  const _Avatar({required this.url, this.name = '', required this.radius});

  @override
  Widget build(BuildContext context) {
    // If we have a URL, show the image; otherwise show initials
    if (url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        backgroundColor: const Color(0xFFE0E4ED),
      );
    }

    // Generate initials from name
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1D5572),
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.assignment_outlined, label: 'assess'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B3A4B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          8, 12, 8, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _items[i].icon,
                  color: selected ? Colors.white : Colors.white38,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  _items[i].label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white : Colors.white38,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 20 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }), 
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}