import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../routes.dart';

class CampaignManagementScreen extends ConsumerStatefulWidget {
  const CampaignManagementScreen({super.key});

  @override
  ConsumerState<CampaignManagementScreen> createState() => _CampaignManagementScreenState();
}

class _CampaignManagementScreenState extends ConsumerState<CampaignManagementScreen> {
  final adAccountIdController = TextEditingController(text: 'act_123456789');
  bool isLoading = false;
  List<dynamic> campaigns = [];

  String _objectiveLabel(String objective) {
    const labels = {
      'OUTCOME_AWARENESS': 'Brand Awareness',
      'OUTCOME_TRAFFIC': 'Website Traffic',
      'OUTCOME_ENGAGEMENT': 'Engagement',
      'OUTCOME_LEADS': 'Lead Generation',
      'OUTCOME_APP_PROMOTION': 'App Promotion',
      'OUTCOME_SALES': 'Sales',
      // Older campaigns may still return Meta's legacy objective values.
      'BRAND_AWARENESS': 'Brand Awareness',
      'LINK_CLICKS': 'Website Traffic',
      'LEAD_GENERATION': 'Lead Generation',
      'APP_INSTALLS': 'App Promotion',
      'CONVERSIONS': 'Sales',
    };

    return labels[objective.toUpperCase()] ?? objective;
  }
  bool hasSearched = false;

  List<dynamic> adAccounts = [];
  bool isLoadingAccounts = true;
  bool enterManually = false;
  String? selectedAdAccountId;

  @override
  void initState() {
    super.initState();
    _loadAdAccountId();
    _fetchAdAccounts();
  }

  Future<void> _fetchAdAccounts() async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      setState(() => isLoadingAccounts = false);
      return;
    }

    try {
      final res = await AdService.fetchUserAdAccounts(token: token);
      if (res['success'] == true && mounted) {
        final accounts = res['accounts'] ?? [];
        setState(() {
          adAccounts = accounts;
          isLoadingAccounts = false;
          
          if (adAccounts.isNotEmpty) {
            final savedId = adAccountIdController.text.trim();
            final match = adAccounts.any((acc) => acc['id'] == savedId);
            selectedAdAccountId = match ? savedId : adAccounts.first['id'];
            adAccountIdController.text = selectedAdAccountId!;
            _fetchCampaigns();
          } else {
            enterManually = true;
          }
        });
      } else {
        if (mounted) {
          setState(() {
            isLoadingAccounts = false;
            enterManually = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingAccounts = false;
          enterManually = true;
        });
      }
    }
  }

  Future<void> _loadAdAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('ad_account_id');
    if (savedId != null && savedId.isNotEmpty) {
      setState(() {
        adAccountIdController.text = savedId;
      });
    }
  }

  @override
  void dispose() {
    adAccountIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchCampaigns() async {
    final adAccountId = adAccountIdController.text.trim();
    if (adAccountId.isEmpty || adAccountId == 'act_') {
      showAppSnackBar(context, 'Please enter a valid Ad Account ID (e.g. act_123456789)');
      return;
    }

    final token = ref.read(authProvider).token;
    if (token == null) {
      showAppSnackBar(context, 'Session expired. Please login again.');
      return;
    }

    setState(() {
      isLoading = true;
      hasSearched = true;
      campaigns = [];
    });

    try {
      final res = await AdService.fetchAdCampaigns(token: token, adAccountId: adAccountId);
      if (res['success'] == true && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ad_account_id', adAccountId);
        setState(() {
          campaigns = res['campaigns'] ?? [];
        });
      } else {
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Failed to fetch campaigns.');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error communicating with server: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _toggleStatus(String campaignId, String currentStatus) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    final nextStatus = currentStatus.toUpperCase() == 'ACTIVE' ? 'PAUSED' : 'ACTIVE';
    
    // Optimistic UI update
    setState(() {
      final index = campaigns.indexWhere((c) => c['id'] == campaignId);
      if (index != -1) {
        campaigns[index]['status'] = nextStatus;
      }
    });

    try {
      final res = await AdService.toggleCampaignStatus(
        token: token,
        campaignId: campaignId,
        status: nextStatus,
      );

      if (res['success'] != true) {
        // Rollback on failure
        setState(() {
          final index = campaigns.indexWhere((c) => c['id'] == campaignId);
          if (index != -1) {
            campaigns[index]['status'] = currentStatus;
          }
        });
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Failed to update campaign status.');
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, 'Campaign status updated to $nextStatus');
        }
      }
    } catch (e) {
      // Rollback on failure
      setState(() {
        final index = campaigns.indexWhere((c) => c['id'] == campaignId);
        if (index != -1) {
          campaigns[index]['status'] = currentStatus;
        }
      });
      if (mounted) {
        showAppSnackBar(context, 'Error updating status: $e');
      }
    }
  }

  Future<void> _duplicateCampaign(String campaignId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    showAppSnackBar(context, 'Duplicating campaign...');

    try {
      final res = await AdService.duplicateCampaign(token: token, campaignId: campaignId);
      if (res['success'] == true) {
        showAppSnackBar(context, 'Campaign duplicated successfully!');
        _fetchCampaigns(); // reload list
      } else {
        showAppSnackBar(context, res['error'] ?? 'Duplication failed.');
      }
    } catch (e) {
      showAppSnackBar(context, 'Error duplicating campaign: $e');
    }
  }

  Future<void> _editCampaignName(String campaignId, String currentName) async {
    final editController = TextEditingController(text: currentName);
    
    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Campaign Name'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            hintText: 'Enter new campaign name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (editController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true) {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final newName = editController.text.trim();
      
      // Optimistic update
      setState(() {
        final index = campaigns.indexWhere((c) => c['id'] == campaignId);
        if (index != -1) {
          campaigns[index]['name'] = newName;
        }
      });

      try {
        final res = await AdService.editCampaign(
          token: token,
          campaignId: campaignId,
          name: newName,
        );

        if (res['success'] != true) {
          setState(() {
            final index = campaigns.indexWhere((c) => c['id'] == campaignId);
            if (index != -1) {
              campaigns[index]['name'] = currentName;
            }
          });
          if (mounted) {
            showAppSnackBar(context, res['error'] ?? 'Failed to edit campaign name.');
          }
        } else {
          if (mounted) {
            showAppSnackBar(context, 'Campaign name updated successfully.');
          }
        }
      } catch (e) {
        setState(() {
          final index = campaigns.indexWhere((c) => c['id'] == campaignId);
          if (index != -1) {
            campaigns[index]['name'] = currentName;
          }
        });
        if (mounted) {
          showAppSnackBar(context, 'Error editing name: $e');
        }
      }
    }
  }

  Future<void> _viewCampaignInsights(String campaignId, String campaignName) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Fetching insights...'),
          ],
        ),
      ),
    );

    try {
      final res = await AdService.getCampaignInsights(token: token, campaignId: campaignId);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
      }

      if (res['success'] == true && mounted) {
        final data = res['insights'] as Map<String, dynamic>;
        final isMock = res['isMock'] == true;

        final spend = double.tryParse(data['spend']?.toString() ?? '0') ?? 0.0;
        final clicks = int.tryParse(data['clicks']?.toString() ?? '0') ?? 0;
        final impressions = int.tryParse(data['impressions']?.toString() ?? '0') ?? 0;
        final reach = int.tryParse(data['reach']?.toString() ?? '0') ?? 0;

        final ctr = impressions > 0 ? (clicks / impressions * 100) : 0.0;
        final cpc = clicks > 0 ? (spend / clicks) : 0.0;

        showDialog<void>(
          context: context,
          builder: (insightsContext) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.analytics_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    campaignName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMock)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.lavender.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sandbox Mode: Showing simulated performance analytics.',
                              style: TextStyle(fontSize: 10, color: AppColors.primary.withOpacity(0.9), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildInsightItem('Total Spend', '₹${spend.toStringAsFixed(2)}', Icons.monetization_on_outlined),
                  _buildInsightItem('Impressions', impressions.toString(), Icons.visibility_outlined),
                  _buildInsightItem('Clicks', clicks.toString(), Icons.ads_click_rounded),
                  _buildInsightItem('Reach', reach.toString(), Icons.people_outline_rounded),
                  _buildInsightItem('Click-Through Rate (CTR)', '${ctr.toStringAsFixed(2)}%', Icons.show_chart_rounded),
                  _buildInsightItem('Cost Per Click (CPC)', '₹${cpc.toStringAsFixed(2)}', Icons.price_change_outlined),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(insightsContext),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Failed to load insights.');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        showAppSnackBar(context, 'Error loading insights: $e');
      }
    }
  }

  Widget _buildInsightItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.text)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Campaign Manager', subtitle: 'Monitor and control your ad campaigns.'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: isLoadingAccounts
                            ? const SizedBox(
                                height: 48,
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              )
                            : enterManually
                                ? TextField(
                                    controller: adAccountIdController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ad Account ID',
                                      hintText: 'act_123456789',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    value: selectedAdAccountId,
                                    decoration: const InputDecoration(
                                      labelText: 'Select Ad Account',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: adAccounts.map<DropdownMenuItem<String>>((acc) {
                                      return DropdownMenuItem<String>(
                                        value: acc['id'],
                                        child: Text(
                                          acc['name'] ?? acc['id'],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12.5),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          selectedAdAccountId = val;
                                          adAccountIdController.text = val;
                                        });
                                        _fetchCampaigns();
                                      }
                                    },
                                  ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isLoading ? null : _fetchCampaigns,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sync'),
                      ),
                    ],
                  ),
                  if (!isLoadingAccounts && adAccounts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            enterManually = !enterManually;
                          });
                        },
                        child: Text(
                          enterManually ? 'Choose from linked accounts' : 'Enter account ID manually',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _buildCampaignsBody(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.adSetup);
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create Campaign',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildCampaignsBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_rounded, color: AppColors.border, size: 70),
            const SizedBox(height: 16),
            const Text(
              'Enter Ad Account ID to list campaigns',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (campaigns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.campaign_outlined, color: AppColors.muted, size: 50),
              const SizedBox(height: 16),
              const Text(
                'No campaigns found',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              const Text(
                'If this is a sandbox account, you can create a test campaign first or verify permission settings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        final c = campaigns[index];
        final id = c['id']?.toString() ?? '';
        final name = c['name']?.toString() ?? 'Unnamed Campaign';
        final status = c['status']?.toString() ?? 'PAUSED';
        final objective = _objectiveLabel(c['objective']?.toString() ?? '');
        final dailyBudget = c['daily_budget'] != null
            ? '₹${(double.tryParse(c['daily_budget'].toString()) ?? 0.0) / 100.0}'
            : null;
        final lifetimeBudget = c['lifetime_budget'] != null
            ? '₹${(double.tryParse(c['lifetime_budget'].toString()) ?? 0.0) / 100.0}'
            : null;

        final isActive = status.toUpperCase() == 'ACTIVE';

        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success.withOpacity(0.12) : AppColors.muted.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isActive ? AppColors.success : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Objective', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      Text(objective, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Budget', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      Text(
                        dailyBudget != null ? '$dailyBudget/day' : (lifetimeBudget ?? 'N/A'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    tooltip: isActive ? 'Pause' : 'Resume',
                    onPressed: () => _toggleStatus(id, status),
                    icon: Icon(
                      isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                      color: isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Duplicate',
                    onPressed: () => _duplicateCampaign(id),
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                  ),
                  IconButton(
                    tooltip: 'Edit Name',
                    onPressed: () => _editCampaignName(id, name),
                    icon: const Icon(Icons.edit_outlined, color: AppColors.muted),
                  ),
                  IconButton(
                    tooltip: 'View Insights',
                    onPressed: () => _viewCampaignInsights(id, name),
                    icon: const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
                  ),
                  IconButton(
                    tooltip: 'Create Ad Set',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.createAdSet,
                        arguments: {
                          'campaignId': id,
                          'adAccountId': selectedAdAccountId,
                          'campaignName': name,
                          'objective': _objectiveLabel(c['objective']?.toString() ?? ''),
                          'advantageBudgetEnabled': dailyBudget != null,
                        },
                      );
                    },
                    icon: const Icon(Icons.add_box_outlined, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
