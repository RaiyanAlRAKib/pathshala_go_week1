import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'validators.dart';
import 'widgets/loading_button.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isVerifying = false;
  bool _isSending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isVerifying = true);
    try {
      await _authService.verifySignupOtp(widget.email, _otpController.text.trim());
      final home = await _authService.homeForCurrentUser();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => home),
        (route) => false,
      );
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isSending = true);
    String message = 'A new code has been sent.';
    try {
      await _authService.resendVerification(widget.email);
    } on AuthException catch (e) {
      message = e.message;
    }
    if (!mounted) return;
    setState(() => _isSending = false);
    _showMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 84,
                  width: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.accent),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Enter verification code',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a 6-digit code to',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    counterText: '',
                  ),
                  validator: Validators.otp,
                ),
                const SizedBox(height: 20),
                LoadingButton(label: 'Verify', isLoading: _isVerifying, onPressed: _verify),
                TextButton(
                  onPressed: _isSending ? null : _resend,
                  child: Text(_isSending ? 'Sending...' : 'Resend code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}