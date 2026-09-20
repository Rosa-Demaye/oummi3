import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oummi3/features/auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home - $role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(userProfileProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text('Home Screen for $role'),
      ),
    );
  }
}
