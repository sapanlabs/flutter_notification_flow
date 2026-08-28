import 'package:flutter/material.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';

/// Screen displayed when navigating via a profile notification route.
class ProfilePage extends StatelessWidget {
  /// The payload passed via route arguments.
  final NotificationPayload payload;

  const ProfilePage({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final userId = payload.data['userId']?.toString() ?? 'N/A';
    final username = payload.data['username']?.toString() ?? 'anonymous';

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    child: Icon(Icons.person_outline, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '@$username',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User ID: $userId',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Payload Data: ${payload.data}',
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
