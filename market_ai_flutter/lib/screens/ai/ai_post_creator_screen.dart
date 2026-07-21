import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AiPostCreatorScreen extends StatefulWidget {
  const AiPostCreatorScreen({super.key});

  @override
  State<AiPostCreatorScreen> createState() => _AiPostCreatorScreenState();
}

class _AiPostCreatorScreenState extends State<AiPostCreatorScreen> {
  final controller = TextEditingController(text: 'Create a post about digital marketing benefits for business');
  String platform = 'Facebook';
  String type = 'Image Post';
  String tone = 'Professional';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'AI Post Creator', subtitle: 'Describe your post or select a type.'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
                      borderColor: AppColors.primary,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              minLines: 3,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9)),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const FormLabel('Select Platform'),
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
                    const FormLabel('Post Type'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Image Post', 'Carousel', 'Reel']
                          .map(
                            (item) => ChoiceChip(
                              label: Text(item),
                              selected: type == item,
                              onSelected: (_) => setState(() => type = item),
                              showCheckmark: false,
                              selectedColor: AppColors.lavender,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: type == item ? AppColors.primary : AppColors.border),
                              labelStyle: TextStyle(
                                color: type == item ? AppColors.primary : AppColors.muted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    const FormLabel('Tone'),
                    DropdownButtonFormField<String>(
                      value: tone,
                      items: ['Professional', 'Friendly', 'Confident', 'Conversational']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => setState(() => tone = value ?? tone),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Generate Post',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.generatedPost),
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
