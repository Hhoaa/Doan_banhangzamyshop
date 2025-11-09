import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/supabase_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../services/local_notification_service.dart';
import '../models/user.dart' as app_user;

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  RealtimeChannel? _channel;
  int? _currentUserId;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  void handleAuthChanged(app_user.User? user) {
    final nextUserId = user?.maNguoiDung;

    if (_currentUserId == nextUserId) {
      return;
    }

    _currentUserId = nextUserId;

    _channel?.unsubscribe();
    _channel = null;

    if (nextUserId == null) {
      if (_notifications.isNotEmpty || _unreadCount != 0 || _isLoading) {
        _notifications = [];
        _unreadCount = 0;
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
      return;
    }

    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
    unawaited(loadNotifications(nextUserId));
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadNotifications(int userId) async {
    setLoading(true);
    setError(null);

    try {
      // Debug: loading notifications
      // ignore: avoid_print
      print('[Notif] Loading notifications for user: ' + userId.toString());
      final notifications = await SupabaseNotificationService.getUserNotifications(userId);
      _notifications = notifications;
      _unreadCount = notifications.where((n) => !n.daDoc).length;
      // ignore: avoid_print
      print('[Notif] Loaded total=' + notifications.length.toString() + ', unread=' + _unreadCount.toString());
      _subscribeRealtime(userId);
    } catch (e) {
      setError('Lỗi tải thông báo: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final success = await SupabaseNotificationService.markAsRead(notificationId);
      if (success) {
        final index = _notifications.indexWhere((n) => n.maThongBao == notificationId);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            maThongBao: _notifications[index].maThongBao,
            maNguoiDung: _notifications[index].maNguoiDung,
            tieuDe: _notifications[index].tieuDe,
            noiDung: _notifications[index].noiDung,
            loaiThongBao: _notifications[index].loaiThongBao,
            daDoc: true,
            thoiGianTao: _notifications[index].thoiGianTao,
            maDonHang: _notifications[index].maDonHang,
            maKhuyenMai: _notifications[index].maKhuyenMai,
            duLieuBoSung: _notifications[index].duLieuBoSung,
          );
          _unreadCount = _notifications.where((n) => !n.daDoc).length;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      setError('Lỗi đánh dấu đã đọc: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead(int userId) async {
    try {
      final success = await SupabaseNotificationService.markAllAsRead(userId);
      if (success) {
        _notifications = _notifications.map((notification) {
          return NotificationModel(
            maThongBao: notification.maThongBao,
            maNguoiDung: notification.maNguoiDung,
            tieuDe: notification.tieuDe,
            noiDung: notification.noiDung,
            loaiThongBao: notification.loaiThongBao,
            daDoc: true,
            thoiGianTao: notification.thoiGianTao,
            maDonHang: notification.maDonHang,
            maKhuyenMai: notification.maKhuyenMai,
            duLieuBoSung: notification.duLieuBoSung,
          );
        }).toList();
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      setError('Lỗi đánh dấu tất cả đã đọc: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final success = await SupabaseNotificationService.deleteNotification(notificationId);
      if (success) {
        _notifications.removeWhere((n) => n.maThongBao == notificationId);
        _unreadCount = _notifications.where((n) => !n.daDoc).length;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      setError('Lỗi xóa thông báo: $e');
      return false;
    }
  }

  Future<bool> deleteAllNotifications(int userId) async {
    try {
      final success = await SupabaseNotificationService.deleteAllNotifications(userId);
      if (success) {
        _notifications.clear();
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      setError('Lỗi xóa tất cả thông báo: $e');
      return false;
    }
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.daDoc) {
      _unreadCount++;
    }
    notifyListeners();
  }

  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  void _subscribeRealtime(int userId) {
    // Clean previous
    _channel?.unsubscribe();
    final client = SupabaseConfig.client;
    // Use correct channel name format: 'public:table'
    _channel = client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          // Use equality filter with integer value; avoid casting to string
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'ma_nguoi_dung', value: userId),
          callback: (payload) async {
            try {
              final Map<String, dynamic>? row = payload.newRecord;
              if (row == null) return;
              final notif = NotificationModel.fromJson(row);
              // ignore: avoid_print
              print('[Notif][RT] Insert received id=' + notif.maThongBao.toString() + ' unread=' + (!notif.daDoc).toString());
              addNotification(notif);
              final title = notif.tieuDe;
              final body = notif.maDonHang != null
                  ? 'Đơn hàng #${notif.maDonHang}: ${notif.noiDung}'
                  : notif.noiDung;
              await LocalNotificationService.showBasic(
                id: notif.maThongBao,
                title: title,
                body: body,
              );
              // ignore: avoid_print
              print('[Notif][RT] Local notification shown');
            } catch (e) {
              // ignore: avoid_print
              print('[Notif][RT] Error handling insert: ' + e.toString());
            }
          },
        )
        .subscribe();
    // ignore: avoid_print
    print('[Notif] Subscribed to realtime for user ' + userId.toString());
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void clearError() {
    setError(null);
  }
}
