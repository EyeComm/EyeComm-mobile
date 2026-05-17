import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _projectId = 'eyecomm-66bb3';

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging'
  ];

  static Future<void> sendToCaregiver(
      {required String title, required String body}) async {
    try {
      final String response =
          await rootBundle.loadString('assets/firebase_service_account.json');
      final accountCredentials = ServiceAccountCredentials.fromJson(response);

      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      final accessToken = client.credentials.accessToken.data;

      const String endpoint =
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'topic': 'caregiver_alerts',
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'notification': {
              'sound': 'default',
              'notification_priority': 'PRIORITY_MAX',
            }
          }
        }
      };

      final http.Response res = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (res.statusCode == 200) {
        debugPrint('✅ تم إرسال الإشعار بنجاح: $title');
      } else {
        debugPrint('❌ خطأ في الإرسال من السيرفر: ${res.body}');
      }

      client.close();
    } catch (e) {
      debugPrint('❌ حدث خطأ أثناء تجهيز أو إرسال الإشعار: $e');
    }
  }
}
