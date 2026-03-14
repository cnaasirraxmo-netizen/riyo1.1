import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              child: Text(
                'RIYO',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'RIYO PREMIUM',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.purple, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'RIYO is a production-grade movie streaming application designed to provide the best entertainment experience with offline mode, high-quality playback, and seamless casting.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 60),
            Text(
              '© 2024 RIYO Entertainment Inc.',
              style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color?.withOpacity(0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
