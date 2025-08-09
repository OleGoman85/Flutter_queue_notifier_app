import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';

/// Plugin for displaying local notifications on the device
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Global instance of SharedPreferences for reuse
late SharedPreferences prefs;

/// Entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures widgets are initialized before Firebase

  // Ensure all async operations are completed
  await _initializeApp();

  runApp(const QueueNotifierApp()); // Launch the main app widget
}

/// Initializes Firebase, SharedPreferences, and notifications
Future<void> _initializeApp() async {
  try {
    // Initialize Firebase only if not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      await FirebaseAuth.instance.signInAnonymously();
      print("Signed in anonymously: ${FirebaseAuth.instance.currentUser?.uid}");
    } else {
      print("Firebase app already initialized");
    }
  } catch (e) {
    print("Firebase initialization or auth error: $e");
    if (!e.toString().contains('already exists')) rethrow;
  }

  // Initialize SharedPreferences (always executed)
  prefs = await SharedPreferences.getInstance();
  print("SharedPreferences initialized");

  // Initialize local notification settings for Android and iOS
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true, // Request permission to show alerts
        requestBadgePermission: true, // Request permission to show badges
        requestSoundPermission: true, // Request permission to play sounds
      );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid, // Add Android settings
    iOS: initializationSettingsIOS, // Add iOS settings
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

/// Root widget of the application
class QueueNotifierApp extends StatelessWidget {
  const QueueNotifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Queue Notifier App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}
