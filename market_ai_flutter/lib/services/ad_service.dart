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
}
