import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/presentation/screens/settings/settings_widgets.dart';

class ParentalControlSettingsScreen extends StatefulWidget {
  const ParentalControlSettingsScreen({super.key});

  @override
  State<ParentalControlSettingsScreen> createState() => _ParentalControlSettingsScreenState();
}

class _ParentalControlSettingsScreenState extends State<ParentalControlSettingsScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _showSetPinDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Parental PIN'),
        content: TextField(
          controller: _pinController,
          decoration: const InputDecoration(
            labelText: 'Enter 4-digit PIN',
            hintText: 'xxxx',
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              if (_pinController.text.length == 4) {
                settings.setKidsPin(_pinController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated successfully')));
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parental Control'),
      ),
      body: ListView(
        children: [
          const SettingsHeader(title: 'Kids Mode'),
          SettingsToggle(
            icon: Icons.child_care,
            title: 'Enable Kids Mode',
            subtitle: 'Restrict content to Kids section only',
            value: settings.isKidsMode,
            onChanged: (val) {
              if (val && settings.kidsPin.isEmpty) {
                _showSetPinDialog(settings);
              } else {
                settings.setKidsMode(val);
              }
            },
          ),
          const SettingsHeader(title: 'Security'),
          SettingsItem(
            icon: Icons.pin_outlined,
            title: 'Change PIN',
            subtitle: settings.kidsPin.isEmpty ? 'Not set' : 'PIN is active',
            onTap: () => _showSetPinDialog(settings),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'When Kids Mode is enabled, a PIN will be required to access adult content or disable the restriction.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
