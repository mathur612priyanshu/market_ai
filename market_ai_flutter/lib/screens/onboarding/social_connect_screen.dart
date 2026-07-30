import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../server_url.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SocialConnectScreen extends ConsumerStatefulWidget {
  const SocialConnectScreen({super.key});

  @override
  ConsumerState<SocialConnectScreen> createState() => _SocialConnectScreenState();
}

class _SocialConnectScreenState extends ConsumerState<SocialConnectScreen> {
  bool facebookConnected = false;
  bool instagramConnected = false;
  bool isLoadingStatus = false;
  List<dynamic> connectedAccounts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final session = ref.read(authProvider);
    final token = session.token;
    if (token == null) return;

    setState(() => isLoadingStatus = true);
    try {
      final res = await AuthService.fetchSocialStatus(token);
      if (res['success'] == true) {
        setState(() {
          facebookConnected = res['facebookConnected'] ?? false;
          instagramConnected = res['instagramConnected'] ?? false;
          connectedAccounts = res['accounts'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error checking social status: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingStatus = false);
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Could not launch URL: $e');
      }
    }
  }

  void _connectFacebook() {
    final session = ref.read(authProvider);
    final userId = session.user?['id'];
    if (userId == null) {
      showAppSnackBar(context, 'Session user ID not found');
      return;
    }
    final url = '$baseUrl/api/auth/facebook?userId=$userId';
    _launchUrl(url);
  }

  void _connectInstagram() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect Instagram'),
        content: const Text('Instagram accounts are connected via Facebook. Connecting Facebook will automatically import your linked Instagram Business profiles.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _connectFacebook();
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showCreatePageDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CreatePageDialog(
        token: ref.read(authProvider).token ?? '',
        onSuccess: () {
          _checkStatus();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                ),
              ),
              const Spacer(flex: 2),
              const Text('Connect your social accounts', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              const Text(
                'Connect to analyze and grow your presence',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 38),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: facebookConnected ? 'Facebook Connected' : 'Connect Facebook',
                  icon: facebookConnected ? Icons.check_circle_rounded : Icons.facebook,
                  color: AppColors.blue,
                  onPressed: _connectFacebook,
                ),
              ),
              if (facebookConnected) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showCreatePageDialog,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Create New Facebook Page', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: instagramConnected ? 'Instagram Connected' : 'Connect Instagram',
                  icon: instagramConnected ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                  color: AppColors.instagram,
                  onPressed: _connectInstagram,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: isLoadingStatus ? null : _checkStatus,
                icon: isLoadingStatus
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Refresh Connection Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              if (connectedAccounts.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Connected Accounts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                ...connectedAccounts.map((acc) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.lavender,
                      backgroundImage: acc['profilePicture'] != null ? NetworkImage(acc['profilePicture']) : null,
                      child: acc['profilePicture'] == null
                          ? Icon(
                              acc['platform'] == 'facebook' ? Icons.facebook : Icons.camera_alt_rounded,
                              color: AppColors.primary,
                              size: 18,
                            )
                          : null,
                    ),
                    title: Text(acc['accountName'] ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      acc['platform'] == 'facebook' ? 'Facebook Page' : 'Instagram Business',
                      style: const TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  ),
                )),
              ],
              const Spacer(flex: 4),
              const Text('You can add or remove later from settings', style: TextStyle(color: AppColors.muted, fontSize: 11)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.businessDetails),
                child: const Text('Skip for now', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
              ),
              if (facebookConnected || instagramConnected) ...[
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.businessDetails),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatePageDialog extends StatefulWidget {
  const _CreatePageDialog({required this.token, required this.onSuccess});
  final String token;
  final VoidCallback onSuccess;

  @override
  State<_CreatePageDialog> createState() => _CreatePageDialogState();
}

class _CreatePageDialogState extends State<_CreatePageDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final aboutController = TextEditingController();
  final categorySearchController = TextEditingController();
  String? categoryId;
  bool isCreating = false;
  bool isLoadingCategories = true;
  bool showSuggestions = false;
  List<dynamic> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await AuthService.fetchFacebookCategories(widget.token);
      if (res['success'] == true && mounted) {
        setState(() {
          categories = res['categories'] ?? [];
          if (categories.isNotEmpty) {
            categoryId = categories.first['id']?.toString();
            categorySearchController.text = categories.first['name'] ?? '';
          }
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    aboutController.dispose();
    categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showMetaRestrictionDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 40),
        title: const Text('Meta Platform Restriction', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text(
          'While your app is in Development Mode, Meta restricts programmatic Page creation via API to official "Test Users". Real accounts (even Admin/Developers) cannot create pages via the API.\n\n'
          'Would you like to open Facebook in your browser to create a Page manually, then sync it back here?',
          style: TextStyle(fontSize: 11.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close alert dialog
              Navigator.pop(context); // Close create page dialog
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close alert dialog
              Navigator.pop(context); // Close create page dialog
              _launchUrl('https://www.facebook.com/pages/create/');
            },
            child: const Text('Create Manually'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid category from the suggestions list')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => isCreating = true);
    try {
      final res = await AuthService.createFacebookPage(
        token: widget.token,
        name: nameController.text.trim(),
        categoryId: categoryId!,
        about: aboutController.text.trim(),
      );

      if (res['success'] == true && mounted) {
        widget.onSuccess();
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully created Facebook page: ${res['pageName']}')),
        );
      } else {
        if (mounted) {
          final errorMsg = res['error'] ?? 'Page creation failed.';
          if (errorMsg.toLowerCase().contains('test users')) {
            _showMetaRestrictionDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating page: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isCreating = false);
      }
    }
  }

  void _selectCategoryBottomSheet() {
    final debouncer = _Debouncer(milliseconds: 300);
    List<dynamic> filtered = List.from(categories);
    bool isSearching = false;
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (scrollContext, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Category',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search business category...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          setSheetState(() {
                            isSearching = true;
                          });
                          debouncer.run(() async {
                            try {
                              final res = await AuthService.fetchFacebookCategories(
                                widget.token,
                                query: val.trim(),
                              );
                              if (res['success'] == true && mounted) {
                                setSheetState(() {
                                  filtered = res['categories'] ?? [];
                                  isSearching = false;
                                });
                              }
                            } catch (_) {
                              if (mounted) {
                                setSheetState(() {
                                  isSearching = false;
                                });
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final cat = filtered[index];
                            final isSelected = categoryId == cat['id']?.toString();
                            return ListTile(
                              title: Text(
                                cat['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : Colors.black87,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              onTap: () {
                                setState(() {
                                  categoryId = cat['id']?.toString();
                                  categorySearchController.text = cat['name'] ?? '';
                                });
                                Navigator.pop(sheetContext);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Facebook Page', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: isLoadingCategories
          ? const SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    SizedBox(height: 10),
                    Text('Loading Facebook categories...', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a new Page directly on your Facebook profile.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    const Text('Page Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: nameController,
                      enabled: !isCreating,
                      decoration: const InputDecoration(
                        hintText: 'e.g. My Gym Center',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: categorySearchController,
                      readOnly: true,
                      enabled: !isCreating,
                      onTap: _selectCategoryBottomSheet,
                      decoration: const InputDecoration(
                        hintText: 'Tap to select category...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                      validator: (val) => categoryId == null ? 'Category is required' : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Description (About)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: aboutController,
                      enabled: !isCreating,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Short description of your page',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (isCreating || isLoadingCategories) ? null : _submit,
          child: isCreating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _Debouncer {
  final int milliseconds;
  Timer? _timer;

  _Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
