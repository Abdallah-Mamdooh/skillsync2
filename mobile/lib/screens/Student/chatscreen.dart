import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/bottom_navigation.dart';
import '../../models/chat_models.dart';
import 'feedback_screen.dart';

export '../../models/chat_models.dart';

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

  // Timer / session state
  Timer? _pollTimer;
  Timer? _messagePollTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _graceSeconds = 0;
  bool _timerStarted = false;
  String _sessionStatus = ''; // 'scheduled', 'started', 'active'
  bool _sessionEnded = false;
  bool _joining = false;
  bool _autoJoinAttempted = false;

  bool get _isHistoryView => widget.user.openedFromHistory;
  bool get _isReadOnlySession =>
      _sessionStatus == 'completed' ||
      _sessionStatus == 'cancelled' ||
      _sessionStatus == 'user_no_show';

  @override
  void initState() {
    super.initState();
    _sessionStatus = widget.user.status;
    if (widget.user.sessionId.isNotEmpty &&
        !widget.user.sessionId.startsWith('temp')) {
      _fetchMessages();
      _fetchSessionTimer();
      _startTimerPolling();
      _startMessagePolling();
    } else {
      _messages = [
        const ChatMessage(
          text:
              "Hi! I saw your profile and I'm interested in getting career guidance.",
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

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messagePollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
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
      final data = response['data'] ?? {};
      final timer = data['timer'] is Map<String, dynamic>
          ? data['timer'] as Map<String, dynamic>
          : <String, dynamic>{};
      final seconds = (timer['remainingSessionSeconds'] ?? 0) as num;
      final grace = (timer['remainingJoinGraceSeconds'] ?? 0) as num;
      final timerStarted = timer['timerStarted'] == true;
      final status = (data['status'] ?? '').toString();
      setState(() {
        _remainingSeconds = seconds.toInt();
        _graceSeconds = grace.toInt();
        _timerStarted = timerStarted;
        if (status.isNotEmpty) _sessionStatus = status;
        _sessionTimerLabel = _formatDuration(_remainingSeconds);
      });
      _autoJoinSessionIfNeeded();
      if (!_isHistoryView) {
        _checkSessionEnd();
      }
    }
  }

  Future<void> _autoJoinSessionIfNeeded() async {
    if (_autoJoinAttempted ||
        _joining ||
        _isHistoryView ||
        _isReadOnlySession ||
        widget.user.sessionId.isEmpty ||
        widget.user.sessionId.startsWith('temp') ||
        _sessionStatus != 'started') {
      return;
    }

    _autoJoinAttempted = true;
    await _joinSession(showFeedback: false);
  }

  void _startTimerPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchSessionTimer();
    });
    // Also start a 1-second tick for countdown display
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _sessionTimerLabel = _formatDuration(_remainingSeconds);
        });
        if (!_isHistoryView) {
          _checkSessionEnd();
        }
      }
      if (_sessionStatus == 'started' && _graceSeconds > 0) {
        setState(() => _graceSeconds--);
      }
    });
  }

  void _startMessagePolling() {
    _messagePollTimer?.cancel();
    _messagePollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollNewMessages();
    });
  }

  Future<void> _pollNewMessages() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null || widget.user.sessionId.isEmpty) return;
    try {
      final response =
          await ChatService.getChatMessages(token, widget.user.sessionId);
      if (response['success'] == true && mounted) {
        final List msgs = response['data'] ?? [];
        // Count server messages vs local — if server has more, update
        if (msgs.length > _messages.length) {
          setState(() {
            _messages = msgs.map((m) {
              final dt = DateTime.parse(m['createdAt']).toLocal();
              final attachment = m['attachment'] is Map
                  ? Map<String, dynamic>.from(m['attachment'])
                  : null;
              final hasFile = attachment != null &&
                  (attachment['url'] ?? '').toString().isNotEmpty;
              ChatAttachmentType attType = ChatAttachmentType.none;
              if (hasFile) {
                final mime = (attachment['mimeType'] ?? '').toString();
                attType = mime.startsWith('image/')
                    ? ChatAttachmentType.image
                    : ChatAttachmentType.file;
              }
              return ChatMessage(
                text: m['content'] ?? '',
                isMe: m['senderId'] == auth.user?['_id'],
                time: "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}",
                isRead: m['isRead'] ?? false,
                attachmentType: attType,
                attachmentUrl: hasFile ? attachment!['url']?.toString() : null,
                attachmentFileName:
                    hasFile ? attachment!['fileName']?.toString() : null,
              );
            }).toList();
          });
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  String _formatDuration(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _checkSessionEnd() {
    if (_isHistoryView) return;
    if (_sessionEnded) return;
    if (_sessionStatus == 'completed' ||
        _sessionStatus == 'cancelled' ||
        _sessionStatus == 'user_no_show' ||
        (_timerStarted && _remainingSeconds <= 0)) {
      _sessionEnded = true;
      _pollTimer?.cancel();
      _messagePollTimer?.cancel();
      _showSessionEndedDialog();
    }
  }

  void _showSessionEndedDialog() {
    if (!mounted) return;
    // Check if feedback was already submitted before showing dialog
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) {
      // No token, just go back
      Navigator.pop(context);
      return;
    }
    ApiService.getSessionFeedback(
      token: token,
      sessionId: widget.user.sessionId,
    ).then((response) {
      if (!mounted) return;
      final feedbackExists =
          response['success'] == true && response['data'] != null;
      if (feedbackExists) {
        // Already submitted feedback — just go back
        Navigator.pop(context);
        return;
      }
      // No feedback yet — show dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Session Ended'),
          content: const Text(
              'Your mentoring session has ended. Would you like to leave feedback?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FeedbackScreen(sessionId: widget.user.sessionId),
                  ),
                );
              },
              child: const Text('Leave Feedback'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to chat history
              },
              child: const Text('Skip'),
            ),
          ],
        ),
      );
    }).catchError((_) {
      if (!mounted) return;
      // On error, show the dialog anyway
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Session Ended'),
          content: const Text(
              'Your mentoring session has ended. Would you like to leave feedback?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FeedbackScreen(sessionId: widget.user.sessionId),
                  ),
                );
              },
              child: const Text('Leave Feedback'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Skip'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _joinSession({bool showFeedback = true}) async {
    if (_joining) return;
    setState(() => _joining = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) {
      if (mounted) setState(() => _joining = false);
      return;
    }
    try {
      final response = await ApiService.joinSession(
        token: token,
        sessionId: widget.user.sessionId,
      );
      if (response['success'] == true && mounted) {
        setState(() {
          _sessionStatus = response['data']?['status']?.toString() ?? 'active';
        });
        await _fetchSessionTimer();
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined session successfully!')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  response['message']?.toString() ?? 'Failed to join session')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
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
            final attachment = m['attachment'] is Map
                ? Map<String, dynamic>.from(m['attachment'])
                : null;
            final hasFile = attachment != null &&
                (attachment['url'] ?? '').toString().isNotEmpty;
            ChatAttachmentType attType = ChatAttachmentType.none;
            if (hasFile) {
              final mime = (attachment['mimeType'] ?? '').toString();
              attType = mime.startsWith('image/')
                  ? ChatAttachmentType.image
                  : ChatAttachmentType.file;
            }
            final isLocalFile = (m['file'] != null ||
                (m['attachment'] == null && hasFile == false));
            return ChatMessage(
              text: m['content'] ?? '',
              isMe: m['senderId'] == auth.user?['_id'],
              time: "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}",
              isRead: m['isRead'] ?? false,
              attachmentType: attType,
              attachmentUrl: hasFile ? attachment!['url']?.toString() : null,
              attachmentFileName:
                  hasFile ? attachment!['fileName']?.toString() : null,
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
            .showSnackBar(SnackBar(content: Text('Image error: $e')));
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
            .showSnackBar(SnackBar(content: Text('File error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildHeader(),
          // Read-only banner for completed sessions
          if (_isReadOnlySession) _buildReadOnlyBanner(),
          // Join session banner when mentor has started but user hasn't joined
          if (_sessionStatus == 'started' && !_isHistoryView)
            _buildJoinBanner(),
          // Session ending soon warning
          if (_timerStarted &&
              _remainingSeconds > 0 &&
              _remainingSeconds <= 120)
            _buildEndingSoonBanner(),
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
          if (!_isReadOnlySession) _buildInputBar(),
          const BottomNavigation(selectedIndex: BottomNavIndex.chat),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String duration;
    if (_sessionStatus == 'scheduled') {
      duration = 'Waiting for mentor...';
    } else if (_sessionStatus == 'started' && !_timerStarted) {
      duration = 'Grace: ${_formatDuration(_graceSeconds)}';
    } else if (_timerStarted && _remainingSeconds > 0) {
      duration = _formatDuration(_remainingSeconds);
    } else if (_sessionTimerLabel.isNotEmpty) {
      duration = _sessionTimerLabel;
    } else {
      duration = widget.user.sessionDuration.isNotEmpty
          ? widget.user.sessionDuration
          : '00:00';
    }

    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1D5572)),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 4,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton(
              icon:
                  const Icon(Icons.chevron_left, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.user.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 28,
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
                _buildCombinedStatusPill(duration),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildDateChip(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Color(0xFFE5E7EB).withOpacity(0.8),
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
            color: const Color(0xFF1F2937),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

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
                color: isMe ? const Color(0xFF1D5572) : Color(0xFFD9D9D9),
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
                  // Image attachment: local file or server URL
                  if (msg.attachmentType == ChatAttachmentType.image &&
                      msg.filePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(msg.filePath!),
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (msg.attachmentType == ChatAttachmentType.image &&
                      msg.attachmentUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        msg.attachmentUrl!,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  // File attachment: local file or server URL
                  if (msg.attachmentType == ChatAttachmentType.file &&
                      msg.filePath != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          color:
                              isMe ? Colors.white70 : const Color(0xFF1B2B4B),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            msg.fileName ?? 'File',
                            style: GoogleFonts.inter(
                              color:
                                  isMe ? Colors.white : const Color(0xFF1A1A2E),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else if (msg.attachmentType == ChatAttachmentType.file &&
                      msg.attachmentUrl != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          color:
                              isMe ? Colors.white70 : const Color(0xFF1B2B4B),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            msg.attachmentFileName ?? 'File',
                            style: GoogleFonts.inter(
                              color:
                                  isMe ? Colors.white : const Color(0xFF1A1A2E),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (msg.text.isNotEmpty) ...[
                    if (msg.attachmentType != ChatAttachmentType.none)
                      const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        msg.text,
                        style: GoogleFonts.inter(
                          color: isMe ? Colors.white : const Color(0xFF1D5572),
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
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

  Widget _buildJoinBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFF3CD),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF856404), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mentor has started the session. Grace period: ${_formatDuration(_graceSeconds)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF856404),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _joining ? null : _joinSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2B4B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: _joining
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Join',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEndingSoonBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFFFEBEE),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 8),
          Text(
            'Session ending soon: ${_formatDuration(_remainingSeconds)} remaining',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFFD32F2F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyBanner() {
    final label = _sessionStatus == 'completed'
        ? 'Session completed — Read only'
        : _sessionStatus == 'user_no_show'
            ? 'Session ended (no show) — Read only'
            : 'Session cancelled — Read only';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF757575), size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
                  hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}
