import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                title: 'Privacy Policy',
                subtitle: 'How we protect and manage your data',
                showBack: true,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Top Highlight Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.08), AppColors.lavender],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Your Privacy Matters to Us',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'MarketAI by Trusting Brains is built with enterprise security, strict Meta Platform compliance, and data privacy safeguards.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Last Updated: September 2026 • Version 1.2',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSection(
                    icon: Icons.info_outline_rounded,
                    title: '1. Introduction & Overview',
                    content:
                        'MarketAI ("we", "our", or "us"), operated by Trusting Brains, provides AI-driven marketing automation, competitor intelligence, social media publishing, and Meta ad campaign management. This Privacy Policy outlines our practices regarding collection, usage, storage, and protection of your personal and business information.',
                  ),

                  _buildSection(
                    icon: Icons.person_outline_rounded,
                    title: '2. Information We Collect',
                    content:
                        '• Account Information: Phone number, full name, email address, country, and profile image.\n'
                        '• Business Details: Business name, industry, website, address, and marketing services.\n'
                        '• Social & Ad Accounts: Meta/Facebook Pages, Instagram accounts, Ad Account IDs, campaign metrics, and access tokens.\n'
                        '• Customer Leads: Lead form submissions generated via your authorized Meta LeadGen campaigns.\n'
                        '• Generated Content: AI marketing prompts, schedules, captions, and creative assets created in your workspace.',
                  ),

                  _buildSection(
                    icon: Icons.auto_awesome_outlined,
                    title: '3. How We Use Your Information',
                    content:
                        '• AI Content Generation: Creating customized social media posts, captions, hashtags, and marketing recommendations tailored to your business industry.\n'
                        '• Campaign Management & Reporting: Fetching real-time ad delivery metrics (CTR, CPC, Spend, Reach) and computing ROI analysis.\n'
                        '• Lead Synchronization: Ingesting Meta lead generation submissions directly into your CRM dashboard for immediate follow-up.\n'
                        '• Service Improvement & Authentication: Verifying OTP logins, managing subscriptions, and maintaining system uptime.',
                  ),

                  _buildSection(
                    icon: Icons.hub_outlined,
                    title: '4. Meta & Social Media Data Compliance',
                    content:
                        '• Direct Platform Interaction: MarketAI uses official Meta Graph APIs (v20.0+) to read insights and publish content only upon your explicit authorization.\n'
                        '• No Third-Party Sale: We DO NOT sell, rent, or trade your Meta account data, customer leads, or ad creatives to any third parties or data brokers.\n'
                        '• Token Security: OAuth access tokens and Page tokens are stored with high-grade server encryption and used solely for your account operations.',
                  ),

                  _buildSection(
                    icon: Icons.lock_outline_rounded,
                    title: '5. Data Storage, Security & AI Safeguards',
                    content:
                        '• All data transmissions are encrypted using standard SSL/TLS 1.3 cryptographic protocols.\n'
                        '• User private data and customer lead entries are never used to train public machine learning foundation models.\n'
                        '• Authentication is fortified using JWT tokens with automatic session expiration.',
                  ),

                  _buildSection(
                    icon: Icons.delete_outline_rounded,
                    title: '6. User Rights & Data Deletion',
                    content:
                        'You have complete control over your data:\n'
                        '• Right to Access & Update: You can edit your profile, business details, or connected accounts at any time from Settings.\n'
                        '• Right to Erasure / Deletion: To delete your account and all associated Meta data, visit our Data Deletion callback endpoint or send a request to privacy@trustingbrains.com. Data will be purged within 48 business hours.',
                  ),

                  _buildSection(
                    icon: Icons.mail_outline_rounded,
                    title: '7. Contact Us & Grievance Redressal',
                    content:
                        'If you have any questions, concerns, or requests regarding this Privacy Policy or your data, please reach out to our team:\n\n'
                        'Trusting Brains / MarketAI Support\n'
                        '• Email: privacy@trustingbrains.com / support@marketai.com\n'
                        '• Helpline: +91 98765 43210\n'
                        '• Address: Technology Park, India',
                  ),

                  const SizedBox(height: 12),

                  // Bottom Action
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back to App'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
