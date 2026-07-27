import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class GeneratedPostScreen extends StatefulWidget {
  const GeneratedPostScreen({super.key});

  @override
  State<GeneratedPostScreen> createState() => _GeneratedPostScreenState();
}

class _GeneratedPostScreenState extends State<GeneratedPostScreen> {
  late TextEditingController captionController;
  late TextEditingController hashtagsController;
  bool isInitialized = false;
  late String platform;

  late String creativeUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      platform = args['platform'] as String;
      captionController = TextEditingController(text: args['caption'] as String);
      hashtagsController = TextEditingController(text: args['hashtags'] as String);
      creativeUrl = args['creativeUrl'] as String? ?? '';
      isInitialized = true;
    }
  }

  @override
  void dispose() {
    captionController.dispose();
    hashtagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Generated Post', subtitle: "Here's your AI generated post."),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarketingPostCard(imageUrl: creativeUrl),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () {
                            showAppSnackBar(context, 'Post caption copied to clipboard');
                          },
                          icon: const Icon(Icons.share_outlined),
                        ),
                        IconButton(
                          onPressed: () => showAppSnackBar(context, 'You can edit the caption fields directly below'),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => showAppSnackBar(context, 'Mock creative downloaded to device'),
                          icon: const Icon(Icons.download_outlined),
                        ),
                        IconButton(
                          onPressed: () => showAppSnackBar(context, 'More sharing options opened'),
                          icon: const Icon(Icons.more_horiz_rounded),
                        ),
                      ],
                    ),
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
                      label: 'Schedule Post',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.schedulePost,
                          arguments: {
                            'platform': platform,
                            'caption': captionController.text,
                            'hashtags': hashtagsController.text,
                            'creativeUrl': creativeUrl,
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
