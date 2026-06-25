import 'package:intl/intl.dart';

class Exercise {
  final DateTime timestamp;
  final String activityName;
  final int duration; //in milliseconds

  Exercise({
    required this.timestamp,
    required this.activityName,
    required this.duration,
  });

  Exercise.fromJson(String date, Map<String, dynamic> json)
      : timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$date ${json["time"]}'),
        activityName = json["activityName"].toString(),
        duration = int.parse(json["duration"].toString());

  @override
  String toString() {
    return 'Exercise{timestamp: $timestamp, activityName: $activityName, duration: $duration}';
  }
}
