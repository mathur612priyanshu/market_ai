import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      showAppSnackBar(context, 'Enter a valid 10-digit mobile number');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await AuthService.sendOtp(phone);

      if (data['success'] == true) {
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.otp,
            arguments: phone,
          );
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, data['message'] ?? 'Failed to send OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Connection error. Please check backend server.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              const Center(child: MarketAiLogo()),
              const Spacer(flex: 2),
              const Text('Enter your mobile number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              const Text('We will send you an OTP to verify', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    height: 51,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Text('+91', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(width: 3),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isLoading,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: const InputDecoration(hintText: 'Mobile number'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(label: 'Send OTP', onPressed: _continue),
              const Spacer(flex: 5),
              const Center(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: AppColors.muted, fontSize: 10.5, height: 1.5),
                    children: [
                      TextSpan(text: 'By continuing, you agree to our\n'),
                      TextSpan(text: 'Terms & Conditions', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      TextSpan(text: ' & '),
                      TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
