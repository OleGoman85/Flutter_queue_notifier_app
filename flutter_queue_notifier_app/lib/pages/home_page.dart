import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'queues_page.dart';

/// This is the initial page where the user selects an institution and enters their queue number
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://flutterqueuenotificationapp-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref();

  final TextEditingController _numberController = TextEditingController();

  String? _selectedInstitutionId;
  Map<String, dynamic> _institutions = {};
  String? _currentNumber;

  @override
  void initState() {
    super.initState();

    // Rebuilds the widget when the user types their number
    _numberController.addListener(() {
      setState(() {});
    });

    // Load available institutions from Firebase
    _loadInstitutionsFromFirebase();
  }

  /// Loads the list of institutions from Firebase Realtime Database
  void _loadInstitutionsFromFirebase() async {
    try {
      FirebaseDatabase.instance.setLoggingEnabled(true); // Enable debug logging

      final snapshot = await _database.child('institutions').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        print("Loaded institutions: $data");

        setState(() {
          _institutions = data.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        });
      } else {
        print("No data found in 'institutions'");
        setState(() {
          _institutions = {};
        });
      }
    } catch (e) {
      print("Error loading institutions: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading institutions: $e")));
    }
  }

  @override
  void dispose() {
    _numberController.dispose(); // Free resources when the widget is destroyed
    super.dispose();
  }

  /// Saves the user's selected queue to SharedPreferences and navigates to QueuesPage
  void _goToQueuesPage() async {
    if (_selectedInstitutionId != null && _numberController.text.isNotEmpty) {
      final queuesJson = prefs.getString('user_queues');

      final List<Map<String, dynamic>> queueData = queuesJson != null
          ? (jsonDecode(queuesJson) as List<dynamic>)
                .cast<Map<String, dynamic>>()
          : [];

      queueData.add({
        'institutionId': _selectedInstitutionId,
        'userNumber': _numberController.text.trim(),
      });

      await prefs.setString('user_queues', jsonEncode(queueData));

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QueuesPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prepare a list of institutions for the dropdown
    final institutionList = _institutions.entries
        .map(
          (entry) => {
            'id': entry.key,
            'name': entry.value['name'].toString(),
            'currentNumber': entry.value['currentNumber'].toString(),
          },
        )
        .toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Electronic Queue'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select an institution',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown for selecting institution
                  _institutions.isEmpty
                      ? const CircularProgressIndicator()
                      : DropdownSearch<Map<String, String>>(
                          items: institutionList,
                          itemAsString: (item) => item['name']!,
                          selectedItem: _selectedInstitutionId != null
                              ? institutionList.firstWhere(
                                  (e) => e['id'] == _selectedInstitutionId,
                                  orElse: () => {'id': '', 'name': ''},
                                )
                              : null,
                          onChanged: (value) {
                            setState(() {
                              _selectedInstitutionId = value?['id'];
                              _currentNumber = value?['currentNumber'];
                            });
                          },
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                labelText: 'Search',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: 'Institution',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(25),
                                ),
                              ),
                            ),
                          ),
                        ),

                  // Display current number if selected
                  if (_currentNumber != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Current number: $_currentNumber',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Input for user's own queue number
                  TextField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: 'Enter your number (e.g. A123)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_selectedInstitutionId != null &&
                              _numberController.text.isNotEmpty)
                          ? _goToQueuesPage
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.blueAccent,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Done'),
                    ),
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
