import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../../server_url.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ReportDetailsScreen extends ConsumerStatefulWidget {
  const ReportDetailsScreen({super.key});

  @override
  ConsumerState<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  String _errorMsg = '';
  String _accountName = 'Loading...';
  String? _adAccountId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reportData == null && _errorMsg.isEmpty) {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final reportId = args?['id']?.toString() ?? 'competitor';
    final savedAdAccountId = args?['adAccountId']?.toString();

    setState(() {
      _isLoading = true;
      _errorMsg = '';
      _adAccountId = savedAdAccountId;
    });

    try {
      final token = ref.read(authProvider).token;
      if (token == null) {
        setState(() {
          _errorMsg = 'Auth token missing';
          _isLoading = false;
        });
        return;
      }

      final res = await ReportService.fetchReportDetails(token: token, type: reportId, adAccountId: savedAdAccountId);
      if (res['success'] == true && mounted) {
        setState(() {
          _reportData = res['report'];
          _accountName = res['accountName']?.toString() ?? 'Demo Ad Account';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = res['error']?.toString() ?? 'Failed to load report details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
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

  Future<void> _downloadReport(String format) async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final reportId = args?['id']?.toString() ?? 'competitor';

    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final url = '$baseUrl/api/reports/$reportId/download?token=$token&format=$format&adAccountId=${_adAccountId ?? ""}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          showAppSnackBar(context, '$format report download started.');
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final reportTitle = args?['title']?.toString() ?? 'Report Detail';
    final iconName = args?['iconName']?.toString() ?? 'analytics_outlined';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: reportTitle),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _errorMsg.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMsg, style: const TextStyle(color: AppColors.danger)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchDetails,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 21,
                                    backgroundColor: AppColors.lavender,
                                    child: Icon(_getIcon(iconName), color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_reportData?['title']?.toString() ?? reportTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 3),
                                        Text('Report for $_accountName • ${_reportData?['date'] ?? ""}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              const Text('Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text(
                                _reportData?['summary']?.toString() ?? 'No summary available.',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.55),
                              ),
                              const SizedBox(height: 24),
                              const Text('Key Insights', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              if (_reportData?['insights'] == null || (_reportData?['insights'] as List).isEmpty)
                                const Text('No insights available yet.', style: TextStyle(color: AppColors.muted, fontSize: 12.5))
                              else
                                ...(_reportData?['insights'] as List).map<Widget>((ins) {
                                  return _Insight(text: ins.toString());
                                }),
                              const SizedBox(height: 30),
                              const Text('Download Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _downloadReport('PDF'),
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
                                      onPressed: () => _downloadReport('Excel'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
