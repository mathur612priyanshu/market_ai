import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SocialConnectScreen extends StatefulWidget {
  const SocialConnectScreen({super.key});

  @override
  State<SocialConnectScreen> createState() => _SocialConnectScreenState();
}

class _SocialConnectScreenState extends State<SocialConnectScreen> {
  bool facebookConnected = false;
  bool instagramConnected = false;

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
                  onPressed: () => setState(() => facebookConnected = !facebookConnected),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: instagramConnected ? 'Instagram Connected' : 'Connect Instagram',
                  icon: instagramConnected ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
                  color: AppColors.instagram,
                  onPressed: () => setState(() => instagramConnected = !instagramConnected),
                ),
              ),
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
