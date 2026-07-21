import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  int selected = 1;

  @override
  Widget build(BuildContext context) {
    final plans = const [
      _Plan('Basic', '₹999', ['1 User', '5 Reports / month', 'Basic Support']),
      _Plan('Pro', '₹1999', ['3 Users', 'Unlimited Reports', 'Priority Support']),
      _Plan('Enterprise', '₹4999', ['10 Users', 'Unlimited Reports', '24/7 Support']),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Subscription Plan', subtitle: 'Choose the best plan for your business.'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 27, 14, 24),
                child: Column(
                  children: [
                    SizedBox(
                      height: 282,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(plans.length, (index) {
                          final plan = plans[index];
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: index == 0 ? 0 : 4, right: index == 2 ? 0 : 4),
                              child: _PlanCard(
                                plan: plan,
                                selected: selected == index,
                                popular: index == 1,
                                onTap: () => setState(() => selected = index),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 29),
                    PrimaryButton(
                      label: 'Upgrade Now',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 45),
                          title: Text('${plans[selected].name} selected'),
                          content: const Text('Payment checkout requires your production payment gateway and backend configuration.'),
                          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
                        ),
                      ),
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

class _Plan {
  const _Plan(this.name, this.price, this.features);
  final String name;
  final String price;
  final List<String> features;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.selected, required this.popular, required this.onTap});
  final _Plan plan;
  final bool selected;
  final bool popular;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 270),
        padding: const EdgeInsets.fromLTRB(9, 12, 9, 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavender : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 25,
              child: popular
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Most Popular', style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800)),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(plan.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(plan.price, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            ),
            const Text('/month', style: TextStyle(color: AppColors.muted, fontSize: 8.5)),
            const SizedBox(height: 18),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text(feature, style: const TextStyle(fontSize: 8.5, height: 1.25))),
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
