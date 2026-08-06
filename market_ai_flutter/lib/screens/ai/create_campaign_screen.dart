import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../routes.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final campaignNameController = TextEditingController();
  final adAccountIdController = TextEditingController(text: 'act_');
  final campaignBudgetController = TextEditingController(text: '500');

  List<dynamic> adAccounts = [];
  bool isLoadingAccounts = true;
  bool enterManually = false;
  String? selectedAdAccountId;

  // Form selections
  String selectedObjective = 'Lead Generation'; // Default
  String specialAdCategory = 'NONE';
  bool advantageBudgetEnabled = false;
  String bidStrategy = 'HIGHEST_VOLUME';

  bool isSubmitting = false;

  final Map<String, Map<String, dynamic>> objectiveMeta = {
    'Brand Awareness': {
      'icon': Icons.campaign_rounded,
      'desc': 'Show your ads to people who are most likely to remember them.',
    },
    'Website Traffic': {
      'icon': Icons.ads_click_rounded,
      'desc': 'Send people to a destination, like a website, app, or Facebook event.',
    },
    'Engagement': {
      'icon': Icons.thumb_up_alt_rounded,
      'desc': 'Get more page likes, post engagement, event responses or messages.',
    },
    'Lead Generation': {
      'icon': Icons.assignment_turned_in_rounded,
      'desc': 'Collect leads for your business via forms, calls, or chat.',
    },
    'App Promotion': {
      'icon': Icons.phone_android_rounded,
      'desc': 'Find new people to install your app and continue using it.',
    },
    'Sales': {
      'icon': Icons.shopping_bag_rounded,
      'desc': 'Find people likely to purchase your goods or services.',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadAdAccountId();
    _fetchAdAccounts();
  }

  @override
  void dispose() {
    campaignNameController.dispose();
    adAccountIdController.dispose();
    campaignBudgetController.dispose();
    super.dispose();
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

  Future<void> _saveAdAccountId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ad_account_id', id);
  }

  Future<void> _submitCampaign() async {
    final name = campaignNameController.text.trim();
    final adAccountId = adAccountIdController.text.trim();

    if (name.isEmpty) {
      showAppSnackBar(context, 'Please enter a Campaign Name');
      return;
    }

    if (adAccountId.isEmpty || adAccountId == 'act_') {
      showAppSnackBar(context, 'Please enter a valid Ad Account ID');
      return;
    }

    final campaignBudget = double.tryParse(campaignBudgetController.text.trim());
    if (advantageBudgetEnabled && (campaignBudget == null || campaignBudget <= 0)) {
      showAppSnackBar(context, 'Please enter a valid campaign budget');
      return;
    }

    setState(() => isSubmitting = true);
    await _saveAdAccountId(adAccountId);

    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final res = await AdService.createCampaignOnly(
        token: token,
        adAccountId: adAccountId,
        campaignName: name,
        objective: selectedObjective,
        specialAdCategory: specialAdCategory,
        useCampaignBudget: advantageBudgetEnabled,
        campaignBudget: advantageBudgetEnabled ? campaignBudgetController.text.trim() : null,
      );

      if (res['success'] == true && mounted) {
        final campaignId = res['campaignId'];
        showAppSnackBar(context, 'Campaign created successfully!');
        
        // Go to Step 2 (Ad Set creation), pass selectedObjective & budget parameters
        Navigator.pushNamed(
          context,
          AppRoutes.createAdSet,
          arguments: {
            'campaignId': campaignId,
            'adAccountId': adAccountId,
            'campaignName': name,
            'objective': selectedObjective,
            'advantageBudgetEnabled': advantageBudgetEnabled,
            'bidStrategy': bidStrategy,
          },
        );
      } else {
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Failed to create campaign');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error creating campaign: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: ScreenHeader(
                      title: 'Create Campaign',
                      subtitle: 'Step 1: Set objective and campaign details',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ad Account Selector
                    if (isLoadingAccounts)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    else ...[
                      const FormLabel('Ad Account'),
                      if (!enterManually && adAccounts.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: selectedAdAccountId,
                          items: adAccounts
                              .map((acc) => DropdownMenuItem<String>(
                                    value: acc['id'],
                                    child: Text(acc['name'] ?? acc['id']),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedAdAccountId = value;
                              adAccountIdController.text = value ?? '';
                            });
                          },
                        )
                      else
                        TextField(
                          controller: adAccountIdController,
                          decoration: const InputDecoration(hintText: 'Enter Facebook Ad Account ID (e.g. act_1234567)'),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
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
                    const SizedBox(height: 8),

                    // Campaign Name
                    const FormLabel('Campaign Name'),
                    TextField(
                      controller: campaignNameController,
                      decoration: const InputDecoration(hintText: 'Enter Campaign Name'),
                    ),
                    const SizedBox(height: 18),

                    // Marketing Objectives Choice Grid
                    const FormLabel('Select Marketing Objective'),
                    const SizedBox(height: 6),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: objectiveMeta.keys.length,
                      itemBuilder: (context, index) {
                        final key = objectiveMeta.keys.elementAt(index);
                        final item = objectiveMeta[key]!;
                        final isSelected = selectedObjective == key;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedObjective = key;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.lavender : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  color: isSelected ? AppColors.primary : AppColors.muted,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.primary : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    item['desc'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // Special Ad Categories Dropdown
                    const FormLabel('Special Ad Category'),
                    DropdownButtonFormField<String>(
                      value: specialAdCategory,
                      items: const [
                        DropdownMenuItem(value: 'NONE', child: Text('No Special Category')),
                        DropdownMenuItem(value: 'CREDIT', child: Text('Credit Ads')),
                        DropdownMenuItem(value: 'EMPLOYMENT', child: Text('Employment / Job Ads')),
                        DropdownMenuItem(value: 'HOUSING', child: Text('Housing / Real Estate Ads')),
                        DropdownMenuItem(value: 'ISSUES_ELECTIONS_POLITICS', child: Text('Social Issues, Elections or Politics')),
                      ],
                      onChanged: (val) => setState(() => specialAdCategory = val ?? 'NONE'),
                    ),
                    const SizedBox(height: 18),

                    // Advantage Campaign Budget (CBO) Section
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Advantage Campaign Budget',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Distribute budget across ad sets for optimal delivery',
                                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: advantageBudgetEnabled,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => advantageBudgetEnabled = val);
                                },
                              ),
                            ],
                          ),
                          if (advantageBudgetEnabled) ...[
                            const Divider(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: FormLabel('Campaign Daily Budget (₹)'),
                            ),
                            TextField(
                              controller: campaignBudgetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Enter budget amount'),
                            ),
                            const SizedBox(height: 10),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: FormLabel('Ad Set Bid Strategy'),
                            ),
                            DropdownButtonFormField<String>(
                              value: bidStrategy,
                              items: const [
                                DropdownMenuItem(value: 'HIGHEST_VOLUME', child: Text('Highest Volume (Default)')),
                                DropdownMenuItem(value: 'COST_CAP', child: Text('Cost Cap')),
                                DropdownMenuItem(value: 'BID_CAP', child: Text('Bid Cap')),
                              ],
                              onChanged: (val) => setState(() => bidStrategy = val ?? 'HIGHEST_VOLUME'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSubmitting ? null : _submitCampaign,
                        child: isSubmitting
                            ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            : const Text('Create Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
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
