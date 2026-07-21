import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LeadsManagerScreen extends StatefulWidget {
  const LeadsManagerScreen({super.key});

  @override
  State<LeadsManagerScreen> createState() => _LeadsManagerScreenState();
}

class _LeadsManagerScreenState extends State<LeadsManagerScreen> {
  int tab = 0;

  final leads = const [
    _Lead('Rahul Sharma', 'rahul@gmail.com', 'May 24, 2024', 'New', 'RS'),
    _Lead('Sneha Patel', 'sneha@gmail.com', 'May 23, 2024', 'Contacted', 'SP'),
    _Lead('Amit Verma', 'amit@gmail.com', 'May 23, 2024', 'Converted', 'AV'),
    _Lead('Priya Singh', 'priya@gmail.com', 'May 22, 2024', 'New', 'PS'),
    _Lead('Karan Mehta', 'karan@gmail.com', 'May 21, 2024', 'Contacted', 'KM'),
  ];

  List<_Lead> get filtered {
    if (tab == 0) return leads;
    final status = ['New', 'Contacted', 'Converted'][tab - 1];
    return leads.where((lead) => lead.status == status).toList();
  }

  void _showLead(_Lead lead) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.lavender,
                child: Text(lead.initials, style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              Text(lead.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(lead.email, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 14),
              StatusChip(label: lead.status),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      onPressed: () {
                        Navigator.pop(context);
                        showAppSnackBar(this.context, 'Email action opened for ${lead.name}');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Call',
                      icon: Icons.call_outlined,
                      onPressed: () {
                        Navigator.pop(context);
                        showAppSnackBar(this.context, 'Call action opened for ${lead.name}');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['All Leads', 'New', 'Contacted', 'Converted'];
    return Scaffold(
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(title: 'Leads', subtitle: 'Manage your leads and inquiries.'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ChoiceChip(
                  label: Text(tabs[index]),
                  selected: tab == index,
                  showCheckmark: false,
                  selectedColor: AppColors.lavender,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: tab == index ? AppColors.primary : AppColors.border),
                  labelStyle: TextStyle(
                    color: tab == index ? AppColors.primary : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                  onSelected: (_) => setState(() => tab = index),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lead = filtered[index];
                  return ListTile(
                    onTap: () => _showLead(lead),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: CircleAvatar(
                      radius: 23,
                      backgroundColor: const Color(0xFFF2E4D9),
                      child: Text(lead.initials, style: const TextStyle(color: Color(0xFF71482E), fontWeight: FontWeight.w800)),
                    ),
                    title: Text(lead.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(lead.email, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                        Text(lead.date, style: const TextStyle(fontSize: 10, color: Color(0xFFAAA5B0))),
                      ],
                    ),
                    trailing: StatusChip(label: lead.status),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lead {
  const _Lead(this.name, this.email, this.date, this.status, this.initials);
  final String name;
  final String email;
  final String date;
  final String status;
  final String initials;
}
