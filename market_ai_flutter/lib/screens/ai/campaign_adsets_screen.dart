import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../routes.dart';
import '../../widgets/common_widgets.dart';

class CampaignAdSetsScreen extends ConsumerStatefulWidget {
  const CampaignAdSetsScreen({super.key});

  @override
  ConsumerState<CampaignAdSetsScreen> createState() => _CampaignAdSetsScreenState();
}

class _CampaignAdSetsScreenState extends ConsumerState<CampaignAdSetsScreen> {
  List<dynamic> adsets = [];
  bool isLoading = true;
  String? campaignId;
  String? campaignName;
  String? objective;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && campaignId == null) {
      campaignId = args['campaignId'];
      campaignName = args['campaignName'];
      objective = args['objective'];
      _fetchAdSets();
    }
  }

  Future<void> _fetchAdSets() async {
    if (campaignId == null) return;

    setState(() => isLoading = true);

    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final res = await AdService.fetchAdSetsForCampaign(token: token, campaignId: campaignId!);
      if (res['success'] == true && mounted) {
        setState(() {
          adsets = res['adsets'] ?? [];
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          showAppSnackBar(context, res['error'] ?? 'Failed to load ad sets');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showAppSnackBar(context, 'Error loading ad sets: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(campaignName ?? 'Ad Sets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAdSets,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : adsets.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: adsets.length,
                  itemBuilder: (context, index) {
                    final adset = adsets[index];
                    final name = adset['name'] ?? 'Unnamed Ad Set';
                    final id = adset['id'] ?? '';
                    final status = adset['status'] ?? 'PAUSED';
                    final isActive = status.toUpperCase() == 'ACTIVE';

                    // Parse budget
                    String budgetStr = 'N/A';
                    if (adset['daily_budget'] != null) {
                      final parsed = double.tryParse(adset['daily_budget'].toString()) ?? 0.0;
                      budgetStr = '₹${(parsed / 100).toStringAsFixed(0)} / daily';
                    } else if (adset['lifetime_budget'] != null) {
                      final parsed = double.tryParse(adset['lifetime_budget'].toString()) ?? 0.0;
                      budgetStr = '₹${(parsed / 100).toStringAsFixed(0)} / lifetime';
                    }

                    final optimizationGoal = adset['optimization_goal'] ?? 'N/A';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.adsetAds,
                            arguments: {
                              'adAccountId': args?['adAccountId'],
                              'campaignId': campaignId,
                              'campaignName': campaignName,
                              'adsetId': id,
                              'adsetName': name,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.success.withAlpha(20)
                                          : AppColors.muted.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? AppColors.success : AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID: $id',
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildInfoCol('Budget', budgetStr),
                                  _buildInfoCol('Optimization', optimizationGoal),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.add_box_rounded, size: 16, color: AppColors.primary),
                                    label: const Text(
                                      'Add Ad',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.createAd,
                                        arguments: {
                                          'adAccountId': args?['adAccountId'],
                                          'campaignId': campaignId,
                                          'adsetId': id,
                                          'adsetName': name,
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.muted),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.createAdSet,
            arguments: {
              'adAccountId': args?['adAccountId'],
              'campaignId': campaignId,
              'campaignName': campaignName,
              'objective': objective ?? 'Lead Generation',
              'advantageBudgetEnabled': args?['advantageBudgetEnabled'] ?? false,
              'bidStrategy': args?['bidStrategy'] ?? 'HIGHEST_VOLUME',
            },
          ).then((_) => _fetchAdSets());
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Ad Set', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
              child: const Icon(Icons.folder_open_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Ad Sets Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a new Ad Set in this campaign to target specific audiences, budgets, and schedules.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
