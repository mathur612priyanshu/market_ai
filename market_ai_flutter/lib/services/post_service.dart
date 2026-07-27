import 'dart:convert';
import 'package:http/http.dart' as http;
import '../server_url.dart';

class PostService {
  static Future<Map<String, dynamic>> generateAiPost({
    required String token,
    required String prompt,
    required String platform,
    required String tone,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/posts/generate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'prompt': prompt,
        'platform': platform,
        'tone': tone,
        'type': type,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> scheduleOrPublishPost({
    required String token,
    required String platform,
    required String caption,
    String? hashtags,
    String? mediaUrl,
    String? scheduledTime,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/posts/schedule'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'platform': platform,
        'caption': caption,
        'hashtags': hashtags,
        'mediaUrl': mediaUrl,
        'scheduledTime': scheduledTime,
      }),
    );
    return jsonDecode(response.body);
  }
}
