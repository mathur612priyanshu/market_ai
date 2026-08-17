import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../services/auth_service.dart';
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
  bool isLoading = false;
  String? syncWarning;

  List<dynamic> facebookPages = [];
  List<dynamic> forms = [];
  String? selectedPageId;
  String? selectedFormId;
  bool isLoadingPages = true;
  bool isLoadingForms = false;

  @override
  void initState() {
    super.initState();
    _fetchPages();
  }

  Future<void> _fetchPages() async {
    setState(() {
      isLoadingPages = true;
      facebookPages = [];
    });
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;
      
      final res = await AuthService.fetchSocialStatus(token);
      if (res['success'] == true && mounted) {
        final accounts = res['accounts'] as List<dynamic>? ?? [];
        final fbPages = accounts.where((acc) => acc['platform'] == 'facebook').toList();
        setState(() {
          facebookPages = fbPages;
          isLoadingPages = false;
          if (fbPages.isNotEmpty) {
            selectedPageId = fbPages.first['accountId']?.toString();
          }
        });
        if (selectedPageId != null) {
          _fetchForms(selectedPageId!);
        }
      } else {
        setState(() => isLoadingPages = false);
      }
    } catch (e) {
      setState(() => isLoadingPages = false);
    }
  }

  Future<void> _fetchForms(String pageId) async {
    setState(() {
      isLoadingForms = true;
      forms = [];
      selectedFormId = null;
      leads = [];
    });
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;
      
      final res = await AdService.fetchPageForms(token: token, pageId: pageId);
      if (res['success'] == true && mounted) {
        final formsList = res['forms'] as List<dynamic>? ?? [];
        setState(() {
          forms = formsList;
          isLoadingForms = false;
          if (formsList.isNotEmpty) {
            selectedFormId = formsList.first['id']?.toString();
          }
        });
        if (selectedFormId != null) {
          _fetchLeads(selectedFormId!);
        }
      } else {
        setState(() => isLoadingForms = false);
      }
    } catch (e) {
      setState(() => isLoadingForms = false);
    }
  }

  Future<void> _fetchLeads(String formId) async {
    setState(() {
      isLoading = true;
      syncWarning = null;
    });
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;

      final res = await AdService.fetchFormLeads(token: token, formId: formId);
      if (res['success'] == true && mounted) {
        setState(() {
          leads = res['leads'] ?? [];
          syncWarning = res['syncWarning']?.toString();
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
        if (selectedFormId != null) {
          _fetchLeads(selectedFormId!); // Rollback
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error updating status: $e');
        if (selectedFormId != null) {
          _fetchLeads(selectedFormId!);
        }
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
    final fieldData = lead['fieldData'] as List<dynamic>? ?? [];

    final customQuestions = <Map<String, String>>[];
    for (final field in fieldData) {
      final fieldName = field['name']?.toString() ?? '';
      final valuesList = field['values'] as List<dynamic>? ?? [];
      final val = valuesList.isNotEmpty ? valuesList.first.toString() : '';

      final lowerName = fieldName.toLowerCase();
      if (lowerName.contains('name') || lowerName.contains('email') || lowerName.contains('phone')) {
        continue;
      }

      if (fieldName.isNotEmpty && val.isNotEmpty) {
        var humanName = fieldName
            .replaceAll(RegExp(r'^[\d\.\s_]+'), '')
            .replaceAll('_', ' ')
            .trim();
        if (humanName.isNotEmpty) {
          humanName = humanName[0].toUpperCase() + humanName.substring(1);
          customQuestions.add({
            'label': humanName,
            'value': val,
          });
        }
      }
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SingleChildScrollView(
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
                if (customQuestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Custom Survey Responses',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Column(
                        children: customQuestions.map((q) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  '${q['label']}:',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Colors.black87),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  q['value'] ?? '',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
                    onPressed: () {
                      if (selectedFormId != null) {
                        _fetchLeads(selectedFormId!);
                      } else {
                        _fetchPages();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Dropdown Selectors Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (isLoadingPages)
                    const Center(child: LinearProgressIndicator(color: AppColors.primary))
                  else if (facebookPages.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No connected Facebook Pages found. Please connect page in Social Connect.',
                              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      value: selectedPageId,
                      decoration: const InputDecoration(
                        labelText: 'Facebook Page',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      items: facebookPages.map((page) {
                        return DropdownMenuItem<String>(
                          value: page['accountId']?.toString(),
                          child: Text(page['accountName']?.toString() ?? 'Unnamed Page'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedPageId = val;
                          });
                          _fetchForms(val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isLoadingForms)
                      const Center(child: LinearProgressIndicator(color: AppColors.primary))
                    else if (forms.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No active Leadgen Forms found for this page.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedFormId,
                        decoration: const InputDecoration(
                          labelText: 'Lead Form',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: forms.map((form) {
                          return DropdownMenuItem<String>(
                            value: form['id']?.toString(),
                            child: Text(form['name']?.toString() ?? 'Unnamed Form'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedFormId = val;
                            });
                            _fetchLeads(val);
                          }
                        },
                      ),
                  ],
                ],
              ),
            ),
            if (syncWarning != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          syncWarning!,
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
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
                          onRefresh: () => selectedFormId != null ? _fetchLeads(selectedFormId!) : Future.value(),
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
            Text(
              selectedFormId == null 
                ? 'Please select a Facebook Page and Lead Form to view contacts.'
                : 'No contacts submitted through this lead generation form yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
