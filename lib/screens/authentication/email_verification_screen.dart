import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_viewmodel.dart';

class EmailVerificationSheet extends StatefulWidget {
  final String email;
  final VoidCallback onVerificationComplete;
  final VoidCallback onBackToSignIn;

  const EmailVerificationSheet({
    Key? key,
    required this.email,
    required this.onVerificationComplete,
    required this.onBackToSignIn,
  }) : super(key: key);

  @override
  _EmailVerificationSheetState createState() => _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends State<EmailVerificationSheet> {
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    Future.delayed(const Duration(seconds: 5), _checkVerificationStatus);
  }

  Future<void> _checkVerificationStatus() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final isVerified = await authViewModel.checkEmailVerification();

      if (isVerified && mounted) {
        widget.onVerificationComplete();
      } else if (mounted) {
        setState(() => _isLoading = false);
        _startVerificationCheck();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error checking verification status';
        });
        _startVerificationCheck();
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      await authViewModel.sendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to resend verification email';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Icon(
            Icons.mark_email_read_outlined,
            size: 60,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Verify Your Email',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'We\'ve sent a verification link to ${widget.email}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your email and click the verification link to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: _isResending ? null : _resendVerificationEmail,
            child: _isResending
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Resend Verification Email'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onBackToSignIn,
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }
}