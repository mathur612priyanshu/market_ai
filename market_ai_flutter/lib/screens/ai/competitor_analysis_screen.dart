import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<dynamic> watchlist = [];
  String? errorMessage;
  bool isFirstLoad = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        analysis = routeArgs['analysis'] != null ? Map<String, dynamic>.from(routeArgs['analysis']) : routeArgs;
        watchlist = routeArgs['watchlist'] != null ? List<dynamic>.from(routeArgs['watchlist']) : [];
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
          watchlist = List<dynamic>.from(res['watchlist'] ?? []);
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

  Future<void> _runCustomAnalysis(String prompt) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final res = await CompetitorService.analyzeCompetitors(
        token: token,
        prompt: prompt,
      );

      if (res['success'] == true && res['analysis'] != null && mounted) {
        setState(() {
          analysis = Map<String, dynamic>.from(res['analysis']);
          watchlist = List<dynamic>.from(res['watchlist'] ?? []);
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

  Widget _buildAdSpyGallery() {
    if (watchlist.isEmpty) {
      if (isLoading) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.lavender.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Column(
              children: [
                CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                SizedBox(height: 12),
                Text(
                  'Analyzing and crawling competitor ads...',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'No competitor ads crawled yet. Try searching for a real competitor brand above!',
              style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Competitor Ad Watchlist',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...watchlist.map((item) {
          final ads = item['ads'] as List<dynamic>? ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        item['rank']?.toString() ?? '1',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['name'] ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item['handle'] ?? '',
                        style: const TextStyle(fontSize: 10, color: AppColors.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (ads.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No active ads found for this competitor.', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final ad = ads[idx];
                    final activeDays = ad['activeDays'] ?? 0;
                    final isWinning = activeDays >= 30;

                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.lavender,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ad['mediaType']?.toString().toUpperCase() ?? 'IMAGE',
                                      style: const TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active: $activeDays days',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.muted),
                                  ),
                                ],
                              ),
                              if (isWinning)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    border: Border.all(color: const Color(0xFFFFD54F)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.emoji_events_outlined, color: Color(0xFFF57F17), size: 10),
                                      SizedBox(width: 3),
                                      Text(
                                        'Winning Ad',
                                        style: TextStyle(color: Color(0xFFF57F17), fontSize: 8, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (ad['mediaUrl'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                ad['mediaUrl'],
                                height: 130,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            ad['caption'] ?? '',
                            style: const TextStyle(fontSize: 11.5, height: 1.45, color: Colors.black87),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _showAdBreakdown(ad),
                                  icon: const Icon(Icons.psychology_outlined, size: 14, color: AppColors.primary),
                                  label: const Text('AI Breakdown', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    backgroundColor: AppColors.lavender,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final url = ad['landingPageUrl']?.toString() ?? 'https://www.facebook.com/ads/library';
                                    final uri = Uri.parse(url);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: const Icon(Icons.launch_rounded, size: 13, color: AppColors.muted),
                                  label: Text(
                                    ad['ctaText']?.toString() ?? 'Landing Page',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.muted),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  void _showAdBreakdown(dynamic ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Ad Spy Breakdown',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Creative Hook & Offer Intelligence',
                          style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Extracted Hook', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ad['adHook']?.toString() ?? 'Direct product introduction hook.',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Detected Promotional Offer', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ad['offer']?.toString() ?? 'No specific coupon code or promotion found.',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Messaging Angle', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                ad['angle']?.toString() ?? 'Pain point comparisons targeting industry standard workflows.',
                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 22),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              const Text('AI Strategic Recommendation', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Based on this competitor\'s high active duration (${ad['activeDays']} days), their "${ad['adHook']}" angle is working well. '
                      'Since your current ad creative style is text-centric, we recommend testing a similar structured layout with a bold headline, using a direct "${ad['ctaText']}" action button to drive leads.',
                      style: const TextStyle(fontSize: 11.5, height: 1.5, fontStyle: FontStyle.italic, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              PrimaryButton(
                label: 'Close Analysis',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
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
              mainAxisAlignment:  MainAxisAlignment.center,
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
                    // Search Bar directly on the screen
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: const InputDecoration(
                                hintText: 'Search competitor brand (e.g. Swiggy, Nike)...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  _runCustomAnalysis(val.trim());
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 18),
                            onPressed: () {
                              final val = _searchController.text.trim();
                              if (val.isNotEmpty) {
                                _runCustomAnalysis(val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 15),
                    
                    if (tab == 1) ...[
                      _buildAdSpyGallery(),
                      const SizedBox(height: 15),
                    ],

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
                    // "Use This Analysis" Button is commented out as requested
                    // PrimaryButton(
                    //   label: 'Use This Analysis',
                    //   onPressed: () => Navigator.pushNamed(
                    //     context,
                    //     AppRoutes.useAnalysis,
                    //     arguments: recommendedAd,
                    //   ),
                    // ),
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
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 60,
            ),
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
                Flexible(
                  child: Text(
                    s.toString(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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
      trailing: TextButton.icon(
        onPressed: () async {
          final query = Uri.encodeComponent(name);
          final url = 'https://www.facebook.com/ads/library/?active_status=all&ad_type=all&q=$query&search_type=keyword_unordered';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            showAppSnackBar(context, 'Could not open Facebook Ads Library');
          }
        },
        icon: const Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.primary),
        label: const Text('View Ads', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          backgroundColor: AppColors.lavender,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
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
