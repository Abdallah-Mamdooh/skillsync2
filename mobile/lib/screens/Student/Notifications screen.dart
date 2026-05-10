import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/bottom_navigation.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  void _loadNotifications() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<NotificationProvider>().fetchNotifications(token);
    }
  }

  void _markAllAsRead() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<NotificationProvider>().markAllAsRead(token);
    }
  }

  void _markAsRead(String notificationId) {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<NotificationProvider>().markAsRead(token, notificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D5572),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                color: const Color(0xFFF2F4F6),
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE8A020),
                        ),
                      );
                    }

                    if (provider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(
                              provider.error!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadNotifications,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8A020),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (provider.notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 48, color: Color(0xFF9A9AAF)),
                            SizedBox(height: 12),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9A9AAF),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: const Color(0xFFE8A020),
                      onRefresh: () async => _loadNotifications(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: _markAllAsRead,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE8A020),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Text(
                                  'Mark All As Read',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1A1A2E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(provider.notifications.length, (index) {
                            final item = provider.notifications[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    index == provider.notifications.length - 1
                                        ? 0
                                        : 8,
                              ),
                              child: _NotificationCard(
                                item: item,
                                onTap: () {
                                  if (!item.isRead) {
                                    _markAsRead(item.id);
                                  }
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.none),
    );
  }

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
              'Notifications',
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
            child: Text(
              'Check your latest updates and important alerts',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 0.5),
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          item.isRead ? FontWeight.w400 : FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.timeAgo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9AAF),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!item.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8A020),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
