import 'package:flutter/material.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';

/// Screen displayed when navigating via a chat notification route.
class ChatPage extends StatelessWidget {
  /// The payload passed via route arguments.
  final NotificationPayload payload;

  const ChatPage({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final chatId = payload.data['chatId']?.toString() ?? 'Unknown';
    final sender = payload.data['sender']?.toString() ?? 'Friend';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $sender'),
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
                    child: Icon(Icons.chat_bubble_outline, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chat ID: $chatId',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sender: $sender',
                    style: Theme.of(context).textTheme.bodyLarge,
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
