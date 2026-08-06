import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(String phone) async {
    final otp = _otpController.text;
    if (otp.length != 6) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await AuthService.verifyOtp(phone, otp);

      if (data['success'] == true) {
        final token = data['token'];
        final user = data['user'];

        // Save session state to Riverpod Provider
        ref.read(authProvider.notifier).setSession(token, user);

        // Persist token and user locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(user));

        if (mounted) {
          if (user['name'] != null && user['name'].toString().isNotEmpty) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.profile);
          }
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, data['message'] ?? 'Invalid OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Connection error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp(String phone) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await AuthService.sendOtp(phone);
      if (mounted) {
        showAppSnackBar(context, data['message'] ?? 'OTP sent successfully');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error connecting to server.');
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
    final phone = ModalRoute.of(context)!.settings.arguments as String? ?? '1234567890';
    final formattedPhone = phone.length == 10 
        ? '${phone.substring(0, 5)} ${phone.substring(5)}'
        : phone;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                        ),
                      ),
                      const Spacer(flex: 2),
                      const Text('Verify your number', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 9),
                      Text(
                        'Enter the 6-digit OTP sent to\n+91 $formattedPhone',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
                      ),
                      const SizedBox(height: 38),
                      GestureDetector(
                        onTap: () {
                          _focusNode.requestFocus();
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TextField(
                              controller: _otpController,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.number,
                              showCursor: false,
                              maxLength: 6,
                              style: const TextStyle(color: Colors.transparent, fontSize: 1),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (val) {
                                setState(() {});
                                if (val.length == 6) {
                                  _verifyOtp(phone);
                                }
                              },
                            ),
                            IgnorePointer(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  final otpText = _otpController.text;
                                  final filled = index < otpText.length;
                                  final isFocused = _focusNode.hasFocus && index == otpText.length;
                                  
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 44,
                                    height: 52,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: isFocused 
                                            ? AppColors.primary 
                                            : (filled ? AppColors.primary : AppColors.border),
                                        width: (isFocused || filled) ? 1.8 : 1,
                                      ),
                                      boxShadow: isFocused ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ] : null,
                                    ),
                                    child: Text(
                                      filled ? otpText[index] : '',
                                      style: const TextStyle(
                                        fontSize: 19, 
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextButton(
                        onPressed: _isLoading ? null : () => _resendOtp(phone),
                        child: const Text('Resend OTP', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 15),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : PrimaryButton(
                              label: 'Verify OTP',
                              onPressed: _otpController.text.length == 6 ? () => _verifyOtp(phone) : null,
                            ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
