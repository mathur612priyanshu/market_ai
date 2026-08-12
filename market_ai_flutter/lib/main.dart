import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/onboarding/otp_verification_screen.dart';
import 'screens/onboarding/profile_information_screen.dart';
import 'screens/onboarding/social_connect_screen.dart';
import 'screens/onboarding/business_details_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/ai/ai_search_screen.dart';
import 'screens/ai/competitor_analysis_screen.dart';
import 'screens/ai/use_analysis_screen.dart';
import 'screens/ai/create_campaign_screen.dart';
import 'screens/ai/create_adset_screen.dart';
import 'screens/ai/create_ad_screen.dart';
import 'screens/ai/campaign_management_screen.dart';
import 'screens/ai/campaign_adsets_screen.dart';
import 'screens/ai/adset_ads_screen.dart';
import 'screens/ai/ai_post_creator_screen.dart';
import 'screens/ai/generated_post_screen.dart';
import 'screens/ai/schedule_post_screen.dart';
import 'screens/business/leads_screen.dart';
import 'screens/business/roi_tracker_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/reports/report_details_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/subscription_plan_screen.dart';
import 'screens/settings/help_support_screen.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  String initialRoute = AppRoutes.login;

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token != null && userJson != null) {
      final user = jsonDecode(userJson);
      container.read(authProvider.notifier).setSession(token, user);
      
      // Navigate to profile screen if name is empty, otherwise straight to dashboard
      if (user['name'] != null && user['name'].toString().isNotEmpty) {
        initialRoute = AppRoutes.dashboard;
      } else {
        initialRoute = AppRoutes.profile;
      }
    }
  } catch (e) {
    debugPrint('Error restoring user session: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MarketAiApp(initialRoute: initialRoute),
    ),
  );
}

class MarketAiApp extends StatelessWidget {
  const MarketAiApp({super.key, this.initialRoute = AppRoutes.login});
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.otp: (_) => const OtpVerificationScreen(),
        AppRoutes.profile: (_) => const ProfileInformationScreen(),
        AppRoutes.socialConnect: (_) => const SocialConnectScreen(),
        AppRoutes.businessDetails: (_) => const BusinessDetailsScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.aiSearch: (_) => const AiSearchScreen(),
        AppRoutes.competitorAnalysis: (_) => const CompetitorAnalysisScreen(),
        AppRoutes.useAnalysis: (_) => const UseAnalysisScreen(),
        AppRoutes.adSetup: (_) => const CreateCampaignScreen(),
        AppRoutes.createAdSet: (_) => const CreateAdSetScreen(),
        AppRoutes.createAd: (_) => const CreateAdScreen(),
        AppRoutes.campaignManagement: (_) => const CampaignManagementScreen(),
        AppRoutes.campaignAdSets: (_) => const CampaignAdSetsScreen(),
        AppRoutes.adsetAds: (_) => const AdSetAdsScreen(),
        AppRoutes.aiPostCreator: (_) => const AiPostCreatorScreen(),
        AppRoutes.generatedPost: (_) => const GeneratedPostScreen(),
        AppRoutes.schedulePost: (_) => const SchedulePostScreen(),
        AppRoutes.leads: (_) => const LeadsManagerScreen(),
        AppRoutes.roiTracker: (_) => const RoiTrackerScreen(),
        AppRoutes.reports: (_) => const ReportsScreen(),
        AppRoutes.reportDetails: (_) => const ReportDetailsScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.subscription: (_) => const SubscriptionPlanScreen(),
        AppRoutes.helpSupport: (_) => const HelpSupportScreen(),
      },
    );
  }
}