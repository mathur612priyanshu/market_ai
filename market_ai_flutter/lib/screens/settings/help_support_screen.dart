import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Help & Support', subtitle: "We're here to help you."),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                children: [
                  _SupportTile(
                    icon: Icons.help_outline_rounded,
                    title: 'FAQs',
                    onTap: () => _showFaqs(context),
                  ),
                  _SupportTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat with Support',
                    onTap: () => showAppSnackBar(context, 'Support chat opened in demo mode'),
                  ),
                  _SupportTile(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'support@marketai.com',
                    onTap: () => showAppSnackBar(context, 'Email composer opened for support@marketai.com'),
                  ),
                  _SupportTile(
                    icon: Icons.call_outlined,
                    title: 'Call Support',
                    subtitle: '+91 98765 43210',
                    onTap: () => showAppSnackBar(context, 'Phone dialer opened for +91 98765 43210'),
                  ),
                  _SupportTile(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Video Tutorials',
                    onTap: () => showAppSnackBar(context, 'Video tutorials opened'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFaqs(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Frequently Asked Questions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              ExpansionTile(
                title: Text('How does competitor analysis work?'),
                children: [Padding(padding: EdgeInsets.all(16), child: Text('MarketAI summarizes competitor data supplied by your configured data sources and APIs.'))],
              ),
              ExpansionTile(
                title: Text('Can I publish ads directly?'),
                children: [Padding(padding: EdgeInsets.all(16), child: Text('Yes after connecting production Meta or Google ad APIs, authentication, and a backend.'))],
              ),
              ExpansionTile(
                title: Text('Where are reports stored?'),
                children: [Padding(padding: EdgeInsets.all(16), child: Text('This UI demo uses local sample data. A production build needs database and cloud storage integration.'))],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.icon, required this.title, this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          leading: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
