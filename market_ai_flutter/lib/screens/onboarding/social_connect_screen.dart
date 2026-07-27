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
