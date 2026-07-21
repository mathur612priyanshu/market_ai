import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdSetupScreen extends StatefulWidget {
  const AdSetupScreen({super.key});

  @override
  State<AdSetupScreen> createState() => _AdSetupScreenState();
}

class _AdSetupScreenState extends State<AdSetupScreen> {
  String objective = 'Lead Generation';
  String budget = '₹500 / day';
  String duration = '7 Days';

  Future<void> _runAd() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
        title: const Text('Campaign ready'),
        content: const Text('Your ad configuration has been reviewed. Connect a live ad account and backend before publishing a real campaign.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
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
              child: ScreenHeader(title: 'Ad Setup', subtitle: 'Review and run your ad campaign.'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel('Campaign Name'),
                    const TextField(decoration: InputDecoration(hintText: 'Leads Campaign - May 2024')),
                    const SizedBox(height: 14),
                    const FormLabel('Objective'),
                    DropdownButtonFormField<String>(
                      value: objective,
                      items: ['Lead Generation', 'Website Traffic', 'Brand Awareness', 'Sales']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => setState(() => objective = value ?? objective),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Audience'),
                    const TextField(decoration: InputDecoration(hintText: 'Business Owners, 25-45, India')),
                    const SizedBox(height: 14),
                    const FormLabel('Budget'),
                    DropdownButtonFormField<String>(
                      value: budget,
                      items: ['₹500 / day', '₹1,000 / day', '₹2,500 / day']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => setState(() => budget = value ?? budget),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Duration'),
                    DropdownButtonFormField<String>(
                      value: duration,
                      items: ['7 Days', '14 Days', '30 Days']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => setState(() => duration = value ?? duration),
                    ),
                    const SizedBox(height: 17),
                    const FormLabel('Placements'),
                    const Row(
                      children: [
                        TinyPlatformIcon(type: 'facebook'),
                        SizedBox(width: 12),
                        TinyPlatformIcon(type: 'instagram'),
                        SizedBox(width: 12),
                        TinyPlatformIcon(type: 'google'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(label: 'Review & Run Ad', onPressed: _runAd),
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
