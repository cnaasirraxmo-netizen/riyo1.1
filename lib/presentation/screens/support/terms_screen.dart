import 'package:flutter/material.dart';
import 'package:riyo/core/design_system.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('TERMS OF SERVICE',
            style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms of Service',
                style: AppTypography.titleLarge),
            const SizedBox(height: 10),
            const Text('Last updated: February 2024', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),
            Text(
              '1. Acceptance of Terms\n\nBy accessing and using RIYO, you agree to be bound by these Terms of Service and all applicable laws and regulations.\n\n'
              '2. Use License\n\nPermission is granted to temporarily download one copy of the materials (information or software) on RIYO\'s app for personal, non-commercial transitory viewing only.\n\n'
              '3. Disclaimer\n\nThe materials on RIYO are provided on an \'as is\' basis. RIYO makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
