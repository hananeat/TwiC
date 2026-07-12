import 'package:flutter/material.dart';
import '../models/steps.dart';
import '../models/sleep.dart';
import '../models/exercises.dart';
import '../services/impact.dart';

// HealthDataProvider is a ChangeNotifier that manages the fetching and storage
// of daily health data (steps, sleep, exercise) from the IMPACT backend API.
// It serves as the central data source for the homepage dashboard, exposing
// aggregated metrics (total steps, sleep minutes, exercise sessions) and
// notifying the UI whenever new data is loaded or the loading state changes.

class HealthDataProvider extends ChangeNotifier {
  final Impact _impact = Impact(); // call Impact API
  List<Steps> _stepsData = []; // list of steps data for the selected date
  Sleep? _sleepData; // sleep data for the selected date (nullable because sometimes the data may not be available)
  List<Exercise> _exerciseData = []; // list of exercise data for the selected date

  bool _isLoading = false; // flag to indicate if the data is loading
  DateTime _currentDate = DateTime.now(); // date selected by the user (default to today)

  // Getters: public read-only properties for accessing the private data
  List<Steps> get stepsData => _stepsData;
  Sleep? get sleepData => _sleepData;
  List<Exercise> get exerciseData => _exerciseData;
  bool get isLoading => _isLoading;
  DateTime get currentDate => _currentDate;

  // Aggregated metrics calculation for the selected date
  // totalSteps: total number of steps for the selected date
  int get totalSteps {
    return _stepsData.fold(0, (sum, item) => sum + item.value);
  }

  // totalSleepMinutes: total number of minutes of sleep for the selected date
  int get totalSleepMinutes {
    return _sleepData?.minutesAsleep ?? 0;
  }

  // totalExerciseSessions: total number of exercise sessions for the selected date
  int get totalExerciseSessions {
    return _exerciseData.length;
  }

  // Async method to fetch all the data for the selected date
  Future<void> fetchDataOfDay(DateTime date) async {
    _currentDate = date; // update the selected date
    _isLoading = true; // set loading to true
    
    // Clear previous data to prevent stale data from ghosting if the new request fails or has no data
    _stepsData = [];
    _sleepData = null;
    _exerciseData = [];
    
    // Notify listeners that the data is loading (_isLoading = true) and clear old data before loading new data
    notifyListeners();

    // Year shift: to fetch data for the selected date
    final queryDate = DateTime(date.year - 1, date.month, date.day);

    // 3 API calls in parallel (Future.wait) to reduce waiting time:
    try {
      final results = await Future.wait([
        _impact.getStepsData(queryDate),
        _impact.getSleepData(queryDate),
        _impact.getExerciseData(queryDate),
      ]);

      _stepsData = results[0] as List<Steps>;
      _sleepData = results[1] as Sleep?;
      _exerciseData = results[2] as List<Exercise>;

    //if one of the calls fails, it catchs the exception and prints the error message
    } catch (e) {
      debugPrint('Error in data retrieval for the dashboard: $e');
    } finally {
      // Set loading to false and notify listeners that the data has been loaded
      _isLoading = false;
      notifyListeners();
    }
  }
}
