import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class UseAnalysisScreen extends StatelessWidget {
  const UseAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Retrieve the dynamically generated recommended ad structure from route arguments
    final recommendedAd = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final headline = recommendedAd?['headline'] ?? 'Get More Leads for Your Business';
    final primaryText = recommendedAd?['primaryText'] ?? 'We help you grow your business with result-driven digital marketing strategies.';
    final callToAction = recommendedAd?['callToAction'] ?? 'Get Free Consultation';
    final landingPage = recommendedAd?['landingPage'] ?? '/free-consultation';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(
                title: 'Create Ad from Analysis',
                subtitle: "We've created a recommended ad structure\nbased on competitor analysis.",
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 25, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ad Structure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 18),
                          _AdStructureItem(title: 'Headline', value: headline),
                          _AdStructureItem(title: 'Primary Text', value: primaryText),
                          _AdStructureItem(title: 'Call to Action', value: callToAction),
                          _AdStructureItem(title: 'Landing Page', value: landingPage, last: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    PrimaryButton(
                      label: 'Proceed to Ad Setup',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.adSetup,
                        arguments: recommendedAd,
                      ),
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

class _AdStructureItem extends StatelessWidget {
  const _AdStructureItem({required this.title, required this.value, this.last = false});
  final String title;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
