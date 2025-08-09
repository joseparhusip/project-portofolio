import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationPopUp extends StatelessWidget {
  final User user;
  final List<NotificationItem> notifications;
  final Function(int) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;

  const NotificationPopUp({
    super.key,
    required this.user,
    required this.notifications,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notifications'),
      content: SizedBox(
        width: double.maxFinite,
        child: notifications.isEmpty
            ? const Center(child: Text('No new notifications.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    title: Text(notification.message),
                    subtitle: Text(notification.timestamp.toString()),
                    leading: !notification.isRead
                        ? const CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.blue,
                          )
                        : const SizedBox(
                            width: 10), // Placeholder for alignment
                    trailing: IconButton(
                      // FIXED: Used a valid icon
                      icon: const Icon(Icons.mark_email_read_outlined),
                      tooltip: 'Mark as read',
                      onPressed: () => onMarkAsRead(notification.id),
                    ),
                    onTap: () => onMarkAsRead(notification.id),
                  );
                },
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          // FIXED: Moved child property to the end
          child: const Text('Close'),
        ),
        if (notifications.isNotEmpty && notifications.any((n) => !n.isRead))
          TextButton(
            onPressed: onMarkAllAsRead,
            // FIXED: Moved child property to the end
            child: const Text('Mark All as Read'),
          ),
      ],
    );
  }
}

class NotificationItem {
  final int id;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }
}

const String _baseUrl = 'http://192.168.53.208/backend-lapakulbi/api';

Future<List<NotificationItem>> fetchNotifications(int userId) async {
  final Uri url = Uri.parse('$_baseUrl/notifications.php?user_id=$userId');
  try {
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        List<NotificationItem> notifications = (data['data'] as List)
            .map((item) => NotificationItem.fromJson(item))
            .toList();
        return notifications;
      }
    }
    return [];
  } catch (error) {
    // In a real app, you'd want to log this error to a service
    return [];
  }
}

Future<bool> markNotificationAsRead(int notificationId) async {
  // FIXED: Used the correct base URL
  final Uri url = Uri.parse('$_baseUrl/notifications.php');
  try {
    final response = await http.post(
      url,
      body: jsonEncode({
        'action': 'mark_as_read',
        'notification_id': notificationId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data['status'] == 'success';
  } catch (error) {
    return false;
  }
}

Future<bool> markAllNotificationsAsRead(int userId) async {
  // FIXED: Used the correct base URL
  final Uri url = Uri.parse('$_baseUrl/notifications.php');
  try {
    final response = await http.post(
      url,
      body: jsonEncode({
        'action': 'mark_all_as_read',
        'user_id': userId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data['status'] == 'success';
  } catch (error) {
    return false;
  }
}
