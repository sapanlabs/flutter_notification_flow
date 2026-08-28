import 'package:flutter/material.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';

/// The interactive demonstration dashboard for Flutter Notification Flow.
class HomePage extends StatefulWidget {
  /// The [NotificationFlow] instance.
  final NotificationFlow flow;

  const HomePage({super.key, required this.flow});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<NotificationFlowEvent> _events = [];

  @override
  void initState() {
    super.initState();
    widget.flow.events.listen((event) {
      if (mounted) {
        setState(() {
          _events.insert(0, event);
        });
      }
    });
  }

  void _simulateChat() {
    widget.flow.handle(
      const NotificationPayload(
        type: 'chat',
        id: 'chat_msg_01',
        data: {'chatId': '101', 'sender': 'Sarah Connor'},
      ),
    );
  }

  void _simulatePost() {
    widget.flow.handle(
      const NotificationPayload(
        type: 'post',
        id: 'post_notif_02',
        data: {'postId': '404', 'title': 'Deep Dive into Flutter Architecture'},
      ),
    );
  }

  void _simulateProfile() {
    widget.flow.handle(
      const NotificationPayload(
        type: 'profile',
        id: 'profile_notif_03',
        data: {'userId': 'user_88', 'username': 'flutter_dev'},
      ),
    );
  }

  void _simulateUnknown() {
    widget.flow.handle(
      const NotificationPayload(
        type: 'flash_sale_deal',
        data: {'discount': '50%', 'coupon': 'SAVE50'},
      ),
    );
  }

  Future<void> _simulateDuplicate() async {
    const payload = NotificationPayload(
      type: 'chat',
      id: 'duplicate_test_id',
      data: {'chatId': '999', 'sender': 'Duplicate Bot'},
    );

    // First attempt
    await widget.flow.handle(payload);

    // Second attempt (should be intercepted by duplicate guard)
    final handledSecond = await widget.flow.handle(payload);

    if (mounted && !handledSecond) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Duplicate notification was blocked by NotificationDuplicateGuard!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _simulateJson() {
    widget.flow
        .handleJson('{"type":"chat","chatId":"303","sender":"JSON Assistant"}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Notification Flow'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Event Log',
            onPressed: () => setState(() => _events.clear()),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: _buildControls(context)),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildEventLog(context)),
                    ],
                  )
                : ListView(
                    children: [
                      _buildControls(context),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 380,
                        child: _buildEventLog(context),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.send_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simulate Notification Interactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Click any button below to trigger incoming payloads and verify routing & lifecycle handling.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _simulateChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Simulate Chat Notification'),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _simulatePost,
              icon: const Icon(Icons.article_outlined),
              label: const Text('Simulate Post Notification'),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _simulateProfile,
              icon: const Icon(Icons.person_outline),
              label: const Text('Simulate Profile Notification'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _simulateUnknown,
              icon: const Icon(Icons.help_outline),
              label: const Text('Simulate Unknown Type (Graceful Unhandled)'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _simulateDuplicate,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Simulate Duplicate Notification'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _simulateJson,
              icon: const Icon(Icons.code),
              label: const Text('Simulate Flat JSON String Payload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLog(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.stream_rounded,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live Event Stream',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text('${_events.length} events'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Expanded(
              child: _events.isEmpty
                  ? Center(
                      child: Text(
                        'No notification events yet.\nTrigger a simulation to observe events.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _events.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          leading: _buildStatusBadge(event.status),
                          title: Text(
                            'type: "${event.payload.type}"',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'data: ${event.payload.data}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 11),
                          ),
                          trailing: Text(
                            '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(NotificationFlowStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case NotificationFlowStatus.received:
        color = Colors.blue;
        icon = Icons.move_to_inbox;
        break;
      case NotificationFlowStatus.queued:
        color = Colors.purple;
        icon = Icons.hourglass_top_rounded;
        break;
      case NotificationFlowStatus.handling:
        color = Colors.indigo;
        icon = Icons.sync_rounded;
        break;
      case NotificationFlowStatus.handled:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case NotificationFlowStatus.unhandled:
        color = Colors.amber.shade800;
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationFlowStatus.duplicate:
        color = Colors.orange;
        icon = Icons.filter_none;
        break;
      case NotificationFlowStatus.failed:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.name,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
