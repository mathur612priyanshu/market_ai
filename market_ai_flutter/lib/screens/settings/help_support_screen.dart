import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(
                title: 'Help & Support',
                subtitle: "We're here 24/7 to support your marketing growth.",
                showBack: true,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  // System Status Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FAF3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Systems Operational',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFF0F5132),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'AI Post Engine, Meta API v20, and Lead Sync are active.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF155724)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Get Quick Assistance',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Support Options Grid/List
                  _SupportActionCard(
                    icon: Icons.quiz_outlined,
                    iconBg: const Color(0xFFEDE9FE),
                    iconColor: AppColors.primary,
                    title: 'Knowledge Base & FAQs',
                    subtitle: 'Find answers to common questions about ads, AI, & leads',
                    badge: '25+ Guides',
                    onTap: () => _openFaqSheet(context),
                  ),

                  const SizedBox(height: 10),

                  _SupportActionCard(
                    icon: Icons.support_agent_rounded,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                    title: 'Live Chat Support',
                    subtitle: 'Chat directly with our AI assistant or support executives',
                    badge: 'Instant',
                    onTap: () => _openChatModal(context),
                  ),

                  const SizedBox(height: 10),

                  _SupportActionCard(
                    icon: Icons.confirmation_number_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    title: 'Raise a Support Ticket',
                    subtitle: 'Submit a ticket for technical issues or account inquiries',
                    onTap: () => _openTicketModal(context),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Direct Contact Channels',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ContactTile(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    value: 'support@marketai.com',
                    actionLabel: 'Copy',
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'support@marketai.com'));
                      showAppSnackBar(context, 'Email address copied to clipboard: support@marketai.com');
                    },
                  ),

                  const SizedBox(height: 10),

                  _ContactTile(
                    icon: Icons.call_outlined,
                    title: 'Helpline & WhatsApp',
                    value: '+91 98765 43210',
                    actionLabel: 'Call / WhatsApp',
                    onTap: () => _showContactOptions(context),
                  ),

                  const SizedBox(height: 10),

                  _ContactTile(
                    icon: Icons.access_time_rounded,
                    title: 'Support Working Hours',
                    value: 'Mon – Sat: 9:00 AM – 8:00 PM IST',
                    actionLabel: '',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Contact Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Connect with our dedicated support executive', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8FAF3),
                  foregroundColor: AppColors.success,
                  child: Icon(Icons.chat_outlined),
                ),
                title: const Text('Chat on WhatsApp', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('+91 98765 43210 (Average reply < 5 mins)'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showAppSnackBar(context, 'Connecting to MarketAI WhatsApp Support...');
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  foregroundColor: Color(0xFF0284C7),
                  child: Icon(Icons.phone_in_talk_rounded),
                ),
                title: const Text('Call Toll-Free Helpline', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Available 9 AM to 8 PM IST'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Clipboard.setData(const ClipboardData(text: '+919876543210'));
                  showAppSnackBar(context, 'Number copied: +91 98765 43210');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFaqSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => const _FaqSheetContent(),
    );
  }

  void _openTicketModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => const _TicketSheetContent(),
    );
  }

  void _openChatModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => const _LiveChatContent(),
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  const _SupportActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
              ],
            ),
          ),
          if (actionLabel.isNotEmpty)
            InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------- FAQ Bottom Sheet -----------------
class _FaqSheetContent extends StatefulWidget {
  const _FaqSheetContent();

  @override
  State<_FaqSheetContent> createState() => _FaqSheetContentState();
}

class _FaqSheetContentState extends State<_FaqSheetContent> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'All',
    'Account & Meta',
    'AI Marketing',
    'Ads & ROI',
    'Leads & CRM',
  ];

  final List<Map<String, String>> _allFaqs = [
    {
      'cat': 'Account & Meta',
      'q': 'How do I connect my Facebook Pages & Instagram?',
      'a': 'Go to Settings > Social Accounts, tap "Connect with Facebook", and grant page management permissions. All your verified pages and ad accounts will sync automatically.'
    },
    {
      'cat': 'Account & Meta',
      'q': 'How can I change my profile photo or business name?',
      'a': 'Go to Settings > Profile Information to update your picture and basic info, or Settings > Business Information to manage your business services and logo.'
    },
    {
      'cat': 'AI Marketing',
      'q': 'How does the AI Post Creator work?',
      'a': 'Select your industry or topic, choose tone & platform (Facebook, Instagram, LinkedIn), and MarketAI generates customized captions, creatives, and hashtags tailored for your target audience.'
    },
    {
      'cat': 'AI Marketing',
      'q': 'Can I schedule posts for automatic publishing?',
      'a': 'Yes! When creating a post, select "Schedule Post", pick your desired date and time, and our background scheduler will publish it directly to your page.'
    },
    {
      'cat': 'Ads & ROI',
      'q': 'Why does Ad Performance Report show Lifetime metrics?',
      'a': 'If you have not run active ads in the last 30 calendar days, MarketAI automatically pulls your lifetime delivery data so you can always review complete historic spend, clicks, and CTR.'
    },
    {
      'cat': 'Ads & ROI',
      'q': 'How is Cost Per Lead (CPL) calculated in ROI Tracker?',
      'a': 'CPL is calculated by dividing your total tracked Meta Ad Spend by the total validated lead form submissions generated during that period.'
    },
    {
      'cat': 'Leads & CRM',
      'q': 'How do Meta LeadGen forms sync with MarketAI?',
      'a': 'MarketAI connects directly to Meta Graph API webhook and form endpoints. Whenever a user submits a lead form on Facebook or Instagram, it appears instantly in your Leads tab.'
    },
    {
      'cat': 'Leads & CRM',
      'q': 'Can I export reports and lead lists as PDF or CSV?',
      'a': 'Yes! Open any report in the Reports tab and tap "Export PDF" or "Export CSV" to download clean formatted spreadsheets and presentation-ready summaries.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _allFaqs.where((faq) {
      final matchesCat = _selectedCategoryIndex == 0 || faq['cat'] == _categories[_selectedCategoryIndex];
      final matchesSearch = _searchQuery.isEmpty ||
          faq['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['a']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_categories.length, (index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_categories[index]),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategoryIndex = index);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.text,
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredFaqs.isEmpty
                ? const Center(
                    child: Text('No FAQs found matching your search.', style: TextStyle(color: AppColors.muted)),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredFaqs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredFaqs[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            title: Text(
                              item['q']!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            children: [
                              Text(
                                item['a']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Ticket Submission Modal -----------------
class _TicketSheetContent extends StatefulWidget {
  const _TicketSheetContent();

  @override
  State<_TicketSheetContent> createState() => _TicketSheetContentState();
}

class _TicketSheetContentState extends State<_TicketSheetContent> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Technical Issue';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Technical Issue',
    'Meta Account Connection',
    'Ad Campaign & ROI',
    'Lead Sync Inquiries',
    'Billing & Subscriptions',
    'Feature Request',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_subjectController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please enter a ticket subject');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please describe your issue');
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final ticketId = '#MKT-${(10000 + (DateTime.now().millisecondsSinceEpoch % 90000))}';
      Navigator.pop(context);

      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
          title: const Text('Support Ticket Created', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your ticket $ticketId has been logged successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our technical team will review and reply within 2 business hours.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: ticketId));
                Navigator.pop(ctx);
                showAppSnackBar(context, 'Ticket ID copied: $ticketId');
              },
              child: const Text('Copy Ticket ID'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Raise a Support Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Submit your issue and our technical team will resolve it quickly.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const FormLabel('Issue Category', required: true),
            DropdownButtonFormField<String>(
              value: _category,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _category = val ?? _category),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            ),
            const SizedBox(height: 14),
            const FormLabel('Subject', required: true),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(hintText: 'e.g. Meta Page disconnection error'),
            ),
            const SizedBox(height: 14),
            const FormLabel('Detailed Description', required: true),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Provide complete details about what happened...',
              ),
            ),
            const SizedBox(height: 20),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    label: 'Submit Ticket',
                    icon: Icons.send_rounded,
                    onPressed: _submitTicket,
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ----------------- Live Chat Support Modal -----------------
class _LiveChatContent extends StatefulWidget {
  const _LiveChatContent();

  @override
  State<_LiveChatContent> createState() => _LiveChatContentState();
}

class _LiveChatContentState extends State<_LiveChatContent> {
  final _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'text': 'Hello! 👋 I am your MarketAI Assistant. How can I help boost your business today?',
      'time': 'Just now',
    },
  ];

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _msgController.clear();

    setState(() {
      _messages.add({
        'isBot': false,
        'text': text.trim(),
        'time': 'Now',
      });
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      String reply = 'Thank you for reaching out! Our team has noted your question regarding "$text" and will assist you right away. You can also raise a ticket for expedited debugging.';
      if (text.toLowerCase().contains('meta') || text.toLowerCase().contains('facebook')) {
        reply = 'For Meta connections, make sure your page has admin access and your token is renewed in Social Accounts settings.';
      } else if (text.toLowerCase().contains('lead') || text.toLowerCase().contains('form')) {
        reply = 'LeadGen forms sync automatically from Meta Graph API. Check your Leads tab to view or export recent inquiries.';
      } else if (text.toLowerCase().contains('ad') || text.toLowerCase().contains('spend') || text.toLowerCase().contains('roi')) {
        reply = 'Ad metrics are fetched directly from Meta Insights. Lifetime delivery history is available in the ROI Tracker and Reports tab.';
      }

      setState(() {
        _messages.add({
          'isBot': true,
          'text': reply,
          'time': 'Just now',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.lavender,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MarketAI Support Chat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('Online • Replies within minutes', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isBot = msg['isBot'] as bool;
                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isBot ? const Color(0xFFF1F5F9) : AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: isBot ? const Radius.circular(2) : const Radius.circular(14),
                        bottomRight: isBot ? const Radius.circular(14) : const Radius.circular(2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] as String,
                          style: TextStyle(
                            color: isBot ? AppColors.text : Colors.white,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'] as String,
                          style: TextStyle(
                            color: isBot ? AppColors.muted : Colors.white70,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Quick prompt suggestions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _buildQuickReply('Sync Meta Leads'),
                _buildQuickReply('Check Ad Spend'),
                _buildQuickReply('AI Post Ideas'),
                _buildQuickReply('Talk to Human'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              left: 14,
              right: 14,
              top: 6,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                    onPressed: () => _sendMessage(_msgController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReply(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text),
        onPressed: () => _sendMessage(text),
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
