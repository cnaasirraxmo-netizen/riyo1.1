import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/presentation/widgets/riyo_components.dart';
import 'package:riyo/providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).signup(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome to RIYO.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString().replaceAll('Exception: ', '');
        if (message.contains('email-already-in-use')) {
          message = 'Email already registered.';
        } else if (message.contains('weak-password')) {
          message = 'Password must be at least 8 characters.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: AppTypography.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join RIYO to start streaming',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).textTheme.labelSmall?.color,
                  ),
                ),
                const SizedBox(height: 48),
                RiyoTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please fill all required fields.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                RiyoTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please fill all required fields.';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                RiyoTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                RiyoTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please fill all required fields.';
                    if (value.length < 8) return 'Password must be at least 8 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                RiyoButton(
                  text: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _handleSignUp,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: AppTypography.labelSmall,
                      ),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                  ],
                ),
                const SizedBox(height: 24),
                RiyoSocialButton(
                  text: 'Continue with Google',
                  icon: Image.network('https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg', height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 28)),
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      await Provider.of<AuthProvider>(context, listen: false).loginWithGoogle();
                      if (mounted) context.go('/home');
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google login failed: ${e.toString().replaceAll('Exception: ', '')}')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: AppTypography.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Sign In',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
