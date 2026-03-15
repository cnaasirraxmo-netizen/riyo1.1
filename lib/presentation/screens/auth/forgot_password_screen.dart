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
  bool _isLoading = false;

  void _handleReset() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).sendPasswordResetEmail(
        _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent. Please check your inbox.')),
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
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
                'Enter your email address and we will send you a link to reset your password.',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).textTheme.labelSmall?.color,
                ),
              ),
              const SizedBox(height: 48),
              RiyoTextField(
                controller: _emailController,
                label: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              RiyoButton(
                text: 'Send Reset Link',
                isLoading: _isLoading,
                onPressed: _handleReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
