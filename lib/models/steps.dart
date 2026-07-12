import 'package:intl/intl.dart';

class Steps {
  // Instance variables
  final DateTime timestamp;
  final int value;

  // Constructor
  Steps({required this.timestamp, required this.value});

  // Constructor that converts the API JSON directly into a Steps object
  Steps.fromJson(String date, Map<String, dynamic> json)
      : timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$date ${json["time"]}'),
        // Ensure the value is an integer, even if the API returns it as a string or double (using double parsing to support floating values like 12.0)
        value = double.parse(json["value"].toString()).round();

 @override
  String toString() {
    return 'Steps{timestamp: $timestamp, value: $value}';
  }

}
