import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CompetitorAnalysisScreen extends StatefulWidget {
  const CompetitorAnalysisScreen({super.key});

  @override
  State<CompetitorAnalysisScreen> createState() => _CompetitorAnalysisScreenState();
}

class _CompetitorAnalysisScreenState extends State<CompetitorAnalysisScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Overview', 'Ads', 'Social Media', 'Strengths'];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Competitor Analysis', subtitle: 'Generated on May 24, 2024'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 19, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Competitors', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const _CompetitorRow(rank: '1', name: 'DigiGrowth', handle: '@digigrowth.com'),
                    const _CompetitorRow(rank: '2', name: 'BrandBoost', handle: '@brandboost.in'),
                    const _CompetitorRow(rank: '3', name: 'Clickify', handle: 'clickify.in'),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tabs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 9),
                        itemBuilder: (context, index) => ChoiceChip(
                          label: Text(tabs[index]),
                          selected: tab == index,
                          onSelected: (_) => setState(() => tab = index),
                          showCheckmark: false,
                          selectedColor: AppColors.lavender,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: tab == index ? AppColors.primary : AppColors.border),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: tab == index ? AppColors.primary : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(tabs[tab], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      _tabDescription(tab),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
                    ),
                    const SizedBox(height: 17),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.8,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: const [
                        _AnalysisMetric(label: 'Total Ads', value: '128'),
                        _AnalysisMetric(label: 'Est. Monthly Spend', value: '₹45,000'),
                        _AnalysisMetric(label: 'Avg. Engagement', value: '3.8%'),
                        _AnalysisMetric(label: 'Ad Strategy', value: 'Lead Generation'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Summary', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    const Text(
                      'Your competitors are focusing on lead generation campaigns with strong social media presence and high-frequency ad delivery.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.55),
                    ),
                    const SizedBox(height: 25),
                    PrimaryButton(
                      label: 'Use This Analysis',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.useAnalysis),
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

  String _tabDescription(int index) {
    switch (index) {
      case 1:
        return 'Review ad volume, spend estimates, campaign frequency, and the formats competitors use most.';
      case 2:
        return 'Compare audience growth, publishing activity, engagement, and platform presence.';
      case 3:
        return 'See the messaging, offers, channels, and creative patterns that give competitors an advantage.';
      default:
        return "Here's the complete overview of your top competitors.";
    }
  }
}

class _CompetitorRow extends StatelessWidget {
  const _CompetitorRow({required this.rank, required this.name, required this.handle});
  final String rank;
  final String name;
  final String handle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: AppColors.lavender,
        child: Text(rank, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11)),
      ),
      title: Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
      subtitle: Text(handle, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
    );
  }
}

class _AnalysisMetric extends StatelessWidget {
  const _AnalysisMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10.5)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
