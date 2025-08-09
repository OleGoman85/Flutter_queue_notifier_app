import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/queue_info.dart';
import '../main.dart';

/// A card widget that displays a single queue item with countdown and delete functionality.
class QueueCard extends StatefulWidget {
  final QueueInfo queue;
  final VoidCallback onDelete;

  const QueueCard({super.key, required this.queue, required this.onDelete});

  @override
  State<QueueCard> createState() => _QueueCardState();
}

class _QueueCardState extends State<QueueCard> {
  late int _remainingMinutes;
  Timer? _timer;
  bool _notificationSent = false;

  @override
  void initState() {
    super.initState();
    _remainingMinutes = widget.queue.estimatedWaitMinutes;

    if (!widget.queue.isDone) {
      _startTimer();
    } else {
      widget
          .onDelete(); // Immediately remove the card if the queue is already completed
    }
  }

  /// Starts a timer that counts down every minute, updates currentNumber, and sends a notification if needed
  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingMinutes > 0) {
          _remainingMinutes--;
          widget.queue.updateCurrentNumber(
            _remainingMinutes,
          ); // Update currentNumber

          // Notify the user if only 5 people are left
          if (widget.queue.remainingCount <= 5 && !_notificationSent) {
            _sendNotification();
            _notificationSent = true;
          }

          // Remove the card if the queue is done
          if (widget.queue.isDone) {
            widget.onDelete();
            timer.cancel();
          }
        } else {
          _timer?.cancel(); // Stop timer when countdown ends
        }
      });
    });
  }

  /// Sends a local notification to the user
  Future<void> _sendNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'queue_channel',
          'Queue Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      widget.queue.institutionId.hashCode,
      'Queue at ${widget.queue.institutionName}',
      'Only 5 numbers left (about 10 minutes remaining)!',
      platformChannelSpecifics,
      payload: widget.queue.institutionId,
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Clean up timer when the widget is destroyed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Institution name
            Text(
              widget.queue.institutionName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            // Queue details
            Text('Your number: ${widget.queue.userNumber}'),
            Text('Current number: ${widget.queue.currentNumber}'),
            Text('Remaining numbers: ${widget.queue.remainingCount}'),
            Text('Estimated wait time: $_remainingMinutes min'),

            const SizedBox(height: 12),

            // Delete button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
