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
    String? socialAccountId,
    String? period,
  }) async {
    final uri = Uri.parse('$baseUrl/api/reports/$type').replace(
      queryParameters: {
        if (adAccountId != null) 'adAccountId': adAccountId,
        if (socialAccountId != null) 'socialAccountId': socialAccountId,
        if (period != null) 'period': period,
      },
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

  static Future<Map<String, dynamic>> fetchSocialAccounts({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reports/social/accounts'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchAdAccounts({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/accounts'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }
}
