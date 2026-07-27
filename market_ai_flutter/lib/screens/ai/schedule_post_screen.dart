import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SchedulePostScreen extends ConsumerStatefulWidget {
  const SchedulePostScreen({super.key});

  @override
  ConsumerState<SchedulePostScreen> createState() => _SchedulePostScreenState();
}

class _SchedulePostScreenState extends ConsumerState<SchedulePostScreen> {
  String platform = 'Facebook';
  DateTime date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay time = const TimeOfDay(hour: 12, minute: 00);
  bool publishImmediately = true;
  bool isSubmitting = false;

  late String caption;
  late String hashtags;
  late String creativeUrl;
  bool isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      platform = args['platform'] as String;
      caption = args['caption'] as String;
      hashtags = args['hashtags'] as String;
      creativeUrl = args['creativeUrl'] as String? ?? '';
      isInitialized = true;
    }
  }

  String get dateText {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: time);
    if (picked != null) setState(() => time = picked);
  }

  Future<void> _submitPost() async {
    final session = ref.read(authProvider);
    final token = session.token;
    if (token == null) {
      showAppSnackBar(context, 'Authentication session expired. Please login again.');
      return;
    }

    setState(() => isSubmitting = true);
    try {
      String? scheduledTime;
      if (!publishImmediately) {
        final now = DateTime.now();
        final scheduledDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        if (scheduledDateTime.isBefore(now)) {
          showAppSnackBar(context, 'Scheduled date and time must be in the future.');
          setState(() => isSubmitting = false);
          return;
        }
        scheduledTime = scheduledDateTime.toIso8601String();
      }

      final res = await PostService.scheduleOrPublishPost(
        token: token,
        platform: platform,
        caption: caption,
        hashtags: hashtags,
        mediaUrl: creativeUrl.isNotEmpty ? creativeUrl : null,
        scheduledTime: scheduledTime,
      );

      if (res['success'] == true) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              icon: Icon(
                publishImmediately ? Icons.check_circle_rounded : Icons.schedule_rounded,
                color: AppColors.success,
                size: 45,
              ),
              title: Text(publishImmediately ? 'Post Published' : 'Post Scheduled'),
              content: Text(publishImmediately
                  ? 'Your post has been successfully published to your connected $platform feed!'
                  : 'Your post is scheduled to go live on $dateText at ${time.format(context)}.'),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.of(this.context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, res['error'] ?? 'Operation failed');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error communicating with server: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Publish / Schedule', subtitle: 'Choose date and time to publish.'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 21, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel('Platform'),
                    Row(
                      children: [
                        Expanded(
                          child: _SelectOption(
                            label: 'Facebook',
                            selected: platform == 'Facebook',
                            icon: const TinyPlatformIcon(type: 'facebook'),
                            onTap: () => setState(() => platform = 'Facebook'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SelectOption(
                            label: 'Instagram',
                            selected: platform == 'Instagram',
                            icon: const TinyPlatformIcon(type: 'instagram'),
                            onTap: () => setState(() => platform = 'Instagram'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const FormLabel('Publishing Schedule'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Publish Immediately', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Post this item to feed right now', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      value: publishImmediately,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => publishImmediately = val),
                    ),
                    if (!publishImmediately) ...[
                      const SizedBox(height: 12),
                      const FormLabel('Schedule Date'),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_month_outlined)),
                          child: Text(dateText),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const FormLabel('Schedule Time'),
                      InkWell(
                        onTap: _pickTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(suffixIcon: Icon(Icons.schedule_rounded)),
                          child: Text(time.format(context)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const FormLabel('Preview Card'),
                    MarketingPostCard(compact: true, imageUrl: creativeUrl),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: isSubmitting
                          ? 'Processing...'
                          : (publishImmediately ? 'Publish Now' : 'Schedule Post'),
                      onPressed: isSubmitting ? () {} : _submitPost,
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

class _SelectOption extends StatelessWidget {
  const _SelectOption({required this.label, required this.selected, required this.icon, required this.onTap});
  final String label;
  final bool selected;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavender : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: selected ? AppColors.primary : AppColors.text, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
