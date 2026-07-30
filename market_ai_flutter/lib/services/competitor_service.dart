import 'dart:convert';
import 'package:http/http.dart' as http;
import '../server_url.dart';

class CompetitorService {
  static Future<Map<String, dynamic>> analyzeCompetitors({
    required String token,
    required String prompt,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/competitor/analyze'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'prompt': prompt}),
    );
    return jsonDecode(response.body);
  }
}
