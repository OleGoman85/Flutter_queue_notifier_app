import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/queue_info.dart';
import '../widgets/queue_card.dart';
import 'home_page.dart';

/// Page that displays the user's active queues
class QueuesPage extends StatefulWidget {
  const QueuesPage({super.key});

  @override
  State<QueuesPage> createState() => _QueuesPageState();
}

class _QueuesPageState extends State<QueuesPage> {
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://flutterqueuenotificationapp-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref();

  final List<QueueInfo> _queues = []; // List of active queues
  final List<StreamSubscription> _subscriptions = []; // Firebase listeners

  bool _isLoading = true; // Controls loading spinner
  String? _errorMessage; // Stores error message, if any

  @override
  void initState() {
    super.initState();
    _loadUserQueues(); // Load queue data on start
  }

  @override
  void dispose() {
    // Cancel all Firebase listeners on dispose
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  /// Loads user's saved queues from SharedPreferences
  /// and updates them from Firebase
  Future<void> _loadUserQueues() async {
    try {
      // Cancel all previous subscriptions to avoid duplicates
      for (var subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();

      final queuesJson = prefs.getString('user_queues');
      final List<Map<String, dynamic>> queueData = queuesJson != null
          ? (jsonDecode(queuesJson) as List<dynamic>)
                .cast<Map<String, dynamic>>()
          : [];

      final queues = <QueueInfo>[]; // Updated queues
      final completedQueues = <String>[]; // IDs of finished queues

      // Fetch current state of each queue from Firebase
      for (var queue in queueData) {
        final institutionId = queue['institutionId'] as String;
        final userNumber = queue['userNumber'] as String;

        final institutionSnapshot = await _database
            .child('institutions/$institutionId')
            .get();

        if (institutionSnapshot.exists) {
          final institutionData =
              institutionSnapshot.value as Map<dynamic, dynamic>;

          final queueInfo = QueueInfo.fromMap(
            institutionId,
            institutionData.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
            userNumber,
            DateTime.now(),
          );

          if (!queueInfo.isDone) {
            queues.add(queueInfo);
          } else {
            completedQueues.add(institutionId); // Mark as completed
          }
        }
      }

      // Remove all completed queues from local storage
      for (var institutionId in completedQueues) {
        await _removeQueue(institutionId, showSnackBar: false);
      }

      // Update state with active queues
      setState(() {
        _queues
          ..clear()
          ..addAll(queues);
        _isLoading = false;
        _errorMessage = null;
      });

      // Listen for changes in currentNumber for each queue
      for (var queue in queues) {
        final ref = _database.child(
          'institutions/${queue.institutionId}/currentNumber',
        );

        final subscription = ref.onValue.listen(
          (event) {
            if (!mounted) return;

            setState(() {
              final index = _queues.indexWhere(
                (q) => q.institutionId == queue.institutionId,
              );

              if (index != -1 && event.snapshot.exists) {
                // Update the currentNumber from Firebase
                _queues[index].currentNumber = event.snapshot.value.toString();

                // Remove any queues that are now complete
                for (var i = _queues.length - 1; i >= 0; i--) {
                  if (_queues[i].isDone) {
                    _removeQueue(_queues[i].institutionId, showSnackBar: false);
                  }
                }
              }
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _errorMessage = 'Error loading data: $error';
            });
          },
        );

        _subscriptions.add(subscription); // Save subscription for cleanup
      }
    } catch (e) {
      print('Error in _loadUserQueues: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load queues: $e';
      });
    }
  }

  /// Removes a queue from local storage and UI
  Future<void> _removeQueue(
    String institutionId, {
    bool showSnackBar = true,
  }) async {
    try {
      final queuesJson = prefs.getString('user_queues');
      final List<Map<String, dynamic>> queueData = queuesJson != null
          ? (jsonDecode(queuesJson) as List<dynamic>)
                .cast<Map<String, dynamic>>()
          : [];

      // Remove queue by institution ID
      queueData.removeWhere((q) => q['institutionId'] == institutionId);
      await prefs.setString('user_queues', jsonEncode(queueData));

      // Remove from UI
      setState(() {
        _queues.removeWhere((q) => q.institutionId == institutionId);
      });

      if (mounted && showSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Queue removed')));
      }
    } catch (e) {
      print('Error in _removeQueue: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing queue: $e')));
      }
    }
  }

  /// Navigates to the page for adding a new queue
  void _addNewQueue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  /// Reloads all queues and shows loading spinner
  void _refreshQueues() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadUserQueues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Queues'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQueues,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Show loading spinner
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!)) // Show error message
          : _queues.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No active queues',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addNewQueue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Add Queue'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _queues.length,
              itemBuilder: (context, index) {
                final queue = _queues[index];
                return QueueCard(
                  queue: queue,
                  onDelete: () => _removeQueue(queue.institutionId),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewQueue,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
