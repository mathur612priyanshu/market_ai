import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdSetupScreen extends ConsumerStatefulWidget {
  const AdSetupScreen({super.key});

  @override
  ConsumerState<AdSetupScreen> createState() => _AdSetupScreenState();
}

class _AdSetupScreenState extends ConsumerState<AdSetupScreen> {
  final campaignNameController = TextEditingController();

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
  final adAccountIdController = TextEditingController(text: 'act_');
  final budgetController = TextEditingController(text: '500');
  DateTime startDate = DateTime.now();
  DateTime? endDate = DateTime.now().add(const Duration(days: 7));
  bool runContinuously = false;

  String selectedCountry = 'IN';
  int ageMin = 18;
  int ageMax = 65;
  String selectedGender = 'ALL';

  List<Map<String, dynamic>> selectedLocations = [];
  List<dynamic> searchSuggestions = [];
  bool isSearchingLocations = false;
  final locationSearchController = TextEditingController();
  String selectedSearchType = 'city'; // 'country', 'state', 'city', 'zip'

  String objective = 'Lead Generation';
  bool isInitialized = false;

  String headline = '';
  String primaryText = '';
  String creativeUrl = '';
  bool isRunningAd = false;

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        if (endDate != null && endDate!.isBefore(startDate)) {
          endDate = startDate.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate.add(const Duration(days: 7)),
      firstDate: startDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      // 1. Retrieve suggested ad structure to pre-fill details
      final recommendedAd = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (recommendedAd != null) {
        headline = recommendedAd['headline'] ?? 'Get More Leads for Your Business';
        primaryText = recommendedAd['primaryText'] ?? 'We help you grow your business with digital marketing strategies.';
        creativeUrl = recommendedAd['creativeUrl'] ?? ''; // backend will fallback if empty

        campaignNameController.text = 'Campaign - $headline';
        
        final cta = recommendedAd['callToAction']?.toString().toLowerCase() ?? '';
        if (cta.contains('lead') || cta.contains('signup')) {
          objective = 'Lead Generation';
        } else if (cta.contains('sale') || cta.contains('buy') || cta.contains('shop')) {
          objective = 'Sales';
        } else if (cta.contains('visit') || cta.contains('learn') || cta.contains('read')) {
          objective = 'Website Traffic';
        } else {
          objective = 'Brand Awareness';
        }
      } else {
        campaignNameController.text = 'Leads Campaign - May 2024';
        headline = 'Special Offer';
        primaryText = 'Check out our services!';
      }
      isInitialized = true;
    }
  }

  @override
  void dispose() {
    campaignNameController.dispose();
    adAccountIdController.dispose();
    budgetController.dispose();
    locationSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocations(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        searchSuggestions = [];
      });
      return;
    }
    
    setState(() {
      isSearchingLocations = true;
    });
    
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;
      
      final res = await AdService.searchGeolocation(
        token: token,
        query: query,
        type: selectedSearchType,
      );
      if (res['success'] == true && mounted) {
        setState(() {
          searchSuggestions = res['data'] ?? [];
        });
      } else {
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Failed to search locations');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error searching locations: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isSearchingLocations = false;
        });
      }
    }
  }

  Future<void> _runAd() async {
    final adAccountId = adAccountIdController.text.trim();
    if (adAccountId.isEmpty || adAccountId == 'act_') {
      showAppSnackBar(context, 'Please enter your Meta Ad Account ID (e.g. act_12345678)');
      return;
    }

    final token = ref.read(authProvider).token;
    if (token == null) {
      showAppSnackBar(context, 'Session expired. Please login again.');
      return;
    }

    setState(() => isRunningAd = true);
    try {
      final res = await AdService.createAdCampaign(
        token: token,
        adAccountId: adAccountId,
        campaignName: campaignNameController.text.trim(),
        objective: objective,
        budget: budgetController.text.trim(),
        headline: headline,
        primaryText: primaryText,
        creativeUrl: creativeUrl,
        startTime: startDate.toUtc().toIso8601String(),
        endTime: runContinuously ? null : endDate?.toUtc().toIso8601String(),
        targetingCountry: selectedCountry,
        ageMin: ageMin,
        ageMax: ageMax,
        gender: selectedGender,
        selectedLocations: selectedLocations,
      );

      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ad_account_id', adAccountId);
        if (mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
              title: const Text('Campaign Launched!'),
              content: Text(
                'Campaign successfully created on Meta Ads Manager.\n\n'
                'Campaign ID:\n${res['campaignId']}\n\n'
                'Ad Set ID:\n${res['adsetId']}\n\n'
                'Ad ID:\n${res['adId']}\n\n'
                'Status: Created as PAUSED so you can review before starting spend.',
                style: const TextStyle(fontSize: 11.5),
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to use analysis
                    Navigator.pop(context); // Go back to analysis report
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Campaign creation failed.');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error launching ad campaign: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isRunningAd = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Ad Setup', subtitle: 'Review and run your ad campaign.'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel('Ad Account ID'),
                    isLoadingAccounts
                        ? const SizedBox(
                            height: 48,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : enterManually
                            ? TextField(
                                controller: adAccountIdController,
                                enabled: !isRunningAd,
                                decoration: const InputDecoration(hintText: 'Enter act_ followed by Ad Account ID'),
                              )
                            : DropdownButtonFormField<String>(
                                value: selectedAdAccountId,
                                decoration: const InputDecoration(
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
                                onChanged: isRunningAd
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          setState(() {
                                            selectedAdAccountId = val;
                                            adAccountIdController.text = val;
                                          });
                                        }
                                      },
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
                    const SizedBox(height: 14),
                    const FormLabel('Campaign Name'),
                    TextField(
                      controller: campaignNameController,
                      enabled: !isRunningAd,
                      decoration: const InputDecoration(hintText: 'Enter Campaign Name'),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Objective'),
                    DropdownButtonFormField<String>(
                      value: objective,
                      items: [
                        'Lead Generation',
                        'Website Traffic',
                        'Brand Awareness',
                        'Sales',
                        'App Promotion',
                        'Engagement'
                      ]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: isRunningAd ? null : (value) => setState(() => objective = value ?? objective),
                    ),
                    const SizedBox(height: 14),
                    const SizedBox(height: 14),
                    const FormLabel('Location Targeting'),
                    const Text(
                      'Select target type, search, and add locations. You can mix countries, states, cities, or pincodes.',
                      style: TextStyle(color: AppColors.muted, fontSize: 10.5),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['country', 'state', 'city', 'zip'].map((t) {
                          final isSel = selectedSearchType == t;
                          final label = t == 'country'
                              ? 'Country'
                              : t == 'state'
                                  ? 'State / Region'
                                  : t == 'city'
                                      ? 'City'
                                      : 'Pincode / Zip';
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(label, style: const TextStyle(fontSize: 11)),
                              selected: isSel,
                              onSelected: isRunningAd ? null : (val) {
                                if (val) {
                                  setState(() {
                                    selectedSearchType = t;
                                    searchSuggestions = [];
                                    locationSearchController.clear();
                                  });
                                }
                              },
                              showCheckmark: false,
                              selectedColor: AppColors.lavender,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: isSel ? AppColors.primary : AppColors.border),
                              labelStyle: TextStyle(
                                color: isSel ? AppColors.primary : AppColors.muted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationSearchController,
                      enabled: !isRunningAd,
                      decoration: InputDecoration(
                        hintText: selectedSearchType == 'country'
                            ? 'Search Country (e.g. India, United States)...'
                            : selectedSearchType == 'state'
                                ? 'Search State (e.g. Maharashtra, California)...'
                                : selectedSearchType == 'city'
                                    ? 'Search City (e.g. Mumbai, New York)...'
                                    : 'Search Pincode / Zip Code (e.g. 400001, 94025)...',
                        suffixIcon: isSearchingLocations
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search_rounded, size: 20),
                                onPressed: () => _searchLocations(locationSearchController.text),
                              ),
                      ),
                      onChanged: (val) {
                        if (val.trim().length >= 2) {
                          _searchLocations(val);
                        } else {
                          setState(() => searchSuggestions = []);
                        }
                      },
                    ),
                    if (searchSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = searchSuggestions[index];
                            final name = suggestion['name'] ?? '';
                            final country = suggestion['country_code'] ?? '';
                            
                            final rawType = suggestion['type'] ?? selectedSearchType;
                            final typeLabel = rawType == 'zip'
                                ? 'Pincode'
                                : rawType == 'region'
                                    ? 'State'
                                    : rawType == 'country'
                                        ? 'Country'
                                        : 'City';
                            
                            return ListTile(
                              dense: true,
                              title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              subtitle: Text('$typeLabel • $country', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                              onTap: () {
                                final alreadySelected = selectedLocations.any((loc) => loc['key'] == suggestion['key']);
                                if (!alreadySelected) {
                                  setState(() {
                                    selectedLocations.add({
                                      'key': suggestion['key'],
                                      'name': name,
                                      'type': rawType,
                                    });
                                    searchSuggestions = [];
                                    locationSearchController.clear();
                                  });
                                } else {
                                  showAppSnackBar(context, 'Location already added');
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    if (selectedLocations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedLocations.map((loc) {
                          final label = loc['name'] ?? '';
                          final rawType = loc['type'] ?? '';
                          final type = rawType == 'zip'
                              ? 'Zip'
                              : rawType == 'region'
                                  ? 'State'
                                  : rawType == 'country'
                                      ? 'Country'
                                      : 'City';
                          return Chip(
                            label: Text('$label ($type)', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: isRunningAd ? null : () {
                              setState(() {
                                selectedLocations.removeWhere((l) => l['key'] == loc['key']);
                              });
                            },
                            visualDensity: VisualDensity.compact,
                            backgroundColor: AppColors.lavender.withAlpha(100),
                            side: const BorderSide(color: AppColors.primary, width: 0.5),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const FormLabel('Age Range'),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: ageMin,
                            decoration: const InputDecoration(
                              labelText: 'Min Age',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: List.generate(48, (index) => index + 18)
                                .map((age) => DropdownMenuItem(value: age, child: Text('$age')))
                                .toList(),
                            onChanged: isRunningAd
                                ? null
                                : (val) => setState(() {
                                      ageMin = val ?? 18;
                                      if (ageMax < ageMin) ageMax = ageMin;
                                    }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: ageMax,
                            decoration: const InputDecoration(
                              labelText: 'Max Age',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: List.generate(48, (index) => index + ageMin)
                                .map((age) => DropdownMenuItem(value: age, child: Text('$age')))
                                .toList(),
                            onChanged: isRunningAd ? null : (val) => setState(() => ageMax = val ?? 65),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Gender'),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Genders')),
                        DropdownMenuItem(value: 'MALE', child: Text('Male Only')),
                        DropdownMenuItem(value: 'FEMALE', child: Text('Female Only')),
                      ],
                      onChanged: isRunningAd ? null : (val) => setState(() => selectedGender = val ?? 'ALL'),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Budget (₹ / day)'),
                    TextField(
                      controller: budgetController,
                      enabled: !isRunningAd,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Enter Daily Budget (e.g. 500)'),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Duration'),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: isRunningAd ? null : () => _selectStartDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${startDate.day}/${startDate.month}/${startDate.year}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!runContinuously) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: isRunningAd ? null : () => _selectEndDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      endDate != null
                                          ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                          : 'Select End Date',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: runContinuously,
                            activeColor: AppColors.primary,
                            onChanged: isRunningAd
                                ? null
                                : (val) {
                                    setState(() {
                                      runContinuously = val ?? false;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Run continuously (no end date)',
                          style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Placements'),
                    const Row(
                      children: [
                        TinyPlatformIcon(type: 'facebook'),
                        SizedBox(width: 12),
                        TinyPlatformIcon(type: 'instagram'),
                        SizedBox(width: 12),
                        TinyPlatformIcon(type: 'google'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: isRunningAd ? 'Launching Campaign...' : 'Review & Run Ad',
                      onPressed: isRunningAd ? null : _runAd,
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
