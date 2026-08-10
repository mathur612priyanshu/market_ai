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
    String? startTime,
    String? endTime,
    String? targetingCountry,
    int? ageMin,
    int? ageMax,
    String? gender,
    List<Map<String, dynamic>>? selectedLocations,
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
        'startTime': startTime,
        'endTime': endTime,
        'targetingCountry': targetingCountry ?? 'IN',
        'ageMin': ageMin ?? 18,
        'ageMax': ageMax ?? 65,
        'gender': gender ?? 'ALL',
        'selectedLocations': selectedLocations,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createCampaignOnly({
    required String token,
    required String adAccountId,
    required String campaignName,
    required String objective,
    required String specialAdCategory,
    required bool useCampaignBudget,
    String? campaignBudget,
    String? bidStrategy,
    String? bidAmount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/campaigns/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'adAccountId': adAccountId,
        'campaignName': campaignName,
        'objective': objective,
        'specialAdCategory': specialAdCategory,
        'useCampaignBudget': useCampaignBudget,
        'campaignBudget': campaignBudget,
        'bidStrategy': bidStrategy,
        'bidAmount': bidAmount,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createAdSetOnly({
    required String token,
    required String adAccountId,
    required String campaignId,
    required String adSetName,
    String? budget,
    required List<Map<String, dynamic>> selectedLocations,
    required int ageMin,
    required int ageMax,
    required String gender,
    required String objective,
    String? destinationType,
    String? engagementType,
    String? appId,
    String? appStoreUrl,
    String? pixelId,
    String? conversionEvent,
    String? startTime,
    String? endTime,
    String? bidAmount,
    String? bidStrategy,
    required bool useCampaignBudget,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/adsets/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'adAccountId': adAccountId,
        'campaignId': campaignId,
        'adSetName': adSetName,
        'budget': budget,
        'selectedLocations': selectedLocations,
        'ageMin': ageMin,
        'ageMax': ageMax,
        'gender': gender,
        'objective': objective,
        'destinationType': destinationType,
        'engagementType': engagementType,
        'appId': appId,
        'appStoreUrl': appStoreUrl,
        'pixelId': pixelId,
        'conversionEvent': conversionEvent,
        'startTime': startTime,
        'endTime': endTime,
        'bidAmount': bidAmount,
        'bidStrategy': bidStrategy,
        'useCampaignBudget': useCampaignBudget,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createAdOnly({
    required String token,
    required String adAccountId,
    required String adsetId,
    required String adName,
    required String headline,
    required String primaryText,
    required String creativeUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/ads/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'adAccountId': adAccountId,
        'adsetId': adsetId,
        'adName': adName,
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

  static Future<Map<String, dynamic>> fetchDashboardStats({
    required String token,
    required String adAccountId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/dashboard-stats?adAccountId=$adAccountId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchUserAdAccounts({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/accounts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> searchGeolocation({
    required String token,
    required String query,
    String? type,
  }) async {
    final url = '$baseUrl/api/ads/search-geolocation?q=${Uri.encodeComponent(query)}'
        '${type != null ? '&type=$type' : ''}';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    try {
      return jsonDecode(response.body);
    } catch (e) {
      final bodySnippet = response.body.length > 120
          ? response.body.substring(0, 120)
          : response.body;
      throw FormatException('Server error (${response.statusCode}): $bodySnippet');
    }
  }

  static Future<Map<String, dynamic>> fetchAdvertisableApps({
    required String token,
    required String adAccountId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/accounts/$adAccountId/apps'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchAdSetsForCampaign({
    required String token,
    required String campaignId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/campaigns/$campaignId/adsets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchAdsForAdSet({
    required String token,
    required String adsetId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/adsets/$adsetId/ads'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchRoiStats({
    required String token,
    required String adAccountId,
    required String period,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/roi-stats?adAccountId=$adAccountId&period=$period'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchLeads({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ads/leads'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateLeadStatus({
    required String token,
    required String leadId,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ads/leads/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'leadId': leadId,
        'status': status,
      }),
    );
    return jsonDecode(response.body);
  }
}
