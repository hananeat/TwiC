import 'package:flutter/material.dart';
import '../models/steps.dart';
import '../models/sleep.dart';
import '../models/exercises.dart';
import '../services/impact.dart';

class HealthDataProvider extends ChangeNotifier {
  final Impact _impact = Impact();

  List<Steps> _stepsData = [];
  Sleep? _sleepData;
  List<Exercise> _exerciseData = [];

  bool _isLoading = false;
  DateTime _currentDate = DateTime.now(); // Default to today

  // Getters
  List<Steps> get stepsData => _stepsData;
  Sleep? get sleepData => _sleepData;
  List<Exercise> get exerciseData => _exerciseData;
  bool get isLoading => _isLoading;
  DateTime get currentDate => _currentDate;

  // Aggregated metrics calculation for the selected date
  int get totalSteps {
    return _stepsData.fold(0, (sum, item) => sum + item.value);
  }

  int get totalSleepMinutes {
    return _sleepData?.minutesAsleep ?? 0;
  }

  int get totalExerciseSessions {
    return _exerciseData.length;
  }

  // Method to fetch all the data for the selected date in parallel
  Future<void> fetchDataOfDay(DateTime date) async {
    _currentDate = date;
    _isLoading = true;
    
    // Clear previous data to prevent stale data from ghosting if the new request fails or has no data
    _stepsData = [];
    _sleepData = null;
    _exerciseData = [];
    
    notifyListeners();

    // Year shift: to fetch data for the selected date
    final queryDate = DateTime(date.year - 1, date.month, date.day);

    try {
      // Parallel calls to IMPACT with queryDate
      final results = await Future.wait([
        _impact.getStepsData(queryDate),
        _impact.getSleepData(queryDate),
        _impact.getExerciseData(queryDate),
      ]);

      _stepsData = results[0] as List<Steps>;
      _sleepData = results[1] as Sleep?;
      _exerciseData = results[2] as List<Exercise>;
    } catch (e) {
      debugPrint('Error in data retrieval for the dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
