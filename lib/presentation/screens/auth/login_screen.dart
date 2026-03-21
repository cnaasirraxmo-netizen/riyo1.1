import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/presentation/widgets/riyo_components.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/core/localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  int _adTimerSeconds = 5;
  bool _canSkipAd = false;
  Timer? _adTimer;

  @override
  void initState() {
    super.initState();
    _startAdTimer();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_adTimerSeconds > 0) {
        setState(() => _adTimerSeconds--);
      } else {
        setState(() => _canSkipAd = true);
        _adTimer?.cancel();
      }
    });
  }

  void _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        String message = e.toString().replaceAll('Exception: ', '');
        if (message.contains('invalid-credential') || message.contains('wrong-password')) {
          message = 'Incorrect email or password.';
        } else if (message.contains('user-not-found')) {
          message = 'User account not found.';
        } else if (message.contains('network-request-failed')) {
          message = 'No internet connection.';
        } else if (message.contains('timeout')) {
          message = 'Server is unavailable. Try again later.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'RETRY', textColor: Colors.white, onPressed: _handleLogin),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _canSkipAd ? () {
                Provider.of<AuthProvider>(context, listen: false).loginAsGuest().then((_) {
                  if (mounted) context.go('/home');
                });
              } : null,
              style: TextButton.styleFrom(
                backgroundColor: _canSkipAd ? Colors.white10 : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                _canSkipAd ? 'Skip & Guest' : 'Skip in $_adTimerSeconds...',
                style: TextStyle(color: _canSkipAd ? Colors.white : Colors.white54, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'welcome_message'.tr(context),
                  style: AppTypography.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue watching',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).textTheme.labelSmall?.color,
                  ),
                ),
                const SizedBox(height: 48),
                RiyoTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email is required.';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                RiyoTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required.';
                    if (value.length < 6) return 'Password must be at least 6 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: RiyoButton(
                    text: 'Forgot password?',
                    isPrimary: false,
                    onPressed: () => context.push('/forgot-password'),
                  ),
                ),
                const SizedBox(height: 24),
                RiyoButton(
                  text: 'login_button'.tr(context),
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
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
                    if (_isLoading) return;
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
                const SizedBox(height: 16),
                RiyoSocialButton(
                  text: 'Continue with Apple',
                  icon: const Icon(Icons.apple, size: 28),
                  onPressed: () {},
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTypography.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: Text(
                        'Sign Up',
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
