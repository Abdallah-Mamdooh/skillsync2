import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Returns a human-readable relative time string (e.g. "2 hours ago").
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await NotificationService.getMyNotifications(token);

    _isLoading = false;

    if (response['success'] == true) {
      final data = response['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map) {
        final nested =
            data['notifications'] ?? data['items'] ?? data['data'];
        if (nested is List) {
          items = nested;
        }
      }
      _notifications =
          items.map((json) => NotificationModel.fromJson(json)).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } else {
      _error = response['message'] ?? 'Failed to load notifications';
    }

    notifyListeners();
  }

  Future<void> fetchUnreadCount(String token) async {
    await fetchNotifications(token);
  }

  Future<void> markAsRead(String token, String notificationId) async {
    final response =
        await NotificationService.markAsRead(token, notificationId);

    if (response['success'] == true) {
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        final old = _notifications[idx];
        _notifications[idx] = NotificationModel(
          id: old.id,
          type: old.type,
          title: old.title,
          message: old.message,
          isRead: true,
          data: old.data,
          createdAt: old.createdAt,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead(String token) async {
    final response = await NotificationService.markAllAsRead(token);

    if (response['success'] == true) {
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                type: n.type,
                title: n.title,
                message: n.message,
                isRead: true,
                data: n.data,
                createdAt: n.createdAt,
              ))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }
}
