import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class GeneratedPostScreen extends StatelessWidget {
  const GeneratedPostScreen({super.key});

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
                    const MarketingPostCard(),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(onPressed: () => showAppSnackBar(context, 'Post copied'), icon: const Icon(Icons.share_outlined)),
                        IconButton(onPressed: () => showAppSnackBar(context, 'Edit mode opened'), icon: const Icon(Icons.edit_outlined)),
                        IconButton(onPressed: () => showAppSnackBar(context, 'Creative downloaded'), icon: const Icon(Icons.download_outlined)),
                        IconButton(onPressed: () => showAppSnackBar(context, 'More options opened'), icon: const Icon(Icons.more_horiz_rounded)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('Post Caption', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    const Text(
                      'Digital marketing helps you reach more customers, build your brand, and grow your business online.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.55),
                    ),
                    const SizedBox(height: 16),
                    const Text('Hashtags', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    const Text(
                      '#DigitalMarketing #BusinessGrowth #Leads #MarketingStrategy',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, height: 1.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 25),
                    PrimaryButton(
                      label: 'Schedule Post',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.schedulePost),
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
