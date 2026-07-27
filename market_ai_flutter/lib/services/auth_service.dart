import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../server_url.dart';

class AuthService {
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String email,
    required String industry,
    required String country,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'industry': industry,
        'country': country,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadAvatar({
    required String token,
    required String imagePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/auth/upload-avatar'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    final extension = imagePath.split('.').last.toLowerCase();
    final mimeSub = extension == 'png' ? 'png' : (extension == 'gif' ? 'gif' : 'jpeg');

    request.files.add(await http.MultipartFile.fromPath(
      'avatar',
      imagePath,
      contentType: MediaType('image', mimeSub),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchSocialStatus(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/social-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }
}
