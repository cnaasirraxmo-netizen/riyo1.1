import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HELP & SUPPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSupportSection(
            context,
            'CONTACT US',
            [
              _SupportItem(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'support@riyobox.com',
                onTap: () {},
              ),
              _SupportItem(
                icon: Icons.chat_bubble_outline,
                title: 'Live Chat',
                subtitle: 'Available 24/7 for Premium users',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSupportSection(
            context,
            'FREQUENTLY ASKED QUESTIONS',
            [
              _SupportItem(
                icon: Icons.question_answer_outlined,
                title: 'How to cancel subscription?',
                onTap: () {},
              ),
              _SupportItem(
                icon: Icons.question_answer_outlined,
                title: 'Supported devices',
                onTap: () {},
              ),
              _SupportItem(
                icon: Icons.question_answer_outlined,
                title: 'Streaming quality issues',
                onTap: () {},
              ),
              _SupportItem(
                icon: Icons.question_answer_outlined,
                title: 'Casting to TV guide',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSupportSection(
            context,
            'REPORT',
            [
              _SupportItem(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                onTap: () {},
              ),
              _SupportItem(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Terms of Service', style: TextStyle(color: Colors.deepPurpleAccent)),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Privacy Policy', style: TextStyle(color: Colors.deepPurpleAccent)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, String title, List<_SupportItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final int idx = entry.key;
              final _SupportItem item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: Colors.deepPurpleAccent),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: item.subtitle != null ? Text(item.subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
                    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                    onTap: item.onTap,
                  ),
                  if (idx < items.length - 1)
                    const Divider(height: 1, color: Colors.white10, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SupportItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _SupportItem({required this.icon, required this.title, this.subtitle, required this.onTap});
}
