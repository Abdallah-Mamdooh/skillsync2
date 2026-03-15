import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF2F4F7),
      ),
      home: const ChatsScreen(),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class ChatUser {
  final String name;
  final String lastMessage;
  final String time;
  final String date;
  final int unread;
  final String avatarUrl;
  final bool isOnline;

  const ChatUser({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.date,
    required this.unread,
    required this.avatarUrl,
    this.isOnline = false,
  });
}

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final bool isRead;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = false,
  });
}

// ── Chats Screen ──────────────────────────────────────────────────────────────

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  int _selectedIndex = 2;

  final ChatUser bookedSession = const ChatUser(
    name: 'Sarah Johnson',
    lastMessage: 'Hello! my name is sarah Johnson',
    time: '10:45',
    date: '08/05',
    unread: 1,
    avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
    isOnline: true,
  );

  final List<ChatUser> chatHistory = const [
    ChatUser(
      name: 'Michael Chen',
      lastMessage: 'Appreciate it! See you soon!',
      time: '1:30',
      date: '06/05',
      unread: 1,
      avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
    ),
    ChatUser(
      name: 'Emily Rodriguez',
      lastMessage: 'Appreciate it! See you soon!',
      time: '8:25',
      date: '02/05',
      unread: 1,
      avatarUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
    ),
    ChatUser(
      name: 'David Kim',
      lastMessage: 'Appreciate it! See you soon!',
      time: '6:30',
      date: '22/04',
      unread: 1,
      avatarUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
    ),
  ];

  void _openChat(ChatUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatWithMentorScreen(user: user)),
    );
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openChat(bookedSession),
                      child: _BookedSessionCard(user: bookedSession),
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 17,
                      thickness: 2,
                      color: Color(0xFFD9D9D9),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: chatHistory.length,
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () => _openChat(chatHistory[index]),
                          child: _ChatHistoryTile(user: chatHistory[index]),
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
                _Avatar(url: user.avatarUrl, radius: 22),
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
                        user.lastMessage,
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
          _Avatar(url: user.avatarUrl, radius: 22),
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
                  user.lastMessage,
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

  final List<ChatMessage> _messages = const [
    ChatMessage(
      text:
          "Hi! I saw your profile and I'm interested in getting career guidance.",
      isMe: true,
      time: '10:30 AM',
      isRead: true,
    ),
    ChatMessage(
      text:
          "Hello! I'd be happy to help you. What specific area would you like to focus on?",
      isMe: false,
      time: '10:32 AM',
    ),
    ChatMessage(
      text:
          "I'm currently learning React and want to transition into a frontend developer role. Do you have any advice on building a strong portfolio?",
      isMe: true,
      time: '10:33 AM',
      isRead: true,
    ),
    ChatMessage(
      text:
          "Great question! Building a portfolio is crucial. I recommend starting with 3-5 quality projects that showcase different skills.",
      isMe: false,
      time: '10:34 AM',
    ),
    ChatMessage(
      text:
          "Focus on projects that solve real problems. Include at least one full-stack application, and make sure your code is clean and well-documented on GitHub.",
      isMe: false,
      time: '10:35 AM',
    ),
    ChatMessage(
      text:
          "That's really helpful! Should I focus more on personal projects or contribute to open source?",
      isMe: true,
      time: '10:38 AM',
      isRead: true,
    ),
    ChatMessage(
      text: "Both are valuable! Personal projects show",
      isMe: false,
      time: '10:39 AM',
    ),
  ];

  late List<ChatMessage> _mutableMessages;

  @override
  void initState() {
    super.initState();
    _mutableMessages = List.from(_messages);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _mutableMessages.add(ChatMessage(
        text: text,
        isMe: true,
        time: TimeOfDay.now().format(context),
        isRead: false,
      ));
    });
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
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
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _mutableMessages.length + 1, // +1 for date label
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _DateLabel(label: 'Today');
                      }
                      final msg = _mutableMessages[index - 1];
                      return _MessageBubble(message: msg);
                    },
                  ),
                ),
              ),

              // ── Input Bar ─────────────────────────────────────────
              _MessageInputBar(
                controller: _controller,
                onSend: _sendMessage,
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
                          _Avatar(url: user.avatarUrl, radius: 24),
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
                                      color: const Color(0xFF1D5572), width: 2),
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
      ..strokeWidth = 4.0
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
          ..strokeWidth = 4.0
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
  const _MessageBubble({required this.message});

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
            const _Avatar(
              url: 'https://randomuser.me/api/portraits/women/44.jpg',
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? const Color(0xFF1B3A4B)
                            : const Color(0xFF9E9E9E),
                      ),
                    ],
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

// ── Message Input Bar ─────────────────────────────────────────────────────────

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.onSend,
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
            onTap: onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623),
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Icon(
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
  final double radius;
  const _Avatar({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(url),
      backgroundColor: const Color(0xFFE0E4ED),
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
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
