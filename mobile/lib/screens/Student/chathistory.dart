import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/bottom_navigation.dart';
import '../../models/chat_models.dart';
import 'chatscreen.dart';

// ── Chats Screen ──────────────────────────────────────────────────────────────

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
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
              .where((s) =>
                  s.status == 'scheduled' ||
                  s.status == 'started' ||
                  s.status == 'active')
              .toList();
          _historySessions =
              chatSessions
                  .where((s) =>
                      s.status == 'completed' ||
                      s.status == 'cancelled' ||
                      s.status == 'user_no_show')
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
                                        size: 64, color: Colors.grey.shade300),
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
                                      'Book a chat session with a Mentor to start chatting!',
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
                                      ..._activeSessions.map((user) => Padding(
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
                                                user: _historySessions[index]),
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
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.chat),
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
                ChatAvatar(url: user.avatarUrl, name: user.name, radius: 22),
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
                    if (user.unread > 0) ChatBadge(count: user.unread),
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
          ChatAvatar(url: user.avatarUrl, name: user.name, radius: 22),
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
              if (user.unread > 0) ChatBadge(count: user.unread),
            ],
          ),
        ],
      ),
    );
  }
}
