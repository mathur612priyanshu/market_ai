import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      bottomNavigationBar: const MainBottomNav(currentIndex: 4),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Settings', subtitle: 'Manage your account and preferences.', showBack: false),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile Information',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.profile, arguments: {'isEditMode': true}),
                  ),
                  _SettingsTile(
                    icon: Icons.link_rounded,
                    label: 'Social Accounts',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.socialConnect, arguments: {'isEditMode': true}),
                  ),
                  _SettingsTile(
                    icon: Icons.business_outlined,
                    label: 'Business Information',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.businessDetails, arguments: {'isEditMode': true}),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notification Preferences',
                    onTap: () => showAppSnackBar(context, 'Notification preferences opened'),
                  ),
                  _SettingsTile(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Subscription Plan',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.subscription),
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.helpSupport),
                  ),
                  const SizedBox(height: 13),
                  ListTile(
                    onTap: () async {
                      ref.read(authProvider.notifier).clearSession();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('token');
                      await prefs.remove('user');
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                      }
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: const Color(0xFFFFF3F4),
                    leading: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 21),
                    title: const Text('Logout', style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          leading: Icon(icon, color: AppColors.muted, size: 21),
          title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
