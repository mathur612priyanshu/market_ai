import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SchedulePostScreen extends StatefulWidget {
  const SchedulePostScreen({super.key});

  @override
  State<SchedulePostScreen> createState() => _SchedulePostScreenState();
}

class _SchedulePostScreenState extends State<SchedulePostScreen> {
  String platform = 'Facebook';
  DateTime date = DateTime(2024, 5, 25);
  TimeOfDay time = const TimeOfDay(hour: 10, minute: 30);

  String get dateText {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: time);
    if (picked != null) setState(() => time = picked);
  }

  Future<void> _schedule() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 45),
        title: const Text('Post scheduled'),
        content: Text('Your $platform post is scheduled for $dateText at ${time.format(context)}.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(this.context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Schedule Post', subtitle: 'Choose date and time to publish.'),
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
                    const SizedBox(height: 19),
                    const FormLabel('Date'),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_month_outlined)),
                        child: Text(dateText),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const FormLabel('Time'),
                    InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(suffixIcon: Icon(Icons.schedule_rounded)),
                        child: Text(time.format(context)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const FormLabel('Preview'),
                    const MarketingPostCard(compact: true),
                    const SizedBox(height: 25),
                    PrimaryButton(label: 'Schedule', onPressed: _schedule),
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
