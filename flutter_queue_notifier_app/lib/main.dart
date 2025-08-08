import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';

/// Plugin for displaying local notifications on the device
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures widgets are initialized before Firebase

  try {
    // Initialize Firebase only if not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enable offline mode for Firebase Realtime Database
      FirebaseDatabase.instance.setPersistenceEnabled(true);

      // Sign in the user anonymously (no registration required)
      await FirebaseAuth.instance.signInAnonymously();
      print("Signed in anonymously: ${FirebaseAuth.instance.currentUser?.uid}");
    } else {
      print("Firebase app already initialized");
    }

    // Initialize local notification settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  } catch (e) {
    print("Firebase initialization or auth error: $e");

    // Ignore known duplicate initialization error, rethrow other errors
    if (!e.toString().contains('already exists')) rethrow;
  }

  runApp(const QueueNotifierApp()); // Launch the main app widget
}

/// Root widget of the application
class QueueNotifierApp extends StatelessWidget {
  const QueueNotifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Queue Notifier App', // App title shown in the task switcher
      debugShowCheckedModeBanner: false, // Removes the debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue, // Set primary theme color
      ),
      home: const HomePage(), // Load the home page on startup
    );
  }
}
