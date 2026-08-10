import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LeadsManagerScreen extends ConsumerStatefulWidget {
  const LeadsManagerScreen({super.key});

  @override
  ConsumerState<LeadsManagerScreen> createState() => _LeadsManagerScreenState();
}

class _LeadsManagerScreenState extends ConsumerState<LeadsManagerScreen> {
  int tab = 0;
  List<dynamic> leads = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() => isLoading = true);
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final res = await AdService.fetchLeads(token: token);
      if (res['success'] == true && mounted) {
        setState(() {
          leads = res['leads'] ?? [];
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          showAppSnackBar(context, res['error'] ?? 'Failed to load leads.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showAppSnackBar(context, 'Error loading leads: $e');
      }
    }
  }

  Future<void> _updateLeadStatus(String leadId, String newStatus) async {
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      // Optimistic UI update
      setState(() {
        final idx = leads.indexWhere((l) => l['id'] == leadId);
        if (idx != -1) {
          leads[idx]['status'] = newStatus;
        }
      });

      final res = await AdService.updateLeadStatus(
        token: token,
        leadId: leadId,
        status: newStatus,
      );

      if (res['success'] != true && mounted) {
        showAppSnackBar(context, res['error'] ?? 'Failed to update status.');
        _fetchLeads(); // Rollback
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error updating status: $e');
        _fetchLeads();
      }
    }
  }

  List<dynamic> get filtered {
    if (tab == 0) return leads;
    final statusFilter = ['New', 'Contacted', 'Converted'][tab - 1];
    return leads.where((l) => l['status'] == statusFilter).toList();
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '??';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        showAppSnackBar(context, 'Could not open email application.');
      }
    }
  }

  Future<void> _launchCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        showAppSnackBar(context, 'Could not open dialer.');
      }
    }
  }

  void _showLead(dynamic lead) {
    final leadId = lead['id']?.toString() ?? '';
    final name = lead['name']?.toString() ?? 'Unnamed Contact';
    final email = lead['email']?.toString() ?? 'N/A';
    final phone = lead['phone']?.toString() ?? 'N/A';
    String statusValue = lead['status']?.toString() ?? 'New';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.lavender,
                  child: Text(
                    _getInitials(name),
                    style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: AppColors.muted)),
                if (phone != 'N/A') ...[
                  const SizedBox(height: 2),
                  Text(phone, style: const TextStyle(color: AppColors.muted)),
                ],
                const SizedBox(height: 16),
                
                // Status selection row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: statusValue,
                      items: const [
                        DropdownMenuItem(value: 'New', child: Text('New')),
                        DropdownMenuItem(value: 'Contacted', child: Text('Contacted')),
                        DropdownMenuItem(value: 'Converted', child: Text('Converted')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            statusValue = val;
                          });
                          _updateLeadStatus(leadId, val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (email != 'N/A')
                      Expanded(
                        child: SecondaryButton(
                          label: 'Email',
                          icon: Icons.email_outlined,
                          onPressed: () {
                            Navigator.pop(context);
                            _launchEmail(email);
                          },
                        ),
                      ),
                    if (email != 'N/A' && phone != 'N/A') const SizedBox(width: 10),
                    if (phone != 'N/A')
                      Expanded(
                        child: SecondaryButton(
                          label: 'Call',
                          icon: Icons.call_outlined,
                          onPressed: () {
                            Navigator.pop(context);
                            _launchCall(phone);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: ScreenHeader(title: 'Leads', subtitle: 'Manage your leads and inquiries.'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                    onPressed: _fetchLeads,
                  ),
                ],
              ),
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchLeads,
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final lead = filtered[index];
                              final name = lead['name']?.toString() ?? 'Unnamed Contact';
                              final email = lead['email']?.toString() ?? 'N/A';
                              final dateStr = lead['submittedAt']?.toString() ?? '';
                              final status = lead['status']?.toString() ?? 'New';

                              return ListTile(
                                onTap: () => _showLead(lead),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                leading: CircleAvatar(
                                  radius: 23,
                                  backgroundColor: const Color(0xFFF2E4D9),
                                  child: Text(
                                    _getInitials(name),
                                    style: const TextStyle(color: Color(0xFF71482E), fontWeight: FontWeight.w800),
                                  ),
                                ),
                                title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(email, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                                    if (dateStr.isNotEmpty)
                                      Text(_formatDate(dateStr), style: const TextStyle(fontSize: 10, color: Color(0xFFAAA5B0))),
                                  ],
                                ),
                                trailing: StatusChip(label: status),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.lavender,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Leads Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ensure a Facebook Page is connected in Social Connect, and active Lead Generation forms are setup on your Page.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
