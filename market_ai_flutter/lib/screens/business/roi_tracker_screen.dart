import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class RoiTrackerScreen extends ConsumerStatefulWidget {
  const RoiTrackerScreen({super.key});

  @override
  ConsumerState<RoiTrackerScreen> createState() => _RoiTrackerScreenState();
}

class _RoiTrackerScreenState extends ConsumerState<RoiTrackerScreen> {
  String period = 'this_month';
  bool isLoading = true;
  String? adAccountId;

  double totalSpent = 0.0;
  double totalRevenue = 0.0;
  double roi = 0.0;
  double profit = 0.0;
  List<dynamic> chartPoints = [];

  @override
  void initState() {
    super.initState();
    _loadAdAccountAndFetchStats();
  }

  Future<void> _loadAdAccountAndFetchStats() async {
    final prefs = await SharedPreferences.getInstance();
    adAccountId = prefs.getString('ad_account_id');
    if (adAccountId == null || adAccountId!.isEmpty || adAccountId == 'act_') {
      setState(() {
        isLoading = false;
      });
      return;
    }
    _fetchRoiData();
  }

  Future<void> _fetchRoiData() async {
    if (adAccountId == null) return;
    setState(() => isLoading = true);
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;
      
      final res = await AdService.fetchRoiStats(
        token: token,
        adAccountId: adAccountId!,
        period: period,
      );
      
      if (res['success'] == true && mounted) {
        final metrics = res['metrics'] ?? {};
        setState(() {
          totalSpent = double.tryParse(metrics['totalSpent']?.toString() ?? '0') ?? 0.0;
          totalRevenue = double.tryParse(metrics['totalRevenue']?.toString() ?? '0') ?? 0.0;
          roi = double.tryParse(metrics['roi']?.toString() ?? '0') ?? 0.0;
          profit = double.tryParse(metrics['profit']?.toString() ?? '0') ?? 0.0;
          chartPoints = res['chartData'] ?? [];
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          showAppSnackBar(context, res['error'] ?? 'Failed to load ROI stats');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showAppSnackBar(context, 'Error loading ROI stats: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map dropdown options
    final dropdownValue = period;

    final doubleValues = chartPoints
        .map<double>((p) => double.tryParse(p['roi']?.toString() ?? '0') ?? 0.0)
        .toList();
    final dateLabels = chartPoints
        .map<String>((p) => p['date']?.toString() ?? '')
        .toList();

    final finalValues = doubleValues.isEmpty ? [0.0] : doubleValues;
    final finalLabels = dateLabels.isEmpty ? ['No Data'] : dateLabels;

    return Scaffold(
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'ROI Tracker', subtitle: 'Track your return on investment.'),
            ),
            Expanded(
              child: adAccountId == null || adAccountId == 'act_'
                  ? _buildMissingAccountState()
                  : isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : RefreshIndicator(
                          onRefresh: _fetchRoiData,
                          color: AppColors.primary,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 160,
                                  child: DropdownButtonFormField<String>(
                                    value: dropdownValue,
                                    items: const [
                                      DropdownMenuItem(value: 'this_month', child: Text('This Month')),
                                      DropdownMenuItem(value: 'last_month', child: Text('Last Month')),
                                      DropdownMenuItem(value: 'this_quarter', child: Text('This Quarter')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => period = value);
                                        _fetchRoiData();
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.45,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  children: [
                                    MetricCard(label: 'Total Spent', value: '₹${totalSpent.toStringAsFixed(2)}', change: ''),
                                    MetricCard(label: 'Total Revenue', value: '₹${totalRevenue.toStringAsFixed(2)}', change: ''),
                                    MetricCard(label: 'ROI', value: '${roi.toStringAsFixed(2)}x', change: ''),
                                    MetricCard(label: 'Profit', value: '₹${profit.toStringAsFixed(2)}', change: ''),
                                  ],
                                ),
                                const SizedBox(height: 25),
                                const Text('ROI Over Time', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 13),
                                AppCard(
                                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 11),
                                  child: SizedBox(
                                    height: 230,
                                    width: double.infinity,
                                    child: CustomPaint(
                                      painter: _RoiChartPainter(
                                        values: finalValues,
                                        labels: finalLabels,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                AppCard(
                                  color: AppColors.lavender,
                                  borderColor: AppColors.lavenderStrong,
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.primary,
                                        child: Icon(Icons.auto_awesome_rounded),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('AI Insight', style: TextStyle(fontWeight: FontWeight.w800)),
                                            const SizedBox(height: 3),
                                            Text(
                                              roi > 1
                                                  ? 'ROI is positive! Scale the best performing campaigns to generate more revenue.'
                                                  : 'No return detected yet. Monitor campaign metrics and verify pixel integrations.',
                                              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => Navigator.pushNamed(context, AppRoutes.aiSearch),
                                        icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingAccountState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.lavender,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Ad Account Selected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please go to the Campaign Manager screen first and select a valid Ad Account to load ROI reports.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.campaignManagement).then((_) => _loadAdAccountAndFetchStats());
              },
              child: const Text('Go to Campaign Manager'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoiChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _RoiChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chartRect = Rect.fromLTWH(32, 8, size.width - 43, size.height - 38);
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pointPaint = Paint()..color = AppColors.primary;

    for (var i = 0; i <= 4; i++) {
      final y = chartRect.top + chartRect.height * i / 4;
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    
    final range = maxValue - minValue;
    final divisor = range == 0 ? 1.0 : range;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = chartRect.left + chartRect.width * i / (values.length - 1);
      final normalized = (values[i] - minValue) / divisor;
      final y = chartRect.bottom - chartRect.height * normalized;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.3, pointPaint);
    }
    canvas.drawPath(path, linePaint);

    // Limit label prints to keep spacing clean
    final labelStep = (labels.length / 4).ceil();
    for (var i = 0; i < labels.length; i += labelStep) {
      if (i >= labels.length) break;
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(color: AppColors.muted, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = chartRect.left + chartRect.width * i / (labels.length - 1) - painter.width / 2;
      painter.paint(canvas, Offset(x, chartRect.bottom + 11));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
