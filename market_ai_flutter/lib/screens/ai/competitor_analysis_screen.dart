import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../services/competitor_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CompetitorAnalysisScreen extends ConsumerStatefulWidget {
  const CompetitorAnalysisScreen({super.key});

  @override
  ConsumerState<CompetitorAnalysisScreen> createState() => _CompetitorAnalysisScreenState();
}

class _CompetitorAnalysisScreenState extends ConsumerState<CompetitorAnalysisScreen> {
  int tab = 0;
  bool isLoading = false;
  Map<String, dynamic>? analysis;
  String? errorMessage;
  bool isFirstLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isFirstLoad) {
      _runAnalysis();
      isFirstLoad = false;
    }
  }

  Future<void> _runAnalysis() async {
    final routeArgs = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (routeArgs != null) {
      setState(() {
        analysis = routeArgs;
        isLoading = false;
        errorMessage = null;
      });
      return;
    }

    final token = ref.read(authProvider).token;
    if (token == null) {
      setState(() {
        errorMessage = 'Session expired. Please login again.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final res = await CompetitorService.analyzeCompetitors(
        token: token,
        prompt: 'Analyze competitors automatically based on profile',
      );

      if (res['success'] == true && res['analysis'] != null && mounted) {
        setState(() {
          analysis = Map<String, dynamic>.from(res['analysis']);
        });
      } else {
        if (mounted) {
          setState(() {
            errorMessage = res['error'] ?? 'Failed to load competitor analysis report.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error running competitor analysis: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Analyzing competitors with MarketAI...',
                style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _runAnalysis,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = analysis;

    // Fallback Mock Payload if screen is opened directly or without arguments
    final competitors = data?['competitors'] as List<dynamic>? ?? const [
      {'name': 'DigiGrowth', 'handle': '@digigrowth.com', 'rank': '1'},
      {'name': 'BrandBoost', 'handle': '@brandboost.in', 'rank': '2'},
      {'name': 'Clickify', 'handle': 'clickify.in', 'rank': '3'}
    ];

    final metrics = data?['metrics'] as Map<String, dynamic>? ?? const {
      'totalAds': '128',
      'monthlySpend': '₹45,000',
      'engagementRate': '3.8%',
      'adStrategy': 'Lead Generation'
    };

    final tabs = const ['Overview', 'Ads', 'Social Media', 'Strengths'];

    final swot = data?['swot'] as Map<String, dynamic>? ?? const {
      'strengths': ['Established local presence', 'Good organic reach'],
      'weaknesses': ['No regular video content', 'Slow response times'],
      'opportunities': ['Leverage TikTok and Reels', 'Start direct consultations'],
      'threats': ['Saturated ads market', 'High cost per click']
    };

    final audienceSuggestions = data?['audienceSuggestions'] as List<dynamic>? ?? const [
      'Business Owners',
      'Marketing Managers',
      'Local Shop Owners'
    ];

    final recommendedAd = data?['recommendedAd'] as Map<String, dynamic>? ?? const {
      'headline': 'Get More Leads for Your Business',
      'primaryText': 'We help you grow your business with result-driven digital marketing strategies.',
      'callToAction': 'Get Free Consultation',
      'landingPage': '/free-consultation'
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Competitor Analysis', subtitle: 'AI-Powered Business Intelligence'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 19, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Discovered Competitors', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...competitors.map((c) => _CompetitorRow(
                      rank: c['rank']?.toString() ?? '1',
                      name: c['name'] ?? '',
                      handle: c['handle'] ?? '',
                    )),
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
                      _getTabDescription(tab, data),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
                    ),
                    const SizedBox(height: 17),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _AnalysisMetric(label: 'Total Ads', value: metrics['totalAds'] ?? '0'),
                        _AnalysisMetric(label: 'Est. Monthly Spend', value: metrics['monthlySpend'] ?? 'N/A'),
                        _AnalysisMetric(label: 'Avg. Engagement', value: metrics['engagementRate'] ?? 'N/A'),
                        _AnalysisMetric(label: 'Ad Strategy', value: metrics['adStrategy'] ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    
                    // SWOT Summary Section
                    _buildSwotGrid(swot),
                    const SizedBox(height: 22),

                    // Target Audience Suggestions Section
                    _buildAudienceSuggestions(audienceSuggestions),
                    const SizedBox(height: 22),

                    const Text('Summary', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    Text(
                      analysis?['summary'] ?? 'Your competitors are focusing on lead generation campaigns with strong social media presence and high-frequency ad delivery.',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.55),
                    ),
                    const SizedBox(height: 25),
                    PrimaryButton(
                      label: 'Use This Analysis',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.useAnalysis,
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

  String _getTabDescription(int index, Map<String, dynamic>? analysis) {
    if (analysis != null && analysis['tabs'] != null) {
      final tabs = analysis['tabs'];
      switch (index) {
        case 1:
          return tabs['ads'] ?? '';
        case 2:
          return tabs['socialMedia'] ?? '';
        case 3:
          return tabs['strengths'] ?? '';
        default:
          return tabs['overview'] ?? '';
      }
    }

    // Default static mock descriptions if no arguments
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

  Widget _buildSwotGrid(Map<String, dynamic> swot) {
    final strengths = List<String>.from(swot['strengths'] ?? []);
    final weaknesses = List<String>.from(swot['weaknesses'] ?? []);
    final opportunities = List<String>.from(swot['opportunities'] ?? []);
    final threats = List<String>.from(swot['threats'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SWOT Analysis', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SwotCard(
                  title: 'Strengths',
                  items: strengths,
                  bgColor: const Color(0xFFE8F5E9),
                  textColor: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SwotCard(
                  title: 'Weaknesses',
                  items: weaknesses,
                  bgColor: const Color(0xFFFFEBEE),
                  textColor: const Color(0xFFC62828),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SwotCard(
                  title: 'Opportunities',
                  items: opportunities,
                  bgColor: const Color(0xFFE3F2FD),
                  textColor: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SwotCard(
                  title: 'Threats',
                  items: threats,
                  bgColor: const Color(0xFFFFF3E0),
                  textColor: const Color(0xFFEF6C00),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudienceSuggestions(List<dynamic> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Audience Suggestions', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_pin_circle_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  s.toString(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label, 
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value, 
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwotCard extends StatelessWidget {
  const _SwotCard({
    required this.title,
    required this.items,
    required this.bgColor,
    required this.textColor,
  });

  final String title;
  final List<String> items;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 10, color: Colors.black87, height: 1.3),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
