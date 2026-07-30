import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdSetupScreen extends ConsumerStatefulWidget {
  const AdSetupScreen({super.key});

  @override
  ConsumerState<AdSetupScreen> createState() => _AdSetupScreenState();
}

class _AdSetupScreenState extends ConsumerState<AdSetupScreen> {
  final campaignNameController = TextEditingController();
  final adAccountIdController = TextEditingController(text: 'act_');
  String objective = 'Lead Generation';
  String budget = '₹500 / day';
  String duration = '7 Days';
  bool isInitialized = false;

  String headline = '';
  String primaryText = '';
  String creativeUrl = '';
  bool isRunningAd = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      // 1. Retrieve suggested ad structure to pre-fill details
      final recommendedAd = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (recommendedAd != null) {
        headline = recommendedAd['headline'] ?? 'Get More Leads for Your Business';
        primaryText = recommendedAd['primaryText'] ?? 'We help you grow your business with digital marketing strategies.';
        creativeUrl = recommendedAd['creativeUrl'] ?? ''; // backend will fallback if empty

        campaignNameController.text = 'Campaign - $headline';
        
        final cta = recommendedAd['callToAction']?.toString().toLowerCase() ?? '';
        if (cta.contains('lead') || cta.contains('signup')) {
          objective = 'Lead Generation';
        } else if (cta.contains('sale') || cta.contains('buy') || cta.contains('shop')) {
          objective = 'Sales';
        } else if (cta.contains('visit') || cta.contains('learn') || cta.contains('read')) {
          objective = 'Website Traffic';
        } else {
          objective = 'Brand Awareness';
        }
      } else {
        campaignNameController.text = 'Leads Campaign - May 2024';
        headline = 'Special Offer';
        primaryText = 'Check out our services!';
      }
      isInitialized = true;
    }
  }

  @override
  void dispose() {
    campaignNameController.dispose();
    adAccountIdController.dispose();
    super.dispose();
  }

  Future<void> _runAd() async {
    final adAccountId = adAccountIdController.text.trim();
    if (adAccountId.isEmpty || adAccountId == 'act_') {
      showAppSnackBar(context, 'Please enter your Meta Ad Account ID (e.g. act_12345678)');
      return;
    }

    final token = ref.read(authProvider).token;
    if (token == null) {
      showAppSnackBar(context, 'Session expired. Please login again.');
      return;
    }

    setState(() => isRunningAd = true);
    try {
      final res = await AdService.createAdCampaign(
        token: token,
        adAccountId: adAccountId,
        campaignName: campaignNameController.text.trim(),
        objective: objective,
        budget: budget,
        headline: headline,
        primaryText: primaryText,
        creativeUrl: creativeUrl,
      );

      if (res['success'] == true) {
        if (mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
              title: const Text('Campaign Launched!'),
              content: Text(
                'Campaign successfully created on Meta Ads Manager.\n\n'
                'Campaign ID:\n${res['campaignId']}\n\n'
                'Ad Set ID:\n${res['adsetId']}\n\n'
                'Ad ID:\n${res['adId']}\n\n'
                'Status: Created as PAUSED so you can review before starting spend.',
                style: const TextStyle(fontSize: 11.5),
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to use analysis
                    Navigator.pop(context); // Go back to analysis report
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Campaign creation failed.');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error launching ad campaign: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isRunningAd = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Ad Setup', subtitle: 'Review and run your ad campaign.'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel('Ad Account ID (e.g. act_101593...)'),
                    TextField(
                      controller: adAccountIdController,
                      enabled: !isRunningAd,
                      decoration: const InputDecoration(hintText: 'Enter act_ followed by Ad Account ID'),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Campaign Name'),
                    TextField(
                      controller: campaignNameController,
                      enabled: !isRunningAd,
                      decoration: const InputDecoration(hintText: 'Enter Campaign Name'),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Objective'),
                    DropdownButtonFormField<String>(
                      value: objective,
                      items: ['Lead Generation', 'Website Traffic', 'Brand Awareness', 'Sales']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: isRunningAd ? null : (value) => setState(() => objective = value ?? objective),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Audience'),
                    const TextField(decoration: InputDecoration(hintText: 'Business Owners, 25-45, India')),
                    const SizedBox(height: 14),
                    const FormLabel('Budget'),
                    DropdownButtonFormField<String>(
                      value: budget,
                      items: ['₹500 / day', '₹1,000 / day', '₹2,500 / day']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: isRunningAd ? null : (value) => setState(() => budget = value ?? budget),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Duration'),
                    DropdownButtonFormField<String>(
                      value: duration,
                      items: ['7 Days', '14 Days', '30 Days']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: isRunningAd ? null : (value) => setState(() => duration = value ?? duration),
                    ),
                    const SizedBox(height: 17),
                    const FormLabel('Placements'),
                    const Row(
                      children: [
                        TinyPlatformIcon(type: 'facebook'),
                        SizedBox(width: 12),
                        TinyPlatformIcon(type: 'instagram'),
                        SizedBox(width: 12),
                        TinyPlatformIcon(type: 'google'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: isRunningAd ? 'Launching Campaign...' : 'Review & Run Ad',
                      onPressed: isRunningAd ? null : _runAd,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
