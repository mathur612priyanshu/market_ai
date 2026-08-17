import 'dart:convert';
import 'package:http/http.dart' as http;
import '../server_url.dart';

class ReportService {
  static Future<Map<String, dynamic>> fetchReports({
    required String token,
    String? adAccountId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/reports').replace(
      queryParameters: adAccountId != null ? {'adAccountId': adAccountId} : null,
    );
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchReportDetails({
    required String token,
    required String type,
    String? adAccountId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/reports/$type').replace(
      queryParameters: adAccountId != null ? {'adAccountId': adAccountId} : null,
    );
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }
}
