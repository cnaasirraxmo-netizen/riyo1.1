import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('SUPPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get in touch with our team or browse our resources.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildSupportOption(
            icon: Icons.chat_bubble_outline,
            title: 'Live Chat',
            subtitle: 'Typical response time: 5 minutes',
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat service is currently unavailable. Please try email.')));
            },
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@riyobox.com',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Legal information and rules',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildSupportOption(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () {},
          ),
          const SizedBox(height: 40),
          const Text(
            'FAQ',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'How do I cancel my subscription?',
            'You can manage your subscription in the account settings page or through your app store account.',
          ),
          _buildFAQItem(
            'Can I watch movies offline?',
            'Yes, most of our content can be downloaded for offline viewing. Look for the download icon on the movie details page.',
          ),
          _buildFAQItem(
            'How many devices can I use?',
            'You can stream on up to 3 devices simultaneously with a standard account.',
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.deepPurpleAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Theme(
      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: Colors.grey, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
