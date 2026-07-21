import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class RoiTrackerScreen extends StatefulWidget {
  const RoiTrackerScreen({super.key});

  @override
  State<RoiTrackerScreen> createState() => _RoiTrackerScreenState();
}

class _RoiTrackerScreenState extends State<RoiTrackerScreen> {
  String period = 'This Month';

  @override
  Widget build(BuildContext context) {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        value: period,
                        items: ['This Month', 'Last Month', 'This Quarter']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) => setState(() => period = value ?? period),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
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
                      children: const [
                        MetricCard(label: 'Total Spent', value: '₹12,500', change: ''),
                        MetricCard(label: 'Total Revenue', value: '₹47,500', change: ''),
                        MetricCard(label: 'ROI', value: '3.8x', change: '+18.8%'),
                        MetricCard(label: 'Profit', value: '₹35,000', change: '+22.1%'),
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
                        child: CustomPaint(painter: _RoiChartPainter()),
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text('AI Insight', style: TextStyle(fontWeight: FontWeight.w800)),
                                  SizedBox(height: 3),
                                  Text('ROI improved as lead-focused campaigns scaled.', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
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
          ],
        ),
      ),
    );
  }
}

class _RoiChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const values = [1.2, 1.8, 1.55, 2.25, 2.7, 2.15, 3.05, 2.55, 2.3, 3.15, 3.5, 3.8];
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
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = chartRect.left + chartRect.width * i / (values.length - 1);
      final normalized = (values[i] - minValue) / (maxValue - minValue);
      final y = chartRect.bottom - chartRect.height * normalized;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.3, pointPaint);
    }
    canvas.drawPath(path, linePaint);

    final labels = ['May 1', 'May 10', 'May 20', 'May 30'];
    for (var i = 0; i < labels.length; i++) {
      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(color: AppColors.muted, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = chartRect.left + chartRect.width * i / (labels.length - 1) - painter.width / 2;
      painter.paint(canvas, Offset(x, chartRect.bottom + 11));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
