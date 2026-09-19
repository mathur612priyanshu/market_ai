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
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?['name']?.toString() ?? 'User';
    final userPhone = user?['phone']?.toString() ?? '';
    final userEmail = user?['email']?.toString() ?? '';
    final profilePic = user?['profilePicture']?.toString();
    final plan = user?['plan']?.toString() ?? 'Free';

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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  // Profile Overview Header Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          size: 60,
                          imageUrl: profilePic,
                          name: userName,
                          showBorder: true,
                          borderWidth: 2.5,
                          borderColor: Colors.white,
                          backgroundColor: Colors.white24,
                          iconColor: Colors.white,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.profile, arguments: {'isEditMode': true}),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail.isNotEmpty ? userEmail : userPhone,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white30),
                                    ),
                                    child: Text(
                                      '$plan Plan',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => Navigator.pushNamed(context, AppRoutes.profile, arguments: {'isEditMode': true}),
                                    child: const Row(
                                      children: [
                                        Text('Edit', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationColor: Colors.white)),
                                        SizedBox(width: 2),
                                        Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

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
                    icon: Icons.workspace_premium_outlined,
                    label: 'Subscription Plan',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.subscription),
                  ),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.helpSupport),
                  ),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    label: 'Privacy Policy',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notification Preferences',
                    onTap: () => showAppSnackBar(context, 'Notification preferences opened'),
                  ),
                  const SizedBox(height: 13),
                  ListTile(
                    onTap: () async {
                      ref.read(authProvider.notifier).clearSession();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
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
