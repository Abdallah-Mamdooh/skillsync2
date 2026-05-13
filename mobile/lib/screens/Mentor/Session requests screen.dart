import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/mentor_service.dart';
import '../../widgets/bottom_navigation.dart';
import 'User overview screen.dart';

// ── Data Model ──────────────────────────────────────────────────────────────

class SessionRequest {
  final String sessionId;
  final String studentName;
  final String initials;
  final int durationMinutes;
  final double priceEGP;
  final String sessionType;
  final String timeFrom;
  final String timeTo;
  final String status;

  const SessionRequest({
    required this.sessionId,
    required this.studentName,
    required this.initials,
    required this.durationMinutes,
    required this.priceEGP,
    required this.sessionType,
    required this.timeFrom,
    required this.timeTo,
    this.status = 'scheduled',
  });
}

// ── Main Screen ──────────────────────────────────────────────────────────────

class SessionRequestsScreen extends StatefulWidget {
  const SessionRequestsScreen({super.key});

  @override
  State<SessionRequestsScreen> createState() => _SessionRequestsScreenState();
}

class _SessionRequestsScreenState extends State<SessionRequestsScreen> {
  bool _isLoading = true;
  List<SessionRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadIncoming();
  }

  Future<void> _loadIncoming() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final response = await MentorService.getIncomingSessions(token);
    if (response['success'] == true) {
      final list = response['data'] is List ? response['data'] as List : <dynamic>[];
      _requests = list.whereType<Map>().map((raw) {
        final session = MentorService.normalizeSession(Map<String, dynamic>.from(raw));
        final requester = session['requester'] is Map<String, dynamic>
            ? session['requester'] as Map<String, dynamic>
            : <String, dynamic>{};
        final pricing = session['pricing'] is Map<String, dynamic>
            ? session['pricing'] as Map<String, dynamic>
            : <String, dynamic>{};
        final fullName = (requester['fullName'] ?? 'Student').toString();
        final nameParts = fullName.split(' ');
        final initials = nameParts.length > 1
            ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
            : fullName[0].toUpperCase();
        return SessionRequest(
          sessionId: (session['id'] ?? '').toString(),
          studentName: fullName,
          initials: initials,
          durationMinutes: ((session['durationMinutes'] ?? 0) as num).toInt(),
          priceEGP: ((pricing['total'] ?? pricing['totalAmount'] ?? session['totalAmount'] ?? 0) as num).toDouble(),
          sessionType: (session['method'] ?? 'chat').toString(),
          timeFrom: (session['scheduledStartTime'] ?? '').toString(),
          timeTo: (session['scheduledEndTime'] ?? '').toString(),
          status: (session['status'] ?? 'scheduled').toString(),
        );
      }).toList();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onAccept(int index) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final selected = _requests[index];
    final response = await MentorService.startSession(token, selected.sessionId);
    if (response['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']?.toString() ?? 'Failed to start session')),
        );
      }
      return;
    }
    // Remove from list immediately
    setState(() {
      _requests.removeAt(index);
    });
    if (!mounted) return;
    // Navigate to UserOverview and refresh list when returning
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserOverviewScreen(sessionId: selected.sessionId),
      ),
    );
    // Refresh the full list when coming back
    _loadIncoming();
  }

  Future<void> _onCancel(int index) async {
    // Confirm before declining
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Request'),
        content: Text('Are you sure you want to decline the session request from ${_requests[index].studentName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Remove from local list immediately
    // Note: Backend doesn't have a mentor reject endpoint,
    // so we remove it locally. The session will still exist
    // in the backend but won't show in the mentor's list.
    setState(() {
      _requests.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session request declined.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──
          _buildHeader(),

          // ── Request Cards ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _SessionRequestCard(
                request: _requests[index],
                onAccept: () => _onAccept(index),
                onCancel: () => _onCancel(index),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Nav ──
      bottomNavigationBar: const MentorBottomNavigation(
          selectedIndex: MentorBottomNavIndex.requests),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1F5F7A),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_requests.where((r) => r.status == 'scheduled').length} pending request${_requests.where((r) => r.status == 'scheduled').length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session Request Card ─────────────────────────────────────────────────────

class _SessionRequestCard extends StatelessWidget {
  final SessionRequest request;
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const _SessionRequestCard({
    required this.request,
    required this.onAccept,
    required this.onCancel,
  });

  String get _sessionTypeLabel {
    return request.sessionType == 'call' ? 'Call' : 'Chat';
  }

  IconData get _sessionTypeIcon {
    return request.sessionType == 'call'
        ? Icons.phone_outlined
        : Icons.chat_bubble_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Avatar + Info ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  request.initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Duration · Price · Session type
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Color(0xFF1F5F7A)),
                        const SizedBox(width: 4),
                        Text(
                          '${request.durationMinutes}MIN',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1F5F7A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.credit_card,
                            size: 14, color: Color(0xFF1F5F7A)),
                        const SizedBox(width: 4),
                        Text(
                          '${request.priceEGP.toInt()} EGP',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1F5F7A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(_sessionTypeIcon,
                            size: 14, color: const Color(0xFF1F5F7A)),
                        const SizedBox(width: 4),
                        Text(
                          _sessionTypeLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1F5F7A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Time range
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          'From ${request.timeFrom} To ${request.timeTo}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1F5F7A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Buttons ──
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Decline',
                  icon: Icons.close,
                  onTap: onCancel,
                  isAccept: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Accept',
                  icon: Icons.check,
                  onTap: onAccept,
                  isAccept: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAccept;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isAccept,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isAccept
        ? const Color(0xFF1D5572)
        : Colors.grey.shade200;
    final fgColor = isAccept
        ? Colors.white
        : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}