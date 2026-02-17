import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyobox/providers/auth_provider.dart';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profiles = auth.userAccount?['profiles'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Who's watching?",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                ...profiles.map((profile) => _buildProfileItem(context, profile)),
                _buildAddProfile(context),
              ],
            ),
            const SizedBox(height: 60),
            TextButton(
              onPressed: () => auth.logout().then((_) => context.go('/login')),
              child: const Text('SIGN OUT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, dynamic profile) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return GestureDetector(
      onTap: () async {
        await auth.selectProfile(profile['_id']);
        if (context.mounted) context.go('/home');
      },
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.deepPurpleAccent,
              image: (profile['avatar'] != null && profile['avatar'].isNotEmpty)
                ? DecorationImage(image: NetworkImage(profile['avatar']), fit: BoxFit.cover)
                : null,
            ),
            child: (profile['avatar'] == null || profile['avatar'].isEmpty)
              ? const Icon(Icons.person, color: Colors.white, size: 60)
              : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile['name'],
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProfile(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: const Icon(Icons.add, color: Colors.white54, size: 40),
        ),
        const SizedBox(height: 12),
        const Text(
          'Add Profile',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}
