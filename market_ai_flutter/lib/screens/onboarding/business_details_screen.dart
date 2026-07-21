import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final services = <String>['Digital Marketing', 'SEO', 'Social Media'];

  Future<void> _addService() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add service'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Service name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) setState(() => services.add(value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Business Information', subtitle: 'Tell us about your business'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel('Business Logo'),
                    InkWell(
                      onTap: () => showAppSnackBar(context, 'Logo picker opened (demo)'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 118,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.ios_share_rounded, color: AppColors.primary, size: 28),
                            SizedBox(height: 7),
                            Text('Upload Logo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                            SizedBox(height: 3),
                            Text('JPG, PNG (Max. 2MB)', style: TextStyle(color: AppColors.muted, fontSize: 10.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const FormLabel('Business Name'),
                    const TextField(decoration: InputDecoration(hintText: 'ABC Digital Solutions')),
                    const SizedBox(height: 14),
                    const FormLabel('Business Address'),
                    const TextField(decoration: InputDecoration(hintText: '123, MG Road, Bangalore, India')),
                    const SizedBox(height: 14),
                    const FormLabel('Website (Optional)'),
                    const TextField(
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(hintText: 'www.abcdigitals.com'),
                    ),
                    const SizedBox(height: 14),
                    const FormLabel('Services Offered'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...services.map(
                          (service) => InputChip(
                            label: Text(service),
                            backgroundColor: AppColors.lavender,
                            labelStyle: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                            side: BorderSide.none,
                            onDeleted: () => setState(() => services.remove(service)),
                            deleteIconColor: AppColors.primary,
                            deleteIcon: const Icon(Icons.close, size: 15),
                          ),
                        ),
                        ActionChip(
                          label: const Text('+ Add More'),
                          onPressed: _addService,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          labelStyle: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 27),
                    PrimaryButton(
                      label: 'Save & Continue',
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false),
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
