import 'package:intl/intl.dart';

class Sleep {
  // Instance variables
  final DateTime date;
  final int minutesAsleep;
  final int efficiency;
  
  // Sleep stage details in minutes
  final int deepMinutes;
  final int wakeMinutes;
  final int lightMinutes;
  final int remMinutes;

  // Constructor
  Sleep({
    required this.date,
    required this.minutesAsleep,
    required this.efficiency,
    required this.deepMinutes,
    required this.wakeMinutes,
    required this.lightMinutes,
    required this.remMinutes,
  });

  // Constructor that converts the API JSON directly into a Sleep object
  Sleep.fromJson(String queryDate, Map<String, dynamic> json)
      : date = DateFormat('yyyy-MM-dd').parse(queryDate),

      // ?? operator = if the value is null, use the value after ??
        minutesAsleep = int.parse(json["minutesAsleep"]?.toString() ?? "0"),
        efficiency = int.parse(json["efficiency"]?.toString() ?? "0"),
        deepMinutes = int.parse(json["levels"]?["summary"]?["deep"]?["minutes"]?.toString() ?? "0"),
        wakeMinutes = int.parse(json["levels"]?["summary"]?["wake"]?["minutes"]?.toString() ?? "0"),
        lightMinutes = int.parse(json["levels"]?["summary"]?["light"]?["minutes"]?.toString() ?? "0"),
        remMinutes = int.parse(json["levels"]?["summary"]?["rem"]?["minutes"]?.toString() ?? "0");

  @override
  String toString() {
    return 'Sleep{date: $date, minutesAsleep: $minutesAsleep, efficiency: $efficiency}';
  }

}
