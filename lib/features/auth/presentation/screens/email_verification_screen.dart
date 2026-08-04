import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/auth/providers/auth_provider.dart';

/// EmailVerificationScreen — shown to authenticated users whose email
/// is still unverified. User can:
///   - tap "I've verified — continue" to re-check server state and,
///     if verified, get routed by the AuthGate to the main app.
///   - tap "Resend verification email" to send another link.
///   - tap "Sign out" to return to the login screen.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _autoSent = false;

  @override
  void initState() {
    super.initState();
    // Auto-send the first verification email once the screen mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoSend());
  }

  Future<void> _maybeAutoSend() async {
    if (_autoSent) return;
    _autoSent = true;
    final auth = context.read<AuthProvider>();
    if (!auth.isEmailVerified && auth.firebaseUser != null) {
      await auth.sendVerificationEmail();
      if (!mounted) return;
      final msg = auth.errorMessage;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Check your inbox.'),
          ),
        );
      }
    }
  }

  Future<void> _onContinue() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.reloadAndCheckVerification();
    if (!mounted) return;
    if (ok) {
      // AuthGate will rebuild and route us to MainApp automatically.
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          auth.errorMessage ??
              'Email is still unverified. Please tap the link in your email first.',
        ),
      ),
    );
  }

  Future<void> _onResend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendVerificationEmail();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Verification email resent.'
              : (auth.errorMessage ?? 'Could not resend email.'),
        ),
      ),
    );
  }

  Future<void> _onSignOut() async {
    final auth = context.read<AuthProvider>();
    await auth.signOut();
    // AuthGate will rebuild and show LoginScreen.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification link to\n$email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Open the link in your email, then come back here and tap '
                  'continue. Check your spam folder if you don\'t see it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Error message
                if (auth.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Continue
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "I've verified — continue",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 12),

                // Resend
                OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : _onResend,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Resend verification email'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign out
                TextButton(
                  onPressed: auth.isLoading ? null : _onSignOut,
                  child: const Text(
                    'Use a different account',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}