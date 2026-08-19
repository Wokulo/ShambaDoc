import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final notifications = await NotificationService.listNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'disease_alert':
        return AppColors.error;
      case 'agronomist_response':
        return AppColors.success;
      case 'consultation_reminder':
        return AppColors.warning;
      case 'government_announcement':
        return AppColors.info;
      case 'agrovet_response':
        return AppColors.primary;
      case 'insurance_update':
        return AppColors.error;
      case 'sacco_update':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: n['is_read'] == true ? null : AppColors.primary.withOpacity(0.03),
                      child: ListTile(
                        leading: Icon(Icons.notifications_rounded, color: _typeColor(n['notification_type'] ?? 'platform')),
                        title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(n['body'] ?? ''),
                        trailing: Text(
                          _formatDate(n['created_at']),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) {
      return '';
    }
  }
}
