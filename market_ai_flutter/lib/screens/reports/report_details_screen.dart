import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../../services/report_exporter.dart';
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
  List<dynamic> _facebookPages = [];
  String? _selectedPageId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reportData == null && _errorMsg.isEmpty) {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final reportId = args?['id']?.toString() ?? 'leads';
    final savedAdAccountId = args?['adAccountId']?.toString();
    final isSocial = reportId == 'social';
    final isAdsOrRoi = reportId == 'ads' || reportId == 'roi';
    final isLeads = reportId == 'leads';

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
        pageId: isLeads ? _selectedPageId : null,
      );

      if (res['success'] == true && mounted) {
        final report = res['report'] as Map<String, dynamic>? ?? {};
        if (isLeads && report['facebookPages'] is List) {
          _facebookPages = report['facebookPages'] as List<dynamic>;
        }
        setState(() {
          _reportData = report;
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
    final reportId = args?['id']?.toString() ?? 'leads';
    final reportTitle = args?['title']?.toString() ?? 'Report Detail';

    final token = ref.read(authProvider).token;
    if (token == null) {
      showAppSnackBar(context, 'Session expired. Please log in.');
      return;
    }

    await ReportExporter.exportReport(
      context: context,
      token: token,
      reportType: reportId,
      reportTitle: reportTitle,
      adAccountId: _adAccountId,
      socialAccountId: _socialAccountId,
      period: _socialPeriod,
      pageId: reportId == 'leads' ? _selectedPageId : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final reportId = args?['id']?.toString() ?? 'leads';
    final reportTitle = args?['title']?.toString() ?? 'Report Detail';
    final iconName = args?['iconName']?.toString() ?? 'people_outline_rounded';
    final isSocial = reportId == 'social';
    final isLeads = reportId == 'leads';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(
                title: reportTitle,
                subtitle: _reportData?['period']?.toString() ?? 'Performance Report',
                showBack: true,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMsg.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.danger),
                                const SizedBox(height: 12),
                                Text(_errorMsg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _fetchDetails, child: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(11)),
                                    child: Icon(_getIcon(iconName), color: AppColors.primary, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(reportTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Generated: ${_reportData?['date'] ?? 'Today'}',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isLeads) ...[
                                const SizedBox(height: 20),
                                _LeadReportFilters(
                                  pages: _facebookPages,
                                  selectedPageId: _selectedPageId,
                                  onPageChanged: (value) {
                                    setState(() => _selectedPageId = value);
                                    _fetchDetails();
                                  },
                                ),
                              ],
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

class _LeadReportFilters extends StatelessWidget {
  const _LeadReportFilters({
    required this.pages,
    required this.selectedPageId,
    required this.onPageChanged,
  });

  final List<dynamic> pages;
  final String? selectedPageId;
  final ValueChanged<String?> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter by Facebook Page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(selectedPageId),
          initialValue: selectedPageId ?? 'all',
          isExpanded: true,
          items: [
            const DropdownMenuItem(
              value: 'all',
              child: Text('All Connected Pages (Aggregate)', overflow: TextOverflow.ellipsis),
            ),
            ...pages.map<DropdownMenuItem<String>>((page) => DropdownMenuItem(
              value: page['id']?.toString(),
              child: Text(page['name']?.toString() ?? 'Unnamed Page', overflow: TextOverflow.ellipsis),
            )),
          ],
          onChanged: onPageChanged,
          decoration: const InputDecoration(
            labelText: 'Selected Page',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
        ),
      ],
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
    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4))),
    ]),
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<dynamic> metrics;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: metrics.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.45),
    itemBuilder: (context, index) {
      final m = Map<String, dynamic>.from(metrics[index] as Map);
      Color valueColor = AppColors.text;
      if (m['tone'] == 'positive') valueColor = AppColors.success;
      if (m['tone'] == 'attention') valueColor = const Color(0xFFF59E0B);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(m['label']?.toString() ?? 'Metric', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(m['value']?.toString() ?? '—', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: valueColor)),
          const SizedBox(height: 3),
          Text(m['detail']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ]),
      );
    },
  );
}

class _Insight extends StatelessWidget {
  const _Insight({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_outline, size: 15, color: AppColors.primary)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.text))),
    ]),
  );
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11.5, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.text))),
    ]),
  );
}

class _AdReportFilters extends StatelessWidget {
  const _AdReportFilters({required this.accounts, required this.selectedAccountId, required this.onAccountChanged});
  final List<dynamic> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onAccountChanged;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Filter by Ad Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    if (accounts.isEmpty)
      const Text('No connected Meta ad accounts found.', style: TextStyle(color: AppColors.muted, fontSize: 11.5))
    else
      DropdownButtonFormField<String>(
        key: ValueKey(selectedAccountId),
        initialValue: selectedAccountId,
        isExpanded: true,
        items: accounts.map<DropdownMenuItem<String>>((acc) => DropdownMenuItem(
          value: acc['id']?.toString(),
          child: Text('${acc['name'] ?? 'Ad Account'} (${acc['id'] ?? ''})', overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: onAccountChanged,
        decoration: const InputDecoration(labelText: 'Ad Account', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
      ),
  ]);
}
