import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Report Detail'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: AppColors.lavender,
                          child: Icon(Icons.analytics_outlined, color: AppColors.primary),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Competitor Analysis Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              SizedBox(height: 3),
                              Text('May 24, 2024', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Text('Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text(
                      'Your competitors are investing more in lead generation ads with strong social presence.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.55),
                    ),
                    const SizedBox(height: 24),
                    const Text('Key Insights', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    const _Insight(text: 'High ad frequency'),
                    const _Insight(text: 'Focus on lead magnets'),
                    const _Insight(text: 'Strong use of testimonials'),
                    const _Insight(text: 'Active on Facebook & Instagram'),
                    const SizedBox(height: 30),
                    const Text('Download Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showAppSnackBar(context, 'PDF report downloaded'),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('PDF'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              backgroundColor: const Color(0xFFFFF0F2),
                              side: const BorderSide(color: Color(0xFFFFCDD3)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showAppSnackBar(context, 'Excel report downloaded'),
                            icon: const Icon(Icons.table_chart_outlined),
                            label: const Text('Excel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              backgroundColor: const Color(0xFFEAF8F2),
                              side: const BorderSide(color: Color(0xFFBDE7D7)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
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

class _Insight extends StatelessWidget {
  const _Insight({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 19),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
