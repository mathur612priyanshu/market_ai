import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../routes.dart';

class CreateAdScreen extends ConsumerStatefulWidget {
  const CreateAdScreen({super.key});

  @override
  ConsumerState<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends ConsumerState<CreateAdScreen> {
  final adNameController = TextEditingController();
  final headlineController = TextEditingController();
  final primaryTextController = TextEditingController();
  final creativeUrlController = TextEditingController();

  bool isSubmitting = false;
  bool isUploadingImage = false;

  // Passed parameters
  String? adsetId;
  String? adAccountId;
  String? campaignName;

  @override
  void dispose() {
    adNameController.dispose();
    headlineController.dispose();
    primaryTextController.dispose();
    creativeUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;

    setState(() {
      isUploadingImage = true;
    });

    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      final res = await PostService.uploadPostMedia(token: token, filePath: image.path);
      if (res['success'] == true && mounted) {
        setState(() {
          creativeUrlController.text = res['url'] ?? '';
          isUploadingImage = false;
        });
        showAppSnackBar(context, 'Image uploaded successfully!');
      } else {
        if (mounted) {
          setState(() {
            isUploadingImage = false;
          });
          showAppSnackBar(context, res['error'] ?? 'Upload failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
        });
        showAppSnackBar(context, 'Upload error: $e');
      }
    }
  }

  Future<void> _publishAd() async {
    final name = adNameController.text.trim();
    final headline = headlineController.text.trim();
    final primaryText = primaryTextController.text.trim();
    final creativeUrl = creativeUrlController.text.trim();

    if (name.isEmpty) {
      showAppSnackBar(context, 'Please enter an Ad Name');
      return;
    }
    if (headline.isEmpty) {
      showAppSnackBar(context, 'Please enter the Headline');
      return;
    }
    if (primaryText.isEmpty) {
      showAppSnackBar(context, 'Please enter the Primary Text');
      return;
    }
    if (creativeUrl.isEmpty) {
      showAppSnackBar(context, 'Please enter the Creative Image URL');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final res = await AdService.createAdOnly(
        token: token,
        adAccountId: adAccountId!,
        adsetId: adsetId!,
        adName: name,
        headline: headline,
        primaryText: primaryText,
        creativeUrl: creativeUrl,
      );

      if (res['success'] == true && mounted) {
        // Show success alert dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Text('Campaign Published'),
                ],
              ),
              content: const Text(
                'Your Meta Ad Campaign has been successfully configured and sent to Meta in PAUSED status. You can activate it inside the Campaign Management tab.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              actions: [
                TextButton(
                  child: const Text('Go to Campaigns', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // Navigate to campaign management screen, clearing history
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.campaignManagement,
                      ModalRoute.withName(AppRoutes.dashboard),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Failed to publish Ad');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error publishing Ad: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      adsetId = args['adsetId'];
      adAccountId = args['adAccountId'];
      campaignName = args['campaignName'];

      if (adNameController.text.isEmpty && campaignName != null) {
        adNameController.text = '$campaignName Ad';
      }
    }

    if (adsetId == null || adAccountId == null) {
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
                      title: 'Create Ad Creative',
                      subtitle: 'Step 3: Design copy and media visual spec',
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
                    // Ad Name
                    const FormLabel('Ad Name'),
                    TextField(
                      controller: adNameController,
                      decoration: const InputDecoration(hintText: 'Enter Ad Name'),
                    ),
                    const SizedBox(height: 14),

                    // Headline
                    const FormLabel('Headline'),
                    TextField(
                      controller: headlineController,
                      decoration: const InputDecoration(hintText: 'Enter a catchy headline (e.g. 50% Off Today!)'),
                    ),
                    const SizedBox(height: 14),

                    // Primary Text
                    const FormLabel('Primary Text'),
                    TextField(
                      controller: primaryTextController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Enter primary copy description for post...'),
                    ),
                    const SizedBox(height: 14),

                    // Media URL
                    const FormLabel('Creative Media Image URL'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: creativeUrlController,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: const InputDecoration(
                              hintText: 'Paste an Unsplash or static image URL',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lavender,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: isUploadingImage ? null : _pickAndUploadImage,
                            icon: isUploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  )
                                : const Icon(Icons.upload_file_rounded, size: 18),
                            label: Text(
                              isUploadingImage ? 'Uploading...' : 'Upload File',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'If empty, a default placeholder marketing image will be used.',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
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
                        onPressed: isSubmitting ? null : _publishAd,
                        child: isSubmitting
                            ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            : const Text('Publish & Launch Ad', style: TextStyle(fontWeight: FontWeight.bold)),
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
