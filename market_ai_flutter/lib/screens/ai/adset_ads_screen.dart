import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../routes.dart';
import '../../widgets/common_widgets.dart';

class AdSetAdsScreen extends ConsumerStatefulWidget {
  const AdSetAdsScreen({super.key});

  @override
  ConsumerState<AdSetAdsScreen> createState() => _AdSetAdsScreenState();
}

class _AdSetAdsScreenState extends ConsumerState<AdSetAdsScreen> {
  List<dynamic> ads = [];
  bool isLoading = true;
  String? campaignId;
  String? campaignName;
  String? adsetId;
  String? adsetName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && adsetId == null) {
      campaignId = args['campaignId'];
      campaignName = args['campaignName'];
      adsetId = args['adsetId'];
      adsetName = args['adsetName'];
      _fetchAds();
    }
  }

  Future<void> _fetchAds() async {
    if (adsetId == null) return;

    setState(() => isLoading = true);

    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final res = await AdService.fetchAdsForAdSet(token: token, adsetId: adsetId!);
      if (res['success'] == true && mounted) {
        setState(() {
          ads = res['ads'] ?? [];
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          showAppSnackBar(context, res['error'] ?? 'Failed to load ads');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showAppSnackBar(context, 'Error loading ads: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(adsetName ?? 'Ads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAds,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ads.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    final name = ad['name'] ?? 'Unnamed Ad';
                    final id = ad['id'] ?? '';
                    final status = ad['status'] ?? 'PAUSED';
                    final isActive = status.toUpperCase() == 'ACTIVE';

                    // Parse creative data if available
                    final creative = ad['creative'] ?? {};
                    final creativeId = creative['id'] ?? 'N/A';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.ad_units_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
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
                              'Ad ID: $id',
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                            Text(
                              'Creative ID: $creativeId',
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                            const SizedBox(height: 12),
                            // Quick note about preview
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.lavender,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Review performance metrics for this ad in the Reports tab.',
                                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
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
            AppRoutes.createAd,
            arguments: {
              'adAccountId': args?['adAccountId'],
              'campaignId': campaignId,
              'adsetId': adsetId,
              'adsetName': adsetName,
            },
          ).then((_) => _fetchAds());
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Ad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
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
              child: const Icon(Icons.ad_units_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Ads Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a new Ad creative with text and custom media placements to show to your target audience.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
