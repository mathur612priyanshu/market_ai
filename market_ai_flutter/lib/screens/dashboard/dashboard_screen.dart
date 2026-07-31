import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?['name']?.toString() ?? 'User';
    return Scaffold(
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, $userName 👋', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          const Text("Here's your business overview", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.16),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Transform.translate(
                    offset: const Offset(0, -13),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.72,
                      children: const [
                        MetricCard(label: 'Total Leads', value: '248', change: '+12.5%'),
                        MetricCard(label: 'Ad Spend', value: '₹12,500', change: '-5.2%', positive: false),
                        MetricCard(label: 'ROI', value: '3.8x', change: '+18.8%'),
                        MetricCard(label: 'Reach', value: '45.2K', change: '+8.7%'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    borderColor: AppColors.primary.withOpacity(0.4),
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.campaignManagement),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.lavender,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Campaign Manager',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.text),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Monitor performance, pause, duplicate, or edit your active ad campaigns.',
                                  style: TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: .98,
                    children: [
                      _QuickAction(
                        icon: Icons.analytics_outlined,
                        label: 'Competitor\nAnalysis',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.competitorAnalysis),
                      ),
                      _QuickAction(
                        icon: Icons.campaign_outlined,
                        label: 'Ad Run',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.adSetup),
                      ),
                      _QuickAction(
                        icon: Icons.people_outline_rounded,
                        label: 'Leads',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.leads),
                      ),
                      _QuickAction(
                        icon: Icons.show_chart_rounded,
                        label: 'ROI\nTracker',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.roiTracker),
                      ),
                      _QuickAction(
                        icon: Icons.post_add_outlined,
                        label: 'Social Media\nPost',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.aiPostCreator),
                      ),
                      _QuickAction(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI Search',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.aiSearch),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(child: Text('Recent Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.reports),
                        child: const Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _RecentReport(
                    icon: Icons.analytics_outlined,
                    title: 'Competitor Analysis',
                    date: 'May 24, 2024',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.reportDetails),
                  ),
                  const SizedBox(height: 8),
                  _RecentReport(
                    icon: Icons.campaign_outlined,
                    title: 'Ad Performance Report',
                    date: 'May 23, 2024',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.reportDetails),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(11),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, height: 1.2, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RecentReport extends StatelessWidget {
  const _RecentReport({required this.icon, required this.title, required this.date, required this.onTap});
  final IconData icon;
  final String title;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(date, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showAppSnackBar(context, '$title downloaded'),
            icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
