import 'package:flutter/material.dart';
import '../routes.dart';
import '../theme/app_theme.dart';

class MarketAiLogo extends StatelessWidget {
  const MarketAiLogo({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: compact ? 28 : 38,
          height: compact ? 28 : 38,
          child: CustomPaint(
            painter: _LogoPainter(light: light),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 20 : 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
                children: const [
                  TextSpan(text: 'Market'),
                  TextSpan(text: 'AI', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (!compact)
              Text(
                'AI Powered Marketing Growth',
                style: TextStyle(
                  fontSize: 8.8,
                  color: light ? Colors.white70 : AppColors.muted,
                  letterSpacing: 0.1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.light});
  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = light ? Colors.white : AppColors.primary;
    final p2 = Paint()..color = light ? Colors.white70 : AppColors.primaryLight;
    final path1 = Path()
      ..moveTo(size.width * .48, 0)
      ..lineTo(size.width, size.height * .92)
      ..lineTo(size.width * .64, size.height * .92)
      ..lineTo(size.width * .34, size.height * .35)
      ..close();
    final path2 = Path()
      ..moveTo(size.width * .30, size.height * .28)
      ..lineTo(size.width * .54, size.height * .76)
      ..lineTo(0, size.height * .76)
      ..close();
    canvas.drawPath(path1, p1);
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: height,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(.35),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          elevation: 0,
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(.7)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    );
  }
}

class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
          ],
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color = Colors.white,
    this.borderColor = AppColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(color: Color(0x09000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
    return onTap == null
        ? content
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: content,
          );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.centered = true,
    this.showBack = true,
    this.action,
  });

  final String title;
  final String? subtitle;
  final bool centered;
  final bool showBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack)
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            visualDensity: VisualDensity.compact,
          )
        else
          const SizedBox(width: 44),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: centered ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    textAlign: centered ? TextAlign.center : TextAlign.left,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: 44, child: action),
      ],
    );
  }
}

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.currentIndex});
  final int currentIndex;

  void _go(BuildContext context, String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create with AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lavender,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.auto_awesome_rounded),
                ),
                title: const Text('AI Search', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Analyze competitors and marketing strategy'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, AppRoutes.aiSearch);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lavender,
                  foregroundColor: AppColors.primary,
                  child: Icon(Icons.post_add_rounded),
                ),
                title: const Text('AI Post Creator', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Generate social media content'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, AppRoutes.aiPostCreator);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 68,
      elevation: 8,
      shadowColor: Colors.black12,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.lavender,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            _go(context, AppRoutes.dashboard);
            break;
          case 1:
            _go(context, AppRoutes.reports);
            break;
          case 2:
            _showCreateMenu(context);
            break;
          case 3:
            _go(context, AppRoutes.leads);
            break;
          case 4:
            _go(context, AppRoutes.settings);
            break;
        }
      },
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description_rounded), label: 'Reports'),
        NavigationDestination(
          icon: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          label: '',
        ),
        const NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Leads'),
        const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.change,
    this.positive = true,
  });

  final String label;
  final String value;
  final String change;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              Text(
                change,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: positive ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (label.toLowerCase()) {
      case 'new':
        color = AppColors.success;
        bg = const Color(0xFFE8FAF3);
        break;
      case 'contacted':
        color = AppColors.blue;
        bg = const Color(0xFFEAF2FF);
        break;
      case 'converted':
        color = AppColors.primary;
        bg = AppColors.lavender;
        break;
      default:
        color = AppColors.muted;
        bg = const Color(0xFFF2F0F4);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}class MarketingPostCard extends StatelessWidget {
  const MarketingPostCard({super.key, this.compact = false, this.imageUrl});
  final bool compact;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 150.0 : 250.0;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultCard(context, height),
        ),
      );
    }
    return _buildDefaultCard(context, height);
  }

  Widget _buildDefaultCard(BuildContext context, double height) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(
          colors: [Color(0xFF071B36), Color(0xFF0B4D78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -8,
            child: Container(
              width: compact ? 128 : 210,
              height: compact ? 128 : 210,
              decoration: BoxDecoration(
                color: const Color(0xFF0D84B7).withOpacity(.42),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: compact ? 18 : 28,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 72 : 112,
                  height: compact ? 72 : 112,
                  decoration: const BoxDecoration(color: Color(0xFFD8A477), shape: BoxShape.circle),
                  child: Icon(Icons.person_rounded, size: compact ? 61 : 92, color: const Color(0xFF173852)),
                ),
                Container(
                  width: compact ? 100 : 155,
                  height: compact ? 46 : 75,
                  decoration: const BoxDecoration(
                    color: Color(0xFF123B5B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: compact ? 14 : 20,
            top: compact ? 14 : 22,
            right: compact ? 105 : 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow Your\nBusiness with\nDigital Marketing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 16 : 25,
                    fontWeight: FontWeight.w900,
                    height: 1.06,
                  ),
                ),
                SizedBox(height: compact ? 8 : 13),
                Text(
                  'Get more leads. More customers.\nMore growth.',
                  style: TextStyle(color: Colors.white70, fontSize: compact ? 7.7 : 11.5, height: 1.3),
                ),
                SizedBox(height: compact ? 8 : 15),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: compact ? 5 : 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2A51A),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Get Started Today!',
                    style: TextStyle(color: Colors.white, fontSize: compact ? 7.5 : 10.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TinyPlatformIcon extends StatelessWidget {
  const TinyPlatformIcon({super.key, required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    if (type == 'facebook') {
      return const CircleAvatar(
        radius: 12,
        backgroundColor: Color(0xFF1877F2),
        child: Text('f', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      );
    }
    if (type == 'instagram') {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)]),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 15),
      );
    }
    return const CircleAvatar(
      radius: 12,
      backgroundColor: AppColors.primary,
      child: Text('G', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}

void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
