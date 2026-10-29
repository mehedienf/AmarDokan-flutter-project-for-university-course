import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/auth/data/services/auth_service.dart';
import 'package:amar_dokan/features/auth/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  bool _isSupportedNumber(String phone) =>
      RegExp(r'^01(?:6|8)\d{8}$').hasMatch(phone);

  Future<void> _continue() async {
    final phone = _phoneController.text.trim();
    if (!_isSupportedNumber(phone)) {
      _showError('Enter a valid Robi/Cirkle mobile number.');
      return;
    }

    setState(() => _isLoading = true);
    final service = AuthService();
    final auth = context.read<AuthProvider>();
    try {
      if (await service.isPhoneSubscribed(phone)) {
        if (!await auth.signInWithBdApps(phone: phone)) {
          _showError(auth.errorMessage ?? 'Login failed. Try again.');
        }
        return;
      }

      final request = await service.requestPhoneOtp(phone);
      if (request.success && request.referenceNo.isNotEmpty) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phone: phone,
              referenceNo: request.referenceNo,
            ),
          ),
        );
      } else if (request.statusCode == 'E1351' ||
          request.message.toLowerCase().contains('already registered')) {
        if (!await auth.signInWithBdApps(phone: phone)) {
          _showError(auth.errorMessage ?? 'Login failed. Try again.');
        }
      } else {
        _showError(
          request.message.isNotEmpty
              ? request.message
              : 'OTP could not be sent.',
        );
      }
    } catch (e) {
      _showError('Request failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Amar Dokan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in with your mobile number',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Daily charge is 2.78 BDT (including VAT, SD & SC). '
                  'For Robi and Cirkle users only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _continue(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    hintText: '018********',
                    prefixIcon: Icon(Icons.phone_android_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  final String phone;
  final String referenceNo;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.referenceNo,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 240;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds == 0) {
        _timer?.cancel();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      _showError('Enter the OTP sent to your phone.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = AuthService();
      final verified = await service.verifyPhoneOtp(
        phone: widget.phone,
        otp: otp,
        referenceNo: widget.referenceNo,
      );
      if (!verified) {
        _showError('Invalid OTP. Please try again.');
        return;
      }

      // OTP verified: log in directly. Subscription may still be
      // INITIAL CHARGING PENDING, which is fine.
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final signedIn = await auth.signInWithBdApps(phone: widget.phone);
      if (!mounted) return;
      if (signedIn) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _showError(auth.errorMessage ?? 'Login failed. Try again.');
      }
    } catch (e) {
      _showError('Verify failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(title: const Text('Verify mobile number')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.sms_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'OTP sent to ${widget.phone}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  hintStyle: TextStyle(color: Colors.black38),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$minutes:$seconds',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify and continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
