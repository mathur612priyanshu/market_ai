import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../server_url.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SubscriptionPlanScreen extends ConsumerStatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  ConsumerState<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends ConsumerState<SubscriptionPlanScreen> {
  int selected = 1;
  List<dynamic> packages = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  late Razorpay _razorpay;
  String? currentPackageId;
  int currentDays = 30;

  @override
  void initState() {
    super.initState();
    fetchPlans();
    
    // Initialize Razorpay SDK instance and bind events listeners
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    // Clear listeners to avoid memory leaks
    _razorpay.clear();
    super.dispose();
  }

  // Razorpay Event Callbacks
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => isSubmitting = true);

    try {
      // Trigger signature verification on backend server
      final verifyRes = await http.post(
        Uri.parse('$baseUrl/api/plans/razorpay/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'packageId': currentPackageId,
        }),
      );

      final data = jsonDecode(verifyRes.body);

      if (verifyRes.statusCode == 200 && data['success'] == true) {
        // Update user state locally
        final currentUser = ref.read(authProvider).user;
        if (currentUser != null) {
          final updatedUser = Map<String, dynamic>.from(currentUser);
          updatedUser['plan'] = 'Pro';
          updatedUser['subscriptionExpiresAt'] = data['subscriptionExpiresAt'];
          ref.read(authProvider.notifier).updateUser(updatedUser);
        }

        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 50),
              title: const Text('Recharge Successful!', style: TextStyle(fontWeight: FontWeight.w900)),
              content: Text(
                'Your account has been upgraded to the Pro tier for $currentDays days.\nEnjoy unlimited generations and competitor spies!',
                textAlign: TextAlign.center,
              ),
              actions: [
                Center(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      Navigator.pop(context); // Close success dialog
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
          if (mounted) {
            Navigator.pop(context); // Close plans screen
          }
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, data['error'] ?? 'Payment verification failed.');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Verification error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      showAppSnackBar(context, 'Payment failed: ${response.message ?? "Code ${response.code}"}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      showAppSnackBar(context, 'External wallet selected: ${response.walletName}');
    }
  }

  Future<void> fetchPlans() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/plans/rates'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            packages = data['packages'] ?? [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load plans.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> purchaseSubscription(String packageId, String planName, int price, int days) async {
    final token = ref.read(authProvider).token;
    final user = ref.read(authProvider).user;
    if (token == null) return;

    setState(() => isSubmitting = true);
    currentPackageId = packageId;
    currentDays = days;

    try {
      // 1. Create Razorpay order ID on backend
      final orderRes = await http.post(
        Uri.parse('$baseUrl/api/plans/razorpay/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'packageId': packageId,
        }),
      );

      final orderData = jsonDecode(orderRes.body);

      if (orderRes.statusCode == 200 && orderData['success'] == true) {
        final orderId = orderData['orderId'];
        final keyId = orderData['keyId'];
        final amount = orderData['amount'];

        // 2. Setup checkout options
        var options = {
          'key': keyId,
          'amount': amount * 100, // Amount in paise
          'name': 'MarketAI Marketing Assistant',
          'description': planName,
          'order_id': orderId,
          'prefill': {
            'contact': user?['phone'] ?? '',
            'email': user?['email'] ?? '',
          },
          'external': {
            'wallets': ['paytm']
          }
        };

        // 3. Open Razorpay mobile checkout window
        _razorpay.open(options);

      } else {
        if (mounted) {
          showAppSnackBar(context, orderData['error'] ?? 'Failed to create payment order.');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Order creation error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(errorMessage!, style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });
                    fetchPlans();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userSession = ref.watch(authProvider).user;
    final userPlan = userSession?['plan'] ?? 'Free';
    final expiryDate = userSession?['subscriptionExpiresAt'];
    final formattedExpiry = _formatDate(expiryDate);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ScreenHeader(
                title: 'Subscription Plan',
                subtitle: 'Choose the best plan for your business.',
                showBack: true,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
                child: Column(
                  children: [
                    // Active Subscription Plan Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: userPlan == 'Pro' ? AppColors.lavender : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: userPlan == 'Pro' ? AppColors.primary : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            userPlan == 'Pro' ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
                            color: userPlan == 'Pro' ? AppColors.primary : AppColors.muted,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userPlan == 'Pro' ? 'Active Plan: Growth Pro' : 'Active Plan: Free Tier',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userPlan == 'Pro'
                                      ? 'Your plan will expire on: $formattedExpiry'
                                      : 'Limits apply: 3 posts/day and 5 spies/month. Upgrade below.',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Packages Section Title
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'Available Recharge Passes',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.muted),
                        ),
                      ),
                    ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: packages.length,
                      itemBuilder: (context, index) {
                        final pkg = packages[index];
                        final isSelected = selected == index;
                        final isPopular = pkg['id'] == '3_months'; // Quarterly is popular
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => setState(() => selected = index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.lavender : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                pkg['name'] ?? '',
                                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isPopular) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Popular',
                                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${pkg['days']} Days validity • Unlimited access',
                                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                        ),
                                        if (pkg['discountPercent'] > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Save ${pkg['discountPercent']}% (Original: ₹${pkg['originalPrice']})',
                                            style: const TextStyle(fontSize: 10, color: AppColors.instagram, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${pkg['finalPrice']}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                                      ),
                                      const Text(
                                        'one-time payment',
                                        style: TextStyle(fontSize: 8.5, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    if (isSubmitting)
                      const CircularProgressIndicator(color: AppColors.primary)
                    else
                      PrimaryButton(
                        label: 'Recharge & Upgrade',
                        onPressed: () {
                          if (packages.isEmpty) return;
                          final selectedPkg = packages[selected];
                          purchaseSubscription(
                            selectedPkg['id'],
                            selectedPkg['name'],
                            selectedPkg['finalPrice'],
                            selectedPkg['days'],
                          );
                        },
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
