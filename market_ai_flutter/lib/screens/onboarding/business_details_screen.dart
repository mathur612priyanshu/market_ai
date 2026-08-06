import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../server_url.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BusinessDetailsScreen extends ConsumerStatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  ConsumerState<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final websiteController = TextEditingController();
  
  bool isLoading = false;
  String? logoPath;
  String? logoNetworkUrl;
  final services = <String>['Digital Marketing', 'SEO', 'Social Media'];
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSocialAutofill();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadSocialAutofill() async {
    final session = ref.read(authProvider);
    final token = session.token;
    if (token == null) return;

    setState(() => isLoading = true);
    try {
      // 1. Fetch fresh user profile details directly from database
      final profileRes = await AuthService.getProfile(token);
      Map<String, dynamic>? freshUser;
      if (profileRes['success'] == true) {
        freshUser = profileRes['user'];
        // Synchronize in local memory and cache storage
        ref.read(authProvider.notifier).updateUser(freshUser!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(freshUser));
      }

      // 2. Fetch social status for Facebook autofill fallback
      final socialRes = await AuthService.fetchSocialStatus(token);
      
      if (mounted) {
        final user = freshUser ?? session.user;
        final currentBusinessName = user?['businessName'] as String?;
        final currentBusinessLogo = user?['businessLogo'] as String?;

        final accounts = socialRes['success'] == true ? (socialRes['accounts'] as List<dynamic>? ?? []) : [];
        final facebookPage = accounts.firstWhere(
          (acc) => acc['platform'] == 'facebook',
          orElse: () => null,
        );

        if (currentBusinessName != null && currentBusinessName.isNotEmpty) {
          // User already has business information saved in DB -> Load it directly
          setState(() {
            nameController.text = currentBusinessName;
            addressController.text = user?['businessAddress'] ?? '';
            websiteController.text = user?['businessWebsite'] ?? '';
            logoNetworkUrl = currentBusinessLogo;

            final savedServicesText = user?['businessServices'] as String?;
            if (savedServicesText != null && savedServicesText.isNotEmpty) {
              try {
                final list = jsonDecode(savedServicesText) as List<dynamic>;
                services.clear();
                services.addAll(list.map((e) => e.toString()));
              } catch (_) {}
            }
          });
        } else {
          // No business info exists in DB -> Suggest autofill from connected page if exists
          if (facebookPage != null) {
            setState(() {
              nameController.text = facebookPage['accountName'] ?? '';
              logoNetworkUrl = facebookPage['profilePicture'];
            });
            showAppSnackBar(context, 'Suggested business name and logo loaded from your Facebook Page!');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading initial details profile: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          logoPath = picked.path;
          logoNetworkUrl = null; // Clear autofill remote picture if user chooses custom
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error picking image: $e');
      }
    }
  }

  Future<void> _addService() async {
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _AddServiceDialog(),
    );
    if (value != null && value.isNotEmpty) {
      setState(() => services.add(value));
    }
  }

  Future<void> _saveBusinessDetails() async {
    if (nameController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please enter your Business Name');
      return;
    }
    if (addressController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please enter your Business Address');
      return;
    }

    final session = ref.read(authProvider);
    final token = session.token;
    if (token == null) {
      showAppSnackBar(context, 'Session expired. Please login again.');
      return;
    }

    setState(() => isLoading = true);
    try {
      String? businessLogo = logoNetworkUrl;

      // 1. Upload custom logo if selected via image_picker
      if (logoPath != null) {
        final uploadRes = await AuthService.uploadBusinessLogo(token: token, imagePath: logoPath!);
        if (uploadRes['success'] == true) {
          businessLogo = uploadRes['businessLogo'];
        } else {
          showAppSnackBar(context, uploadRes['message'] ?? 'Failed to upload custom logo');
          setState(() => isLoading = false);
          return;
        }
      }

      // 2. Update text details and services
      final res = await AuthService.updateBusinessProfile(
        token: token,
        businessName: nameController.text.trim(),
        businessAddress: addressController.text.trim(),
        businessWebsite: websiteController.text.trim().isNotEmpty ? websiteController.text.trim() : null,
        businessServices: services,
        businessLogo: businessLogo,
      );

      if (res['success'] == true) {
        // Persist updated user details locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(res['user']));

        // Cache the updated user details inside state
        ref.read(authProvider.notifier).updateUser(res['user']);
        
        if (mounted) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final isEditMode = args?['isEditMode'] == true;
          if (isEditMode) {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
          }
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, res['message'] ?? 'Failed to save profile details');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error communicating with backend: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildLogoPreview() {
    if (logoPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(logoPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    if (logoNetworkUrl != null) {
      final fullUrl = logoNetworkUrl!.startsWith('http') ? logoNetworkUrl! : '$baseUrl$logoNetworkUrl';
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          fullUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.muted, size: 24),
              SizedBox(height: 4),
              Text('Logo unavailable', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
        ),
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.ios_share_rounded, color: AppColors.primary, size: 28),
        SizedBox(height: 7),
        Text('Upload Logo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
        SizedBox(height: 3),
        Text('JPG, PNG (Max. 2MB)', style: TextStyle(color: AppColors.muted, fontSize: 10.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final isEditMode = args?['isEditMode'] == true;

    return PopScope(
      canPop: isEditMode,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: ScreenHeader(title: 'Business Information', subtitle: 'Tell us about your business', showBack: isEditMode),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FormLabel('Business Logo'),
                      InkWell(
                        onTap: isLoading ? null : _pickLogo,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 118,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _buildLogoPreview(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    const FormLabel('Business Name'),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: 'ABC Digital Solutions'),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Business Address'),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(hintText: '123, MG Road, Bangalore, India'),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Website (Optional)'),
                    TextField(
                      controller: websiteController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(hintText: 'www.abcdigitals.com'),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Services Offered'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...services.map(
                          (service) => InputChip(
                            label: Text(service),
                            backgroundColor: AppColors.lavender,
                            labelStyle: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                            side: BorderSide.none,
                            onDeleted: isLoading ? null : () => setState(() => services.remove(service)),
                            deleteIconColor: AppColors.primary,
                            deleteIcon: const Icon(Icons.close, size: 15),
                          ),
                        ),
                        ActionChip(
                          label: const Text('+ Add More'),
                          onPressed: isLoading ? null : _addService,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          labelStyle: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 27),
                    PrimaryButton(
                      label: isLoading ? 'Saving details...' : 'Save & Continue',
                      onPressed: isLoading ? () {} : _saveBusinessDetails,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _AddServiceDialog extends StatefulWidget {
  const _AddServiceDialog();

  @override
  State<_AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<_AddServiceDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add service'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Service name (e.g. Graphic Design)'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
