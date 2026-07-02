// UserProvider manages the user's profile state, including the virtual chick's name,
// earned stars, and daily mood check-in data. It reactively notifies the UI using 
// ChangeNotifier and persists data locally using SharedPreferences.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  late String _chickName;
  late String _firstName;
  late String _lastName;
  late String _sex;
  late int _age;
  int _stars = 0;
  
  // Date-specific mood check-in data (keyed by yyyy-MM-dd)
  final Map<String, bool> _moodDoneMap = {};
  final Map<String, int> _savedMoodMap = {};
  final Map<String, List<String>> _savedChipsMap = {};

  bool _isLoading = true;
  bool _isDataLoaded = false; // Flag to prevent async race conditions

  // Helper to generate a date string key: yyyy-MM-dd
  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Getters for specific dates
  bool isMoodDoneForDate(DateTime date) {
    return _moodDoneMap[_dateKey(date)] ?? false;
  }

  int getSavedMoodForDate(DateTime date) {
    return _savedMoodMap[_dateKey(date)] ?? -1;
  }

  List<String> getSavedChipsForDate(DateTime date) {
    return _savedChipsMap[_dateKey(date)] ?? [];
  }

  // Calculate average mood rating (1 to 5) for the last N days
  double getAverageMood(int days) {
    int totalMood = 0;
    int count = 0;
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final mood = getSavedMoodForDate(date);
      if (mood != -1) {
        totalMood += (mood + 1); // convert 0-4 index to 1-5 rating
        count++;
      }
    }
    return count > 0 ? totalMood / count : 0.0;
  }

  // Getters for the user data: these allow other parts of the app to access the user data without directly modifying it
  String get chickName => _chickName;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get sex => _sex;
  int get age => _age;
  int get stars => _stars;
  
  // Default to today's values for backward compatibility
  bool get moodDone => isMoodDoneForDate(DateTime.now());
  int get savedMood => getSavedMoodForDate(DateTime.now());
  List<String> get savedChips => getSavedChipsForDate(DateTime.now());
  bool get isLoading => _isLoading;

  // Constructor of the class UserProvider: it calls the loadUserData() method to load the user data from SharedPreferences
  UserProvider() {
    loadUserData();
  }

  // Method that loads the user data from SharedPreferences
  // Method 1: Load data asynchronously from SharedPreferences
  Future<void> loadUserData() async {
    if (_isDataLoaded) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Save the user data to SharedPreferences (local database)
      final sp = await SharedPreferences.getInstance();
      
      // if the user data has not been loaded yet (ulterior check to prevent async race conditions)
      if (!_isDataLoaded) {
        // Get the user data from SharedPreferences
        final name = sp.getString('chickName');
        if (name != null && name.isNotEmpty) {
          _chickName = name;
        }

        final fName = sp.getString('firstName');
        if (fName != null) {
          _firstName = fName;
          _lastName = sp.getString('lastName') ?? '';
          _sex = sp.getString('sex') ?? 'Female';
          _age = sp.getInt('age') ?? 18;
        }
        
        _stars = sp.getInt('stars') ?? 0;
        
        // Load date-specific keys
        final keys = sp.getKeys();
        for (var key in keys) {
          if (key.startsWith('mood_done_')) {
            final dateStr = key.substring('mood_done_'.length);
            _moodDoneMap[dateStr] = sp.getBool(key) ?? false;
          } else if (key.startsWith('saved_mood_')) {
            final dateStr = key.substring('saved_mood_'.length);
            _savedMoodMap[dateStr] = sp.getInt(key) ?? -1;
          } else if (key.startsWith('saved_chips_')) {
            final dateStr = key.substring('saved_chips_'.length);
            _savedChipsMap[dateStr] = sp.getStringList(key) ?? [];
          }
        }

        // Migrate legacy single-day keys to today's date if not already populated
        final todayStr = _dateKey(DateTime.now());
        final legacyMoodDone = sp.getBool('mood_done');
        if (legacyMoodDone != null && !_moodDoneMap.containsKey(todayStr)) {
          _moodDoneMap[todayStr] = legacyMoodDone;
        }
        final legacySavedMood = sp.getInt('saved_mood');
        if (legacySavedMood != null && !_savedMoodMap.containsKey(todayStr)) {
          _savedMoodMap[todayStr] = legacySavedMood;
        }
        final legacySavedChips = sp.getStringList('saved_chips');
        if (legacySavedChips != null && !_savedChipsMap.containsKey(todayStr)) {
          _savedChipsMap[todayStr] = legacySavedChips;
        }
        
        _isDataLoaded = true;
      }

    // Catch the error if something goes wrong
    } catch (e) {
      // Print the error
      debugPrint('Error loading user data in UserProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method 2: Save the user's chick name to SharedPreferences (during onboarding process)
  Future<void> setChickName(String name) async {
    _isDataLoaded = true;
    _chickName = name;
    notifyListeners();

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('chickName', _chickName);
    } catch (e) {
      debugPrint('Error saving chickName in UserProvider: $e');
      // catch the error and print it (gestire eventuali errori)
    }
  }

  // Method to set and save user profile data
  Future<void> setUserProfile(String firstName, String lastName, String sex, int age) async {
    _firstName = firstName;
    _lastName = lastName;
    _sex = sex;
    _age = age;
    notifyListeners();

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('firstName', _firstName);
      await sp.setString('lastName', _lastName);
      await sp.setString('sex', _sex);
      await sp.setInt('age', _age);
    } catch (e) {
      debugPrint('Error saving user profile in UserProvider: $e');
    }
  }

  // Method 3: Save the user's mood and chips/tags (to SharedPreferences)
  // If moodDone is false for the given date, add 5 stars to the user's stars
  // Set moodDone to true for that date
  // Save the user's mood and chips/tags to SharedPreferences
  Future<bool> saveCheckIn(int moodIndex, List<String> chips, {DateTime? date}) async {
    _isDataLoaded = true;
    final targetDate = date ?? DateTime.now();
    final keyStr = _dateKey(targetDate);

    _savedMoodMap[keyStr] = moodIndex;
    _savedChipsMap[keyStr] = chips;
    
    bool coinsAdded = false; // Variable to check if coins have been added
    if (!isMoodDoneForDate(targetDate)) {
      _stars += 5; // Add 5 stars to the user's stars
      _moodDoneMap[keyStr] = true; // Set moodDone to true
      coinsAdded = true; // Set coinsAdded to true
    }
    
    notifyListeners(); // Notify the listeners that the user data has been updated
    
    // Save the user data to SharedPreferences (local database)
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('saved_mood_$keyStr', moodIndex);
      await sp.setStringList('saved_chips_$keyStr', chips);
      if (coinsAdded) {
        await sp.setInt('stars', _stars);
        await sp.setBool('mood_done_$keyStr', true);
      }

      // Legacy fallback keys (only if it is today)
      if (keyStr == _dateKey(DateTime.now())) {
        await sp.setInt('saved_mood', moodIndex);
        await sp.setStringList('saved_chips', chips);
        if (coinsAdded) {
          await sp.setBool('mood_done', true);
        }
      }
    } catch (e) {
      debugPrint('Error saving check-in in UserProvider: $e');
      // catch the error and print it (gestire eventuali errori)
    }

    return coinsAdded;
  }

  // Method to reset the user's data with logout
  Future<void> clearUserData() async {
    // Reset all user data to default values
    _chickName = '';
    _firstName = '';
    _lastName = '';
    _sex = 'Female';
    _age = 0;
    _stars = 0;
    // Clear all date-specific mood check-in data
    _savedMoodMap.clear();
    _savedChipsMap.clear();
    _moodDoneMap.clear();
    // Reset the flags
    _isDataLoaded = false;
    _isLoading = false;

    notifyListeners();

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.clear(); // Clear all data from SharedPreferences
    } catch (e) {
      debugPrint('Error clearing user data in UserProvider: $e');
    }
  }
}