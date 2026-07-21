import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AiSearchScreen extends StatefulWidget {
  const AiSearchScreen({super.key});

  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen> {
  final controller = TextEditingController(text: 'Analyze my top 3 competitors and suggest ad strategy');

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _analyze() {
    if (controller.text.trim().isEmpty) {
      showAppSnackBar(context, 'Describe what you want MarketAI to analyze');
      return;
    }
    Navigator.pushNamed(context, AppRoutes.competitorAnalysis);
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
                            onTap: _analyze,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 21),
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
                          onTap: () {
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
