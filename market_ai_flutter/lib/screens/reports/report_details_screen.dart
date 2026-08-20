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
  String? _adAccountId;
  List<dynamic> _socialAccounts = [];
  String? _socialAccountId;
  String _socialPeriod = '30';
  List<dynamic> _adAccounts = [];

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
    final isSocial = reportId == 'social';
    final isAdsOrRoi = reportId == 'ads' || reportId == 'roi';

    setState(() {
      _isLoading = true;
      _errorMsg = '';
      if (_adAccountId == null) {
        _adAccountId = savedAdAccountId;
      }
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

      if (isSocial && _socialAccounts.isEmpty) {
        final accountsRes = await ReportService.fetchSocialAccounts(token: token);
        if (accountsRes['success'] == true) {
          _socialAccounts = accountsRes['accounts'] as List<dynamic>? ?? [];
          _socialAccountId ??= _socialAccounts.isNotEmpty ? _socialAccounts.first['id']?.toString() : null;
        }
      }

      if (isAdsOrRoi && _adAccounts.isEmpty) {
        final adAccountsRes = await ReportService.fetchAdAccounts(token: token);
        if (adAccountsRes['success'] == true) {
          _adAccounts = adAccountsRes['accounts'] as List<dynamic>? ?? [];
          if (_adAccountId == null || _adAccountId == 'act_123456789' || _adAccountId == 'null') {
            _adAccountId = _adAccounts.isNotEmpty ? _adAccounts.first['id']?.toString() : null;
          }
        }
      }

      final res = await ReportService.fetchReportDetails(
        token: token,
        type: reportId,
        adAccountId: _adAccountId,
        socialAccountId: isSocial ? _socialAccountId : null,
        period: isSocial ? _socialPeriod : null,
      );
      if (res['success'] == true && mounted) {
        setState(() {
          _reportData = res['report'];
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

  Future<void> _downloadReport() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final reportId = args?['id']?.toString() ?? 'competitor';

    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final query = <String, String>{'token': token, 'adAccountId': _adAccountId ?? ''};
      if (reportId == 'social') {
        if (_socialAccountId != null) query['socialAccountId'] = _socialAccountId!;
        query['period'] = _socialPeriod;
      }
      final url = Uri.parse('$baseUrl/api/reports/$reportId/download').replace(queryParameters: query).toString();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          showAppSnackBar(context, 'CSV report download started.');
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
    final reportId = args?['id']?.toString() ?? 'competitor';
    final reportTitle = args?['title']?.toString() ?? 'Report Detail';
    final iconName = args?['iconName']?.toString() ?? 'analytics_outlined';
    final isSocial = reportId == 'social';

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
                                        Text('${_reportData?['period'] ?? 'Current snapshot'} • ${_reportData?['date'] ?? ""}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isSocial) ...[
                                const SizedBox(height: 20),
                                _SocialReportFilters(
                                  accounts: _socialAccounts,
                                  selectedAccountId: _socialAccountId,
                                  period: _socialPeriod,
                                  onAccountChanged: (value) {
                                    if (value != null) {
                                      setState(() => _socialAccountId = value);
                                      _fetchDetails();
                                    }
                                  },
                                  onPeriodChanged: (value) {
                                    if (value != null) {
                                      setState(() => _socialPeriod = value);
                                      _fetchDetails();
                                    }
                                  },
                                ),
                              ],
                              if (reportId == 'ads' || reportId == 'roi') ...[
                                const SizedBox(height: 20),
                                _AdReportFilters(
                                  accounts: _adAccounts,
                                  selectedAccountId: _adAccountId,
                                  onAccountChanged: (value) {
                                    if (value != null) {
                                      setState(() => _adAccountId = value);
                                      _fetchDetails();
                                    }
                                  },
                                ),
                              ],
                              const SizedBox(height: 25),
                              const Text('Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text(
                                _reportData?['summary']?.toString() ?? 'No summary available.',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.55),
                              ),
                              const SizedBox(height: 14),
                              if ((_reportData?['dataStatus']?.toString() ?? '').isNotEmpty)
                                _DataStatus(message: _reportData!['dataStatus'].toString()),
                              const SizedBox(height: 24),
                              if (_reportData?['metrics'] is List && (_reportData?['metrics'] as List).isNotEmpty) ...[
                                const Text('Performance Snapshot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 12),
                                _MetricGrid(metrics: _reportData!['metrics'] as List),
                                const SizedBox(height: 24),
                              ],
                              if (isSocial && _reportData?['topPosts'] is List && (_reportData?['topPosts'] as List).isNotEmpty) ...[
                                const Text('Top Performing Content', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 12),
                                ...(_reportData!['topPosts'] as List).map<Widget>((post) => _TopPostCard(post: Map<String, dynamic>.from(post as Map))),
                                const SizedBox(height: 14),
                              ],
                              const Text('Key Insights', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              if (_reportData?['insights'] == null || (_reportData?['insights'] as List).isEmpty)
                                const Text('No insights available yet.', style: TextStyle(color: AppColors.muted, fontSize: 12.5))
                              else
                                ...(_reportData?['insights'] as List).map<Widget>((ins) {
                                  return _Insight(text: ins.toString());
                                }),
                              if (_reportData?['actions'] is List && (_reportData?['actions'] as List).isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text('Recommended Next Steps', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 12),
                                ...(_reportData?['actions'] as List).map<Widget>((action) => _ActionItem(text: action.toString())),
                              ],
                              const SizedBox(height: 30),
                              const Text('Export Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _downloadReport,
                                  icon: const Icon(Icons.table_chart_outlined),
                                  label: const Text('Download CSV (Excel-compatible)'),
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
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialReportFilters extends StatelessWidget {
  const _SocialReportFilters({required this.accounts, required this.selectedAccountId, required this.period, required this.onAccountChanged, required this.onPeriodChanged});
  final List<dynamic> accounts;
  final String? selectedAccountId;
  final String period;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String?> onPeriodChanged;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Reporting filters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    if (accounts.isEmpty)
      const Text('No connected Page or Instagram professional account.', style: TextStyle(color: AppColors.muted, fontSize: 11.5))
    else
      DropdownButtonFormField<String>(
        key: ValueKey(selectedAccountId),
        initialValue: selectedAccountId,
        isExpanded: true,
        items: accounts.map<DropdownMenuItem<String>>((account) => DropdownMenuItem(
          value: account['id']?.toString(),
          child: Text('${account['platform'] == 'instagram' ? 'Instagram' : 'Facebook'} • ${account['name'] ?? 'Unnamed account'}', overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onAccountChanged,
        decoration: const InputDecoration(labelText: 'Social account', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
      ),
    const SizedBox(height: 10),
    SegmentedButton<String>(
      segments: const [ButtonSegment(value: '7', label: Text('Last 7 days')), ButtonSegment(value: '30', label: Text('Last 30 days'))],
      selected: {period},
      onSelectionChanged: (selected) => onPeriodChanged(selected.first),
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    ),
  ]);
}

class _TopPostCard extends StatelessWidget {
  const _TopPostCard({required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(post['text']?.toString() ?? 'Social post', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('${post['engagement'] ?? 0} visible interactions  •  ${post['reactions'] ?? 0} likes/reactions  •  ${post['comments'] ?? 0} comments', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
    ]),
  );
}

class _DataStatus extends StatelessWidget {
  const _DataStatus({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(color: AppColors.muted, fontSize: 11.5, height: 1.35))),
    ]),
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List metrics;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: metrics.map<Widget>((raw) {
      final item = raw as Map;
      final tone = item['tone']?.toString();
      final color = tone == 'positive' ? AppColors.success : tone == 'attention' ? const Color(0xFFD98200) : AppColors.primary;
      return SizedBox(width: (MediaQuery.sizeOf(context).width - 46) / 2, child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['label']?.toString() ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(item['value']?.toString() ?? '—', style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(item['detail']?.toString() ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 9.5), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ));
    }).toList(),
  );
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD98200), size: 18),
      const SizedBox(width: 9), Expanded(child: Text(text, style: const TextStyle(fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w600))),
    ]),
  );
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

class _AdReportFilters extends StatelessWidget {
  const _AdReportFilters({required this.accounts, required this.selectedAccountId, required this.onAccountChanged});
  final List<dynamic> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onAccountChanged;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Reporting filters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    if (accounts.isEmpty)
      const Text('No connected Facebook Ad Accounts found.', style: TextStyle(color: AppColors.muted, fontSize: 11.5))
    else
      DropdownButtonFormField<String>(
        key: ValueKey(selectedAccountId),
        initialValue: selectedAccountId,
        isExpanded: true,
        items: accounts.map<DropdownMenuItem<String>>((account) => DropdownMenuItem(
          value: account['id']?.toString(),
          child: Text('Ad Account • ${account['name'] ?? 'Unnamed account'}', overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onAccountChanged,
        decoration: const InputDecoration(labelText: 'Meta Ad Account', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
      ),
  ]);
}
