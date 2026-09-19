import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class ProfileInformationScreen extends ConsumerStatefulWidget {
  const ProfileInformationScreen({super.key});

  @override
  ConsumerState<ProfileInformationScreen> createState() => _ProfileInformationScreenState();
}

class _ProfileInformationScreenState extends ConsumerState<ProfileInformationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String industry = 'Digital Marketing';
  String country = 'India';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preload user data from Riverpod provider if it exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        if (user['name'] != null) _nameController.text = user['name'];
        if (user['email'] != null) _emailController.text = user['email'];
        if (user['industry'] != null && user['industry'].toString().isNotEmpty) {
          setState(() {
            industry = user['industry'];
          });
        }
        if (user['country'] != null && user['country'].toString().isNotEmpty) {
          setState(() {
            country = user['country'];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lavender,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.photo_library_rounded),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Select an existing photo from device'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lavender,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.camera_alt_rounded),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Capture new photo with camera'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = ref.read(authProvider).token;
      final data = await AuthService.uploadAvatar(
        token: token ?? '',
        imagePath: image.path,
      );

      if (data['success'] == true) {
        // Update user state in Riverpod
        ref.read(authProvider.notifier).updateUser(data['user']);
        
        // Persist updated user details locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));

        if (mounted) {
          showAppSnackBar(context, 'Profile picture updated successfully!');
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, data['message'] ?? 'Image upload failed');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error uploading image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppSnackBar(context, 'Name is required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = ref.read(authProvider).token;
      final data = await AuthService.updateProfile(
        token: token ?? '',
        name: name,
        email: _emailController.text.trim(),
        industry: industry,
        country: country,
      );

      if (data['success'] == true) {
        // Update state in Riverpod
        ref.read(authProvider.notifier).updateUser(data['user']);
        
        // Persist updated user details locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['user']));
        
        if (mounted) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final isEditMode = args?['isEditMode'] == true;
          if (isEditMode) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.socialConnect);
          }
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, data['message'] ?? 'Failed to update profile');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Connection error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final profilePic = user?['profilePicture'];

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final isEditMode = args?['isEditMode'] == true;

    return PopScope(
      canPop: isEditMode,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    if (isEditMode)
                      Positioned(
                        left: 8,
                        top: 6,
                        child: IconButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
                        ),
                      ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: const Offset(0, 44),
                      child: UserAvatar(
                        size: 104,
                        imageUrl: profilePic,
                        name: _nameController.text.isNotEmpty ? _nameController.text : 'User',
                        showBorder: true,
                        borderWidth: 4,
                        borderColor: Colors.white,
                        backgroundColor: AppColors.lavenderStrong,
                        iconColor: Colors.white,
                        onTap: _isLoading ? null : _showImagePickerOptions,
                        badge: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                child: Column(
                  children: [
                    const Text('Complete your profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    const Text('Add basic information to get started', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    const SizedBox(height: 24),
                    const Align(alignment: Alignment.centerLeft, child: FormLabel('Full Name')),
                    TextField(
                      controller: _nameController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(hintText: 'John Doe'),
                    ),
                    const SizedBox(height: 15),
                    const Align(alignment: Alignment.centerLeft, child: FormLabel('Email (Optional)')),
                    TextField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'johndoe@gmail.com'),
                    ),
                    const SizedBox(height: 15),
                    const Align(alignment: Alignment.centerLeft, child: FormLabel('Industry')),
                    DropdownButtonFormField<String>(
                      value: industry,
                      items: ['Digital Marketing', 'E-commerce', 'Real Estate', 'Technology']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: _isLoading ? null : (value) => setState(() => industry = value ?? industry),
                    ),
                    const SizedBox(height: 15),
                    const Align(alignment: Alignment.centerLeft, child: FormLabel('Country')),
                    DropdownButtonFormField<String>(
                      value: country,
                      items: ['India', 'United Arab Emirates', 'United States', 'United Kingdom']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: _isLoading ? null : (value) => setState(() => country = value ?? country),
                    ),
                    const SizedBox(height: 25),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : PrimaryButton(
                            label: 'Save & Continue',
                            onPressed: _saveProfile,
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
