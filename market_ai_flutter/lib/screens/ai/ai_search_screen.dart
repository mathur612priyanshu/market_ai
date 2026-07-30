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
  final controller = TextEditingController(text: 'Analyze my top 3 competitors and suggest ad strategy');
  bool isLoading = false;

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

    setState(() => isLoading = true);
    try {
      final res = await CompetitorService.analyzeCompetitors(
        token: token,
        prompt: controller.text.trim(),
      );

      if (res['success'] == true && res['analysis'] != null) {
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.competitorAnalysis,
            arguments: Map<String, dynamic>.from(res['analysis']),
          );
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Analysis failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error running competitor analysis: $e');
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
      'Analyze my competitors',
      'Best ad strategy for my business',
      'Improve my ROI',
      'Content ideas for social media',
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'AI Search', subtitle: 'Ask anything about your business,\ncompetitors, or marketing.'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
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
                    const SizedBox(height: 30),
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
