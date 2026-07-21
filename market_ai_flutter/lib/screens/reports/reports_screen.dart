import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int tab = 0;

  final reports = const [
    _Report('Competitor Analysis Report', 'May 24, 2024', 'Competitor', Icons.analytics_outlined),
    _Report('Ad Performance Report', 'May 23, 2024', 'Ads', Icons.campaign_outlined),
    _Report('Lead Generation Report', 'May 22, 2024', 'Leads', Icons.people_outline_rounded),
    _Report('ROI Report - May 2024', 'May 21, 2024', 'ROI', Icons.show_chart_rounded),
    _Report('Social Media Report', 'May 20, 2024', 'Ads', Icons.post_add_outlined),
  ];

  List<_Report> get filtered {
    if (tab == 0) return reports;
    final category = ['Competitor', 'Ads', 'ROI', 'Leads'][tab - 1];
    return reports.where((report) => report.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['All Reports', 'Competitor', 'Ads', 'ROI', 'Leads'];
    return Scaffold(
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Reports', subtitle: 'View and download your reports.', showBack: false),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 39,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ChoiceChip(
                  label: Text(tabs[index]),
                  selected: tab == index,
                  showCheckmark: false,
                  selectedColor: AppColors.lavender,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: tab == index ? AppColors.primary : AppColors.border),
                  labelStyle: TextStyle(
                    color: tab == index ? AppColors.primary : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                  onSelected: (_) => setState(() => tab = index),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No reports in this category', style: TextStyle(color: AppColors.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final report = filtered[index];
                        return AppCard(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.reportDetails),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(10)),
                                child: Icon(report.icon, color: AppColors.primary, size: 21),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(report.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 4),
                                    Text(report.date, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => showAppSnackBar(context, '${report.title} downloaded'),
                                icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.muted),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Report {
  const _Report(this.title, this.date, this.category, this.icon);
  final String title;
  final String date;
  final String category;
  final IconData icon;
}
