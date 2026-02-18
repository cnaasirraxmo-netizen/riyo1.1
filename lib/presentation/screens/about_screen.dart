import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABOUT RIYOBOX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_circle_filled, size: 80, color: Colors.deepPurple),
            ),
            const SizedBox(height: 24),
            const Text(
              'RIYOBOX',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const Text(
              'Premium Streaming Experience',
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              context,
              'VERSION',
              '2.4.0 (Build 9L6K4D38)',
              Icons.info_outline,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'DEVELOPER',
              'RIYOBOX Digital Solutions',
              Icons.code,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'WEBSITE',
              'www.riyobox.com',
              Icons.language,
            ),
            const SizedBox(height: 40),
            const Text(
              'RIYOBOX is a world-class streaming platform providing high-quality movies, TV series, and live sports hub. Our mission is to deliver the best entertainment experience to your fingertips.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 40),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),
            const Text(
              '© 2024 RIYOBOX. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
