import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission (Apple & Web required, Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Get the token
    String? token = await _fcm.getToken();
    if (kDebugMode) {
      if (kDebugMode) print("FCM Token: $token");
    }

    // Subscribe to All Users topic for Notices
    await _fcm.subscribeToTopic('all_users');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      }
    });

    // Handle background taps
    setupInteractedMessage();
  }

  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from a terminated state.
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (kDebugMode) {
      if (kDebugMode) print("Notification Tapped: ${message.data}");
    }
    // TODO: Navigate to ChatScreen if type == 'chat'
    // We can use a GlobalKey<NavigatorState> to navigate from here if needed,
    // or just let the user land on Home/ChatList.
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  static Future<bool> sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final String serverKey = dotenv.env['FCM_SERVER_KEY'] ?? "";
      if (serverKey.isEmpty) {
        if (kDebugMode) print("FCM Server Key not found");
        return false;
      }

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'priority': 'high',
          'notification': {'title': title, 'body': body, 'sound': 'default'},
          'data': data,
        }),
      );

      if (kDebugMode) {
        if (kDebugMode)
          print('FCM Response: ${response.statusCode} ${response.body}');
      }
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Send Push Error: $e");
      return false;
    }
  }
}
