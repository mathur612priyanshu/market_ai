import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../../server_url.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int tab = 0;
  List<dynamic> reports = [];
  bool isLoading = true;
  String _accountName = 'Loading...';
  String? _adAccountId;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => isLoading = true);
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('ad_account_id') ?? 'act_123456789';

      final res = await ReportService.fetchReports(token: token, adAccountId: savedId);
      if (res['success'] == true && mounted) {
        setState(() {
          reports = res['reports'] ?? [];
          _accountName = res['accountName']?.toString() ?? 'Demo Ad Account';
          _adAccountId = savedId;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<dynamic> get filtered {
    if (tab == 0) return reports;
    final category = ['Competitor', 'Ads', 'ROI', 'Leads'][tab - 1];
    return reports.where((report) => report['category'] == category).toList();
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'analytics_outlined':
        return Icons.analytics_outlined;
      case 'campaign_outlined':
        return Icons.campaign_outlined;
      case 'people_outline_rounded':
        return Icons.people_outline_rounded;
      case 'show_chart_rounded':
        return Icons.show_chart_rounded;
      case 'post_add_outlined':
        return Icons.post_add_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _downloadReport(String reportId) async {
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final url = '$baseUrl/api/reports/$reportId/download?token=$token&adAccountId=${_adAccountId ?? ""}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          showAppSnackBar(context, 'Report download started.');
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, 'Could not start download.');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Download error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['All Reports', 'Competitor', 'Ads', 'ROI', 'Leads'];
    return Scaffold(
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Reports', subtitle: 'View reports for • $_accountName', showBack: false),
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filtered.isEmpty
                      ? const Center(child: Text('No reports in this category', style: TextStyle(color: AppColors.muted)))
                      : RefreshIndicator(
                          onRefresh: _fetchReports,
                          color: AppColors.primary,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final report = filtered[index];
                              final id = report['id']?.toString() ?? '';
                              final title = report['title']?.toString() ?? 'Report';
                              final date = report['date']?.toString() ?? '';
                              final description = report['description']?.toString() ?? '';
                              final icon = _getIcon(report['iconName']?.toString());

                              return AppCard(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.reportDetails,
                                    arguments: {
                                      'id': id,
                                      'title': title,
                                      'iconName': report['iconName']?.toString() ?? '',
                                      'adAccountId': _adAccountId,
                                    },
                                  );
                                },
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(10)),
                                      child: Icon(icon, color: AppColors.primary, size: 21),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 4),
                                          Text(description.isNotEmpty ? description : date, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _downloadReport(id),
                                      icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
