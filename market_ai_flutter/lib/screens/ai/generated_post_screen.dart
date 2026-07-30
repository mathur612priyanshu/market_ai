import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class GeneratedPostScreen extends ConsumerStatefulWidget {
  const GeneratedPostScreen({super.key});

  @override
  ConsumerState<GeneratedPostScreen> createState() => _GeneratedPostScreenState();
}

class _GeneratedPostScreenState extends ConsumerState<GeneratedPostScreen> {
  late TextEditingController captionController;
  late TextEditingController hashtagsController;
  bool isInitialized = false;
  late String platform;
  List<Map<String, dynamic>> mediaList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      platform = args['platform'] as String;
      captionController = TextEditingController(text: args['caption'] as String);
      hashtagsController = TextEditingController(text: args['hashtags'] as String);
      
      final initialCreativeUrl = args['creativeUrl'] as String? ?? '';
      if (initialCreativeUrl.isNotEmpty) {
        mediaList.add({
          'url': initialCreativeUrl,
          'type': 'image',
          'isUploading': false,
        });
      }
      isInitialized = true;
    }
  }

  @override
  void dispose() {
    captionController.dispose();
    hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _uploadFile(String filePath, Map<String, dynamic> item) async {
    final session = ref.read(authProvider);
    final token = session.token;
    if (token == null) return;
    
    try {
      final res = await PostService.uploadPostMedia(token: token, filePath: filePath);
      if (res['success'] == true && mounted) {
        setState(() {
          item['url'] = res['url'];
          item['isUploading'] = false;
        });
      } else {
        if (mounted) {
          setState(() {
            mediaList.remove(item);
          });
          showAppSnackBar(context, res['error'] ?? 'Upload failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          mediaList.remove(item);
        });
        showAppSnackBar(context, 'Upload error: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;

    final tempItem = {
      'localPath': image.path,
      'isUploading': true,
      'type': 'image',
    };

    setState(() {
      mediaList.add(tempItem);
    });

    await _uploadFile(image.path, tempItem);
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    final tempItem = {
      'localPath': video.path,
      'isUploading': true,
      'type': 'video',
    };

    setState(() {
      mediaList.add(tempItem);
    });

    await _uploadFile(video.path, tempItem);
  }

  Future<void> _pickMultiImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;

    for (final image in images) {
      final tempItem = {
        'localPath': image.path,
        'isUploading': true,
        'type': 'image',
      };

      setState(() {
        mediaList.add(tempItem);
      });

      _uploadFile(image.path, tempItem); // Run parallel uploads
    }
  }

  void _showAddMediaOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Add Media to Post', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Add Image', style: TextStyle(fontSize: 13.5)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.collections_outlined, color: AppColors.primary),
                title: const Text('Add Multiple Images (Carousel)', style: TextStyle(fontSize: 13.5)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickMultiImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_collection_outlined, color: AppColors.primary),
                title: const Text('Add Video (Reel)', style: TextStyle(fontSize: 13.5)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool anyUploading = mediaList.any((item) => item['isUploading'] == true);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Compose Post', subtitle: 'Edit caption and manage post media.'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Horizontal Scroll View of Post Media
                    const Text('Post Media', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: mediaList.length + 1,
                        itemBuilder: (context, index) {
                          if (index == mediaList.length) {
                            return GestureDetector(
                              onTap: _showAddMediaOptions,
                              child: Container(
                                width: 140,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                                    const SizedBox(height: 8),
                                    Text('Add Media', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final item = mediaList[index];
                          final bool isUploading = item['isUploading'] == true;
                          final bool isVideo = item['type'] == 'video';

                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (item['url'] != null)
                                  Image.network(item['url'] as String, fit: BoxFit.cover)
                                else if (item['localPath'] != null)
                                  Image.file(File(item['localPath'] as String), fit: BoxFit.cover),
                                if (isVideo && !isUploading)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                    ),
                                  ),
                                if (isUploading)
                                  Container(
                                    color: Colors.black38,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                  ),
                                if (!isUploading)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          mediaList.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Post Caption', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    TextField(
                      controller: captionController,
                      maxLines: 5,
                      minLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Edit your generated caption...',
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Hashtags', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    TextField(
                      controller: hashtagsController,
                      maxLines: 2,
                      minLines: 1,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Add hashtags...',
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 25),
                    PrimaryButton(
                      label: anyUploading ? 'Uploading Media...' : 'Schedule Post',
                      onPressed: anyUploading
                          ? () => showAppSnackBar(context, 'Please wait for all media to finish uploading.')
                          : () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.schedulePost,
                                arguments: {
                                  'platform': platform,
                                  'caption': captionController.text,
                                  'hashtags': hashtagsController.text,
                                  'mediaList': mediaList,
                                },
                              );
                            },
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
