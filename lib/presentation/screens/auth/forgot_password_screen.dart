import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/presentation/widgets/riyo_components.dart';
import 'package:riyo/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0; // 0: Email, 1: Code + New Password
  bool _isLoading = false;

  void _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).forgotPassword(email);
      if (mounted) {
        setState(() {
          _currentStep = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset code sent to your email.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleResetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty || password.isEmpty) return;
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).resetPassword(email, code, password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully. Please login with your new password.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Forgot Password',
                style: AppTypography.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _currentStep == 0
                  ? 'Enter your email address and we will send you a 6-digit code to reset your password.'
                  : 'Enter the 6-digit code sent to your email and your new password.',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).textTheme.labelSmall?.color,
                ),
              ),
              const SizedBox(height: 48),
              if (_currentStep == 0) ...[
                RiyoTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),
                RiyoButton(
                  text: 'Send Reset Code',
                  isLoading: _isLoading,
                  onPressed: _handleSendCode,
                ),
              ] else ...[
                RiyoTextField(
                  controller: _codeController,
                  label: '6-Digit Code',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                RiyoTextField(
                  controller: _passwordController,
                  label: 'New Password',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                RiyoTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                RiyoButton(
                  text: 'Reset Password',
                  isLoading: _isLoading,
                  onPressed: _handleResetPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
