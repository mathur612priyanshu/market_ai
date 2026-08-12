import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../routes.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateAdSetScreen extends ConsumerStatefulWidget {
  const CreateAdSetScreen({super.key});

  @override
  ConsumerState<CreateAdSetScreen> createState() => _CreateAdSetScreenState();
}

class _CreateAdSetScreenState extends ConsumerState<CreateAdSetScreen> {
  final adSetNameController = TextEditingController();
  final budgetController = TextEditingController(text: '500');
  final locationSearchController = TextEditingController();

  int ageMin = 18;
  int ageMax = 65;
  String selectedGender = 'ALL';

  List<Map<String, dynamic>> selectedLocations = [];
  List<dynamic> searchSuggestions = [];
  bool isSearchingLocations = false;
  String selectedSearchType = 'city'; // 'country', 'state', 'city', 'zip'

  late DateTime startDate;
  late TimeOfDay startTime;
  late DateTime? endDate;
  late TimeOfDay endTime;
  bool showEndDate = true;

  // Dynamic details based on objective
  String appStore = 'GOOGLE_PLAY';
  final appIdController = TextEditingController();
  final appStoreUrlController = TextEditingController();
  final pixelIdController = TextEditingController();
  String engagementType = 'POST_ENGAGEMENT';
  String leadContactType = 'INSTANT_FORMS';
  String trafficDestination = 'WEBSITE';
  String conversionEvent = 'PURCHASE';

  bool isSubmitting = false;
  
  // Passed parameters from Step 1
  String? campaignId;
  String? adAccountId;
  String? campaignName;
  String selectedObjective = 'Lead Generation';
  bool advantageBudgetEnabled = false;
  String bidStrategy = 'HIGHEST_VOLUME';
  final bidAmountController = TextEditingController(text: '100');

  List<dynamic> advertisableApps = [];
  bool isLoadingApps = false;
  bool hasFetchedApps = false;

  @override
  void initState() {
    super.initState();
    // A past midnight default is rejected by Meta. Start slightly ahead so the
    // request remains valid after the user finishes the form.
    final initialStart = DateTime.now().add(const Duration(minutes: 15));
    startDate = DateTime(initialStart.year, initialStart.month, initialStart.day);
    startTime = TimeOfDay(hour: initialStart.hour, minute: initialStart.minute);
    final initialEnd = initialStart.add(const Duration(days: 7));
    endDate = DateTime(initialEnd.year, initialEnd.month, initialEnd.day);
    endTime = TimeOfDay(hour: initialEnd.hour, minute: initialEnd.minute);
  }

  Future<void> _fetchAppsOnce() async {
    if (hasFetchedApps || isLoadingApps || adAccountId == null) return;
    setState(() {
      isLoadingApps = true;
    });
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;
      final res = await AdService.fetchAdvertisableApps(token: token, adAccountId: adAccountId!);
      if (res['success'] == true && mounted) {
        setState(() {
          advertisableApps = res['apps'] ?? [];
          hasFetchedApps = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching advertisable apps: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingApps = false;
        });
      }
    }
  }

  @override
  void dispose() {
    adSetNameController.dispose();
    budgetController.dispose();
    locationSearchController.dispose();
    appIdController.dispose();
    appStoreUrlController.dispose();
    pixelIdController.dispose();
    bidAmountController.dispose();
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : (endDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  Future<void> _submitAdSet() async {
    final name = adSetNameController.text.trim();
    if (name.isEmpty) {
      showAppSnackBar(context, 'Please enter an Ad Set Name');
      return;
    }

    final budget = double.tryParse(budgetController.text.trim());
    if (!advantageBudgetEnabled && (budget == null || budget <= 0)) {
      showAppSnackBar(context, 'Please enter a valid daily budget');
      return;
    }

    final hasBidCap = bidStrategy == 'BID_CAP' || bidStrategy == 'COST_CAP';
    final bidAmount = double.tryParse(bidAmountController.text.trim());
    if (hasBidCap && (bidAmount == null || bidAmount <= 0)) {
      showAppSnackBar(context, 'Please enter a valid bid amount limit for the selected strategy');
      return;
    }

    // Dynamic field validation
    if (selectedObjective == 'App Promotion' && appIdController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please enter the Meta App ID');
      return;
    }
    final appStoreUri = Uri.tryParse(appStoreUrlController.text.trim());
    if (selectedObjective == 'App Promotion' &&
        (appStoreUri == null ||
            (appStoreUri.scheme != 'https' && appStoreUri.scheme != 'http') ||
            appStoreUri.host.isEmpty)) {
      showAppSnackBar(context, 'Please enter a valid Google Play or Apple App Store URL');
      return;
    }
    if (selectedObjective == 'Sales' && pixelIdController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please enter the Meta Pixel / Dataset ID for Sales.');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final startDt = DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
      if (!startDt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        showAppSnackBar(context, 'Choose a start time at least 5 minutes from now');
        return;
      }
      final startIso = startDt.toUtc().toIso8601String();
      
      String? endIso;
      if (showEndDate && endDate != null) {
        final endDt = DateTime(endDate!.year, endDate!.month, endDate!.day, endTime.hour, endTime.minute);
        if (!endDt.isAfter(startDt)) {
          showAppSnackBar(context, 'End time must be after the start time');
          return;
        }
        endIso = endDt.toUtc().toIso8601String();
      }

      final res = await AdService.createAdSetOnly(
        token: token,
        adAccountId: adAccountId!,
        campaignId: campaignId!,
        adSetName: name,
        budget: advantageBudgetEnabled ? null : budgetController.text.trim(),
        selectedLocations: selectedLocations,
        ageMin: ageMin,
        ageMax: ageMax,
        gender: selectedGender,
        objective: selectedObjective,
        destinationType: _destinationTypeForObjective(),
        engagementType: selectedObjective == 'Engagement' ? engagementType : null,
        appId: selectedObjective == 'App Promotion' ? appIdController.text.trim() : null,
        appStoreUrl: selectedObjective == 'App Promotion' ? appStoreUrlController.text.trim() : null,
        pixelId: selectedObjective == 'Sales' ? pixelIdController.text.trim() : null,
        conversionEvent: selectedObjective == 'Sales' ? conversionEvent : null,
        startTime: startIso,
        endTime: endIso,
        bidAmount: hasBidCap ? bidAmountController.text.trim() : null,
        bidStrategy: bidStrategy,
        useCampaignBudget: advantageBudgetEnabled,
      );

      if (res['success'] == true && mounted) {
        final adsetId = res['adsetId'];
        showAppSnackBar(context, 'Ad Set created successfully!');

        // Go to Step 3 (Ad Details / Creative creation)
        Navigator.pushNamed(
          context,
          AppRoutes.createAd,
          arguments: {
            'adsetId': adsetId,
            'adAccountId': adAccountId,
            'campaignName': campaignName,
          },
        );
      } else {
        if (mounted) {
          final errorText = res['error'] ?? 'Failed to create Ad Set';
          final pageId = res['pageId']?.toString();
          
          if (errorText.toLowerCase().contains('terms of service') || 
              errorText.toLowerCase().contains('lead generation terms') || 
              errorText.toLowerCase().contains('accept facebook\'s lead generation')) {
            _showTermsDialog(pageId);
          } else {
            showAppSnackBar(context, errorText);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error creating Ad Set: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _showTermsDialog(String? pageId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Action Required', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meta requires you to accept their Lead Generation Terms of Service for your Facebook Page before you can create Lead Ads.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tapping the button below will open Facebook directly to pre-select your page for quick agreement.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final String pageQuery = pageId != null ? '?page_id=$pageId' : '';
              final url = 'https://www.facebook.com/ads/leadgen/tos$pageQuery';
              final uri = Uri.parse(url);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (mounted) {
                  showAppSnackBar(context, 'Could not open browser: $e');
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Open & Accept Terms', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Parse navigation arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      campaignId = args['campaignId'];
      adAccountId = args['adAccountId'];
      campaignName = args['campaignName'];
      selectedObjective = args['objective'] ?? 'Lead Generation';
      advantageBudgetEnabled = args['advantageBudgetEnabled'] ?? false;
      bidStrategy = args['bidStrategy'] ?? 'HIGHEST_VOLUME';
      
      if (adSetNameController.text.isEmpty && campaignName != null) {
        adSetNameController.text = '$campaignName Ad Set';
      }

      if (selectedObjective == 'App Promotion') {
        Future.microtask(() => _fetchAppsOnce());
      }
    }

    if (campaignId == null || adAccountId == null) {
      return const Scaffold(
        body: Center(child: Text('Invalid Arguments Passed')),
      );
    }

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
                      title: 'Configure Ad Set',
                      subtitle: 'Step 2: Set audience and settings',
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
                    // Ad Set Name
                    const FormLabel('Ad Set Name'),
                    TextField(
                      controller: adSetNameController,
                      decoration: const InputDecoration(hintText: 'Enter Ad Set Name'),
                    ),
                    const SizedBox(height: 14),

                    // Daily Budget
                    if (!advantageBudgetEnabled) ...[
                      const FormLabel('Daily Budget (₹)'),
                      TextField(
                        controller: budgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Enter Daily Budget'),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Bid Cap / Cost Limit
                    if (bidStrategy == 'BID_CAP' || bidStrategy == 'COST_CAP') ...[
                      const FormLabel('Bid Cap / Cost Limit per Result (₹)'),
                      TextField(
                        controller: bidAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 100'),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Dynamic Fields based on Objective Selection
                    _buildDynamicFields(),
                    const SizedBox(height: 18),

                    // Geolocation targeting selector
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
                              onSelected: (val) {
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
                                if (alreadySelected) {
                                  showAppSnackBar(context, 'Location already added');
                                  return;
                                }

                                final countryCode = country.toUpperCase();
                                final rawType = suggestion['type'] ?? selectedSearchType;

                                // Case A: Selecting a Country
                                if (rawType == 'country') {
                                  final countryKey = suggestion['key']?.toString().toUpperCase() ?? '';
                                  setState(() {
                                    // Remove any sub-regions/cities of this country to prevent conflict
                                    selectedLocations.removeWhere((loc) =>
                                        loc['country_code']?.toString().toUpperCase() == countryKey ||
                                        loc['country_code']?.toString().toUpperCase() == countryCode);
                                    
                                    selectedLocations.add({
                                      'key': suggestion['key'],
                                      'name': name,
                                      'type': rawType,
                                      'country_code': countryCode,
                                    });
                                    searchSuggestions = [];
                                    locationSearchController.clear();
                                  });
                                  showAppSnackBar(context, 'Added country and removed sub-regions to prevent conflict.');
                                  return;
                                }

                                // Case B: Selecting City, State, or Zip
                                // Check if the parent Country of this suggestion is already selected
                                final isCountryTargeted = selectedLocations.any((loc) =>
                                    loc['type'] == 'country' &&
                                    (loc['key']?.toString().toUpperCase() == countryCode ||
                                     loc['country_code']?.toString().toUpperCase() == countryCode));

                                if (isCountryTargeted) {
                                  showAppSnackBar(context, 'The parent country is already targeted. Sub-regions are already included.');
                                  return;
                                }

                                setState(() {
                                  selectedLocations.add({
                                    'key': suggestion['key'],
                                    'name': name,
                                    'type': rawType,
                                    'country_code': countryCode,
                                  });
                                  searchSuggestions = [];
                                  locationSearchController.clear();
                                });
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
                            onDeleted: () {
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

                    // Age Range
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
                            onChanged: (val) => setState(() => ageMin = val ?? ageMin),
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
                            items: List.generate(48, (index) => index + 18)
                                .map((age) => DropdownMenuItem(value: age, child: Text('$age')))
                                .toList(),
                            onChanged: (val) => setState(() => ageMax = val ?? ageMax),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Gender Selector
                    const FormLabel('Gender'),
                    Row(
                      children: ['ALL', 'MALE', 'FEMALE'].map((g) {
                        final isSel = selectedGender == g;
                        final label = g == 'ALL' ? 'All' : g == 'MALE' ? 'Men' : 'Women';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setState(() => selectedGender = g);
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
                    const SizedBox(height: 18),

                    // Schedule Picker
                    const FormLabel('Schedule'),
                    AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${startDate.day}/${startDate.month}/${startDate.year}', style: const TextStyle(fontSize: 12)),
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.muted),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(startTime.format(context), style: const TextStyle(fontSize: 12)),
                                        const Icon(Icons.access_time_rounded, size: 16, color: AppColors.muted),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Set End Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              Switch.adaptive(
                                value: showEndDate,
                                activeColor: AppColors.primary,
                                onChanged: (val) => setState(() => showEndDate = val),
                              ),
                            ],
                          ),
                          if (showEndDate) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            endDate == null
                                                ? 'Choose Date'
                                                : '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.muted),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(endTime.format(context), style: const TextStyle(fontSize: 12)),
                                          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.muted),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

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
                        onPressed: isSubmitting ? null : _submitAdSet,
                        child: isSubmitting
                            ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            : const Text('Continue to Ad Creative', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildDynamicFields() {
    switch (selectedObjective) {
      case 'App Promotion':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informative Help Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lavender.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'What is Meta App ID?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'To promote a mobile app, Meta requires that your app is registered on the Facebook Developers portal.\n\n'
                    '1. Go to developers.facebook.com -> My Apps.\n'
                    '2. Copy the numeric "App ID" (e.g. 102938475612345) and paste it below.\n'
                    '3. Alternatively, select any app already linked to your Ad Account from the list below.',
                    style: TextStyle(fontSize: 10.5, color: Colors.black87, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Dropdown / Loader for advertisable apps linked to Meta Ad Account
            if (isLoadingApps) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ] else if (advertisableApps.isNotEmpty) ...[
              const FormLabel('Choose Linked App'),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'Select an app linked to this Ad Account',
                ),
                items: advertisableApps.map<DropdownMenuItem<String>>((app) {
                  final appId = app['id']?.toString() ?? '';
                  final appName = app['name']?.toString() ?? 'Unnamed App';
                  return DropdownMenuItem<String>(
                    value: appId,
                    child: Text('$appName ($appId)'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      appIdController.text = val;
                      final matchedApp = advertisableApps.firstWhere((a) => a['id']?.toString() == val, orElse: () => null);
                      if (matchedApp != null && matchedApp['object_store_urls'] != null) {
                        final storeUrls = matchedApp['object_store_urls'] as Map<String, dynamic>;
                        if (storeUrls.containsKey('itunes') && !storeUrls.containsKey('google_play')) {
                          appStore = 'ITUNES';
                        } else {
                          appStore = 'GOOGLE_PLAY';
                        }
                        final selectedStoreUrl = appStore == 'ITUNES'
                            ? storeUrls['itunes']
                            : storeUrls['google_play'];
                        if (selectedStoreUrl != null) {
                          appStoreUrlController.text = selectedStoreUrl.toString();
                        }
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
            ],

            const FormLabel('App Store Location'),
            DropdownButtonFormField<String>(
              value: appStore,
              items: const [
                DropdownMenuItem(value: 'GOOGLE_PLAY', child: Text('Google Play Store')),
                DropdownMenuItem(value: 'ITUNES', child: Text('Apple iOS App Store')),
              ],
              onChanged: (val) {
                final nextStore = val ?? 'GOOGLE_PLAY';
                final selectedApp = advertisableApps.firstWhere(
                      (app) => app['id']?.toString() == appIdController.text.trim(),
                      orElse: () => null,
                    );
                final storeUrls = selectedApp?['object_store_urls'];
                final storeUrl = storeUrls is Map
                    ? storeUrls[nextStore == 'ITUNES' ? 'itunes' : 'google_play']
                    : null;
                setState(() {
                  appStore = nextStore;
                  if (storeUrl != null) appStoreUrlController.text = storeUrl.toString();
                });
              },
            ),
            const SizedBox(height: 12),

            const FormLabel('Meta App ID (Numeric)'),
            TextField(
              controller: appIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 102938475612345',
              ),
            ),
            const SizedBox(height: 12),
            const FormLabel('App Store URL'),
            TextField(
              controller: appStoreUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://play.google.com/store/apps/details?id=...',
              ),
            ),
          ],
        );
      case 'Engagement':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormLabel('Engagement Objective Goal'),
            DropdownButtonFormField<String>(
              value: engagementType,
              items: const [
                DropdownMenuItem(value: 'POST_ENGAGEMENT', child: Text('Get people to engage with posts')),
              ],
              onChanged: (val) => setState(() => engagementType = val ?? 'POST_ENGAGEMENT'),
            ),
          ],
        );
      case 'Lead Generation':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormLabel('Lead Form Setup Type'),
            DropdownButtonFormField<String>(
              value: leadContactType,
              items: const [
                DropdownMenuItem(value: 'INSTANT_FORMS', child: Text('Generate leads using Instant Forms')),
              ],
              onChanged: (val) => setState(() => leadContactType = val ?? 'INSTANT_FORMS'),
            ),
          ],
        );
      case 'Website Traffic':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormLabel('Target Destination Type'),
            DropdownButtonFormField<String>(
              value: trafficDestination,
              items: const [
                DropdownMenuItem(value: 'WEBSITE', child: Text('Website / Landing Page')),
              ],
              onChanged: (val) => setState(() => trafficDestination = val ?? 'WEBSITE'),
            ),
          ],
        );
      case 'Sales':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormLabel('Meta Pixel / Dataset ID'),
            TextField(
              controller: pixelIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter the Pixel or Dataset ID'),
            ),
            const SizedBox(height: 12),
            const FormLabel('Conversion Event'),
            DropdownButtonFormField<String>(
              value: conversionEvent,
              items: const [
                DropdownMenuItem(value: 'PURCHASE', child: Text('Purchase')),
                DropdownMenuItem(value: 'LEAD', child: Text('Lead')),
                DropdownMenuItem(value: 'ADD_TO_CART', child: Text('Add to Cart')),
              ],
              onChanged: (val) => setState(() => conversionEvent = val ?? 'PURCHASE'),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  String? _destinationTypeForObjective() {
    switch (selectedObjective) {
      case 'Lead Generation':
        return leadContactType;
      case 'Website Traffic':
      case 'Sales':
        return trafficDestination;
      case 'App Promotion':
        return appStore;
      default:
        return null;
    }
  }
}
