import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic> _stats = {
    'totalLeads': '248',
    'leadsChange': '+12.5%',
    'adSpend': '₹12,500',
    'spendChange': '-5.2%',
    'spendPositive': false,
    'roi': '3.8x',
    'roiChange': '+18.8%',
    'reach': '45.2K',
    'reachChange': '+8.7%'
  };

  String _accountName = 'Loading...';
  List<dynamic> adAccounts = [];
  String? _selectedAdAccountId;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final accountsRes = await AdService.fetchUserAdAccounts(token: token);
      List<dynamic> list = [];
      if (accountsRes['success'] == true) {
        list = accountsRes['accounts'] as List<dynamic>? ?? [];
      }

      final prefs = await SharedPreferences.getInstance();
      var savedId = prefs.getString('ad_account_id');
      
      if ((savedId == null || savedId.isEmpty || savedId == 'act_') && list.isNotEmpty) {
        savedId = list.first['id']?.toString() ?? '';
        if (savedId.isNotEmpty) {
          await prefs.setString('ad_account_id', savedId);
        }
      }

      setState(() {
        adAccounts = list;
        _selectedAdAccountId = savedId;
      });

      final activeId = _selectedAdAccountId ?? 'act_123456789';
      _fetchDashboardStats(activeId);
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
    }
  }

  Future<void> _fetchDashboardStats(String adAccountId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    try {
      final res = await AdService.fetchDashboardStats(token: token, adAccountId: adAccountId);
      if (res['success'] == true && res['metrics'] != null && mounted) {
        setState(() {
          _stats = Map<String, dynamic>.from(res['metrics']);
          _accountName = res['accountName']?.toString() ?? 'Demo Ad Account';
        });
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          if (adAccounts.isEmpty)
                            Text("Here's your business overview • $_accountName", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500))
                          else ...[
                            const Text("Here's your business overview", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                            Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: AppColors.primary,
                              ),
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedAdAccountId,
                                    isExpanded: true,
                                    dropdownColor: AppColors.primary,
                                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                                    items: adAccounts.map<DropdownMenuItem<String>>((acc) {
                                      return DropdownMenuItem<String>(
                                        value: acc['id']?.toString(),
                                        child: Text(
                                          acc['name']?.toString() ?? 'Unnamed Account',
                                          style: const TextStyle(color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) async {
                                      if (value != null) {
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setString('ad_account_id', value);
                                        setState(() {
                                          _selectedAdAccountId = value;
                                        });
                                        _fetchDashboardStats(value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                      children: [
                        MetricCard(
                          label: 'Total Leads',
                          value: _stats['totalLeads']?.toString() ?? '0',
                          change: '',
                        ),
                        MetricCard(
                          label: 'Ad Spend',
                          value: _stats['adSpend']?.toString() ?? '₹0',
                          change: '',
                        ),
                        MetricCard(
                          label: 'ROI',
                          value: _stats['roi']?.toString() ?? '0.0x',
                          change: '',
                        ),
                        MetricCard(
                          label: 'Reach',
                          value: _stats['reach']?.toString() ?? '0',
                          change: '',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        label: 'Campaign\nManager',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.campaignManagement).then((_) => _loadStats()),
                      ),
                      _QuickAction(
                        icon: Icons.people_outline_rounded,
                        label: 'Leads',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.leads),
                      ),
                      _QuickAction(
                        icon: Icons.show_chart_rounded,
                        label: 'ROI\nTracker',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.roiTracker).then((_) => _loadStats()),
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
