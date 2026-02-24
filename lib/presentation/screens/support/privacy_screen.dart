import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('PRIVACY POLICY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Last updated: February 2024', style: TextStyle(color: Colors.grey, fontSize: 14)),
            SizedBox(height: 30),
            Text(
              'Your privacy is important to us. It is RIYOBOX\'s policy to respect your privacy regarding any information we may collect from you through our app.\n\n'
              'We only ask for personal information when we truly need it to provide a service to you. We collect it by fair and lawful means, with your knowledge and consent.\n\n'
              'We don’t share any personally identifying information publicly or with third-parties, except when required to by law.\n\n'
              'Your continued use of our app will be regarded as acceptance of our practices around privacy and personal information.',
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
