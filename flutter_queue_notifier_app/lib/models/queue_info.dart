/// Represents a queue that the user has joined
class QueueInfo {
  final String institutionId; // Unique ID of the institution (e.g., "hospital")
  final String
  institutionName; // Name of the institution (e.g., "City Hospital")
  final String userNumber; // User's queue number (e.g., "A123")
  String currentNumber; // Current number being served (e.g., "A110")
  final DateTime createdAt; // Time when the user joined the queue

  QueueInfo({
    required this.institutionId,
    required this.institutionName,
    required this.userNumber,
    required this.currentNumber,
    required this.createdAt,
  });

  /// Calculates how many people are still ahead in the queue
  int get remainingCount {
    final user = _extractNumber(userNumber);
    final current = _extractNumber(currentNumber);
    return (user - current).clamp(0, 999); // Avoids negative values
  }

  /// Estimates the waiting time in minutes (2 minutes per person)
  int get estimatedWaitMinutes {
    const minutesPerPerson = 2;
    return remainingCount * minutesPerPerson;
  }

  /// Extracts the numeric part from the queue number (e.g., "A123" → 123)
  int _extractNumber(String value) {
    final digits = RegExp(r'\d+').firstMatch(value)?.group(0);
    return int.tryParse(digits ?? '0') ?? 0;
  }

  /// Returns true if the user is 5 numbers away from being served (i.e. 10 minutes left)
  bool get shouldNotify {
    return remainingCount == 5;
  }

  /// Simulates an update of currentNumber based on remaining time
  /// Used for countdown logic when backend value doesn't change
  void updateCurrentNumber(int remainingMinutes) {
    const minutesPerPerson = 2;
    final user = _extractNumber(userNumber);
    final newRemainingCount = (remainingMinutes / minutesPerPerson).ceil();
    final newCurrentNumber = user - newRemainingCount;

    final prefix = RegExp(r'[A-Za-z]+').firstMatch(userNumber)?.group(0) ?? '';
    currentNumber = '$prefix${newCurrentNumber.clamp(0, 999)}';
  }

  /// Creates an instance of QueueInfo from Firebase or local JSON data
  factory QueueInfo.fromMap(
    String id,
    Map<String, dynamic> map,
    String userNumber,
    DateTime createdAt,
  ) {
    return QueueInfo(
      institutionId: id,
      institutionName: map['name'] ?? '',
      userNumber: userNumber,
      currentNumber: map['currentNumber'] ?? '',
      createdAt: createdAt,
    );
  }

  /// Serializes this object to a Map (used for saving in SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'institutionId': institutionId,
      'institutionName': institutionName,
      'userNumber': userNumber,
      'currentNumber': currentNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Returns true if the current number has reached the user's number
  bool get isDone => currentNumber == userNumber;
}
