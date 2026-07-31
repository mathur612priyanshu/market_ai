import 'dart:convert';
import 'package:http/http.dart' as http;
import '../server_url.dart';

class AdService {
  static Future<Map<String, dynamic>> createAdCampaign({
    required String token,
    required String adAccountId,
    required String campaignName,
    required String objective,
    required String budget,
    required String headline,
    required String primaryText,
    required String creativeUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/create-campaign'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'adAccountId': adAccountId,
        'campaignName': campaignName,
        'objective': objective,
        'budget': budget,
        'headline': headline,
        'primaryText': primaryText,
        'creativeUrl': creativeUrl,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchAdCampaigns({
    required String token,
    required String adAccountId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/campaigns?adAccountId=$adAccountId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> toggleCampaignStatus({
    required String token,
    required String campaignId,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/campaigns/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'campaignId': campaignId,
        'status': status,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> duplicateCampaign({
    required String token,
    required String campaignId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/campaigns/duplicate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'campaignId': campaignId,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> editCampaign({
    required String token,
    required String campaignId,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/campaigns/edit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'campaignId': campaignId,
        'name': name,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCampaignInsights({
    required String token,
    required String campaignId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/campaigns/insights?campaignId=$campaignId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }
}
