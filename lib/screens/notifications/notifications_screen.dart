import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../models/notification.dart';
import '../../services/supabase_notification_service.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/web/web_page_wrapper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final userNotifications =
            await SupabaseNotificationService.getUserNotifications(
              authProvider.user!.maNguoiDung,
            );
        setState(() {
          notifications = userNotifications;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebPageWrapper(
      showTopBar: false,
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: AppLocalizations.of(context).translate('notifications'),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                } else if (value == 'delete_all') {
                  _deleteAllNotifications();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).translate('mark_all_read')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep, size: 20, color: AppColors.accentRed),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).translate('delete_all') ?? 'Xóa tất cả',
                        style: const TextStyle(color: AppColors.accentRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: notifications.isEmpty
                        ? _buildEmptyNotifications()
                        : _buildNotificationsList(),
                  ),
                ),
    ),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('no_notifications'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).translate('no_notifications_subtitle'),
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationItem(notifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.maThongBao.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.accentRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.maThongBao);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color:
              notification.daDoc
                  ? AppColors.cardBackground
                  : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                notification.daDoc ? AppColors.borderLight : AppColors.accentRed,
          ),
        ),
        child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.loaiThongBao),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(notification.loaiThongBao),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.tieuDe,
          style: TextStyle(
            fontSize: 16,
            fontWeight:
                notification.daDoc ? FontWeight.normal : FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.noiDung,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.thoiGianTao),
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.daDoc)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: AppColors.accentRed,
                  shape: BoxShape.circle,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.accentRed,
              onPressed: () => _deleteNotification(notification.maThongBao),
            ),
          ],
        ),
        onTap: () {
          _markAsRead(notification.maThongBao);
          // Navigate to relevant screen based on notification type
        },
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return AppColors.info;
      case 'promotion':
        return AppColors.accentRed;
      case 'system':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      // For simplicity show hours/minutes/just now; days fallback to hours
      final hours = difference.inHours;
      return AppLocalizations.of(context)
          .translate('hours_ago')
          .replaceFirst('{hour}', hours.toString());
    } else if (difference.inHours > 0) {
      return AppLocalizations.of(context)
          .translate('hours_ago')
          .replaceFirst('{hour}', difference.inHours.toString());
    } else if (difference.inMinutes > 0) {
      return AppLocalizations.of(context)
          .translate('minutes_ago')
          .replaceFirst('{min}', difference.inMinutes.toString());
    } else {
      return AppLocalizations.of(context).translate('just_now');
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final success = await SupabaseNotificationService.markAsRead(
        notificationId,
      );
      if (success) {
        setState(() {
          final index = notifications.indexWhere(
            (n) => n.maThongBao == notificationId,
          );
          if (index != -1) {
            notifications[index] = NotificationModel(
              maThongBao: notifications[index].maThongBao,
              maNguoiDung: notifications[index].maNguoiDung,
              tieuDe: notifications[index].tieuDe,
              noiDung: notifications[index].noiDung,
              loaiThongBao: notifications[index].loaiThongBao,
              daDoc: true,
              thoiGianTao: notifications[index].thoiGianTao,
              maDonHang: notifications[index].maDonHang,
              maKhuyenMai: notifications[index].maKhuyenMai,
            );
          }
        });
        // Sync unread badge on app bar
        if (mounted) {
          // ignore: use_build_context_synchronously
          final notifProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          await notifProvider.markAsRead(notificationId);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final success = await SupabaseNotificationService.markAllAsRead(
          authProvider.user!.maNguoiDung,
        );
        if (success) {
          setState(() {
            notifications =
                notifications.map((notification) {
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
                  );
                }).toList();
          });
          // Sync unread badge on app bar
          final notifProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          await notifProvider.markAllAsRead(authProvider.user!.maNguoiDung);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('update_success')),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final success = await SupabaseNotificationService.deleteNotification(notificationId);
      if (success) {
        setState(() {
          notifications.removeWhere((n) => n.maThongBao == notificationId);
        });
        final notifProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        await notifProvider.deleteNotification(notificationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('delete_success') ?? 'Đã xóa thông báo'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete_all') ?? 'Xóa tất cả'),
        content: Text(AppLocalizations.of(context).translate('delete_all_confirm') ?? 'Bạn có chắc muốn xóa tất cả thông báo? Hành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel') ?? 'Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: Text(AppLocalizations.of(context).translate('delete') ?? 'Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final success = await SupabaseNotificationService.deleteAllNotifications(
          authProvider.user!.maNguoiDung,
        );
        if (success) {
          setState(() {
            notifications.clear();
          });
          final notifProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          await notifProvider.deleteAllNotifications(authProvider.user!.maNguoiDung);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).translate('delete_success') ?? 'Đã xóa tất cả thông báo'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).error}: $e')),
        );
      }
    }
  }
}
