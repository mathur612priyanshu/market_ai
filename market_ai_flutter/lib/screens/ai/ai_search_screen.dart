import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../services/competitor_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final controller = TextEditingController(text: 'Suggest dynamic social media content ideas for my niche');
  bool isLoading = false;
  Map<String, dynamic>? searchResults;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (controller.text.trim().isEmpty) {
      showAppSnackBar(context, 'Describe what you want MarketAI to analyze');
      return;
    }

    final token = ref.read(authProvider).token;
    if (token == null) {
      showAppSnackBar(context, 'Session expired. Please login again.');
      return;
    }

    setState(() {
      isLoading = true;
      searchResults = null;
    });

    try {
      final res = await CompetitorService.performAiSearch(
        token: token,
        prompt: controller.text.trim(),
      );

      if (res['success'] == true && res['results'] != null) {
        if (mounted) {
          setState(() {
            searchResults = Map<String, dynamic>.from(res['results']);
          });
        }
      } else {
        if (mounted) {
          if (res['error'] == 'paywall_block') {
            showPaywallDialog(context, res['message'] ?? 'Quota limit reached.');
          } else {
            showAppSnackBar(context, res['error'] ?? 'Search failed. Please try again.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error running AI search: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final examples = [
      'Suggest local ad strategies for my shop',
      'High-impact keyword suggestions for my service',
      'Explain content formats to double my CTR',
      'What social channels work best for my industry?',
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(
                title: 'AI Search',
                subtitle: 'Ask anything about your business,\ncompetitors, or marketing.',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                      borderColor: AppColors.primary,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              minLines: 3,
                              maxLines: 5,
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                hintText: 'Ask MarketAI...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: isLoading ? null : _analyze,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, color: Colors.white, size: 21),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Dynamic Search Results Card
                    if (searchResults != null) ...[
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        borderColor: AppColors.primary.withOpacity(0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'MarketAI Response',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.text),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              searchResults!['summary']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.text),
                            ),
                            if (searchResults!['insights'] != null) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Key Insights',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                              const SizedBox(height: 8),
                              ...(searchResults!['insights'] as List<dynamic>).map(
                                (ins) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ins.toString(),
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.text),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (searchResults!['recommendations'] != null) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Recommended Actions',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                              const SizedBox(height: 8),
                              ...(searchResults!['recommendations'] as List<dynamic>).map(
                                (rec) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.tips_and_updates_outlined, color: Colors.orangeAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          rec.toString(),
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.text),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    const Text('Try these examples', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 11),
                    ...examples.map(
                      (example) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          onTap: isLoading
                              ? null
                              : () {
                                  controller.text = example;
                                  controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                },
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_outlined, size: 18, color: AppColors.muted),
                              const SizedBox(width: 10),
                              Expanded(child: Text(example, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                            ],
                          ),
                        ),
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
