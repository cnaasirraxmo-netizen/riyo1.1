import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/presentation/widgets/riyo_components.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            RiyoTextField(
              controller: _oldPasswordController,
              label: 'Old Password',
              obscureText: true,
              validator: (v) => (v == null || v.isEmpty) ? 'Old password is required' : null,
            ),
            const SizedBox(height: 16),
            RiyoTextField(
              controller: _newPasswordController,
              label: 'New Password',
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'New password is required';
                if (v.length < 8) return 'Password must be at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            RiyoTextField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              obscureText: true,
              validator: (v) {
                if (v != _newPasswordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 32),
            RiyoButton(
              text: 'Update Password',
              isLoading: _isLoading,
              onPressed: _handleChangePassword,
            ),
          ],
        ),
      ),
    );
  }
}
