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
  int _chickXp = 0;
  int _chickLevel = 1;
  int _overflowXp = 0;
  String _lastXpUpdateDate = '';
  String _firstAccessDate = '';
  String _equippedBackground = 'habitat_0';
  String? _equippedAccessory;
  String? _equippedColor;
  Set<String> _ownedItems = {'habitat_0', 'color_0'};
  final Map<String, double> _dailyVitalityMap = {};
  
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
  int get chickXp => _chickXp;
  int get chickLevel => _chickLevel;
  int get overflowXp => _overflowXp;
  String get lastXpUpdateDate => _lastXpUpdateDate;
  String get firstAccessDate => _firstAccessDate;
  String get equippedBackground => _equippedBackground;
  String? get equippedAccessory => _equippedAccessory;
  String? get equippedColor => _equippedColor;
  Set<String> get ownedItems => Set.unmodifiable(_ownedItems);
  
  double getDailyVitalityForDate(DateTime date) {
    return _dailyVitalityMap[_dateKey(date)] ?? 0.0;
  }
  
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
        _chickXp = sp.getInt('chick_xp') ?? 0;
        _chickLevel = sp.getInt('chick_level') ?? 1;
        _overflowXp = sp.getInt('overflow_xp') ?? 0;
        _lastXpUpdateDate = sp.getString('last_xp_update_date') ?? '';
        _firstAccessDate = sp.getString('first_access_date') ?? '';
        _equippedBackground = sp.getString('equipped_background') ?? 'habitat_0';
        _equippedAccessory = sp.getString('equipped_accessory');
        _equippedColor = sp.getString('equipped_color');
        final savedOwned = sp.getStringList('owned_items');
        if (savedOwned != null) {
          _ownedItems = {...savedOwned, 'habitat_0', 'color_0'}; // i default sono sempre sbloccati
        } else {
          _ownedItems = {'habitat_0', 'color_0'};
        }
        if (_firstAccessDate.isEmpty) {
          _firstAccessDate = _dateKey(DateTime.now());
          await sp.setString('first_access_date', _firstAccessDate);
        }
        
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
          } else if (key.startsWith('vitality_')) {
            final dateStr = key.substring('vitality_'.length);
            _dailyVitalityMap[dateStr] = sp.getDouble(key) ?? 0.0;
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
        // Check and process past XP once data is loaded
        await checkAndProcessPastXP();
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

  // Method to update and save the daily vitality score for a given day
  Future<void> updateDailyVitality(String dateKey, double vitality) async {
    // Only update if the value has changed
    if (_dailyVitalityMap[dateKey] == vitality) return;

    _dailyVitalityMap[dateKey] = vitality;
    
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setDouble('vitality_$dateKey', vitality);
    } catch (e) {
      debugPrint('Error saving daily vitality in UserProvider: $e');
    }
    
    // Parse the date from dateKey to use as reference
    DateTime? refDate;
    try {
      final parts = dateKey.split('-');
      refDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {}
    
    // Automatically trigger calculation of past XP
    await checkAndProcessPastXP(currentDate: refDate);
    
    notifyListeners();
  }

  // Scans past days and processes their vitality into XP/Coins
  Future<void> checkAndProcessPastXP({DateTime? currentDate}) async {
    if (_isLoading) return;
    
    final today = DateTime.now();
    final rawReferenceDate = currentDate ?? today;
    
    // Normalize referenceDate to midnight to prevent timezone/hour differences from prematurely finalizing today's XP
    final referenceDate = DateTime(rawReferenceDate.year, rawReferenceDate.month, rawReferenceDate.day);
    
    // If lastXpUpdateDate is empty, initialize it to yesterday so we start tracking from today onwards
    if (_lastXpUpdateDate.isEmpty) {
      final yesterday = referenceDate.subtract(const Duration(days: 1));
      _lastXpUpdateDate = _dateKey(yesterday);
      
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.setString('last_xp_update_date', _lastXpUpdateDate);
      } catch (e) {
        debugPrint('Error setting initial last_xp_update_date: $e');
      }
      return;
    }
    
    DateTime lastDate;
    try {
      final parts = _lastXpUpdateDate.split('-');
      lastDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (e) {
      debugPrint('Error parsing last XP update date: $e');
      lastDate = referenceDate.subtract(const Duration(days: 1));
    }
    
    debugPrint('[TwiC] checkAndProcessPastXP: referenceDate=$referenceDate, _lastXpUpdateDate=$_lastXpUpdateDate, lastDate=$lastDate');
    
    
    // Loop through all days from lastDate + 1 up to yesterday (inclusive) relative to referenceDate
    DateTime processDate = lastDate.add(const Duration(days: 1));
    final yesterday = DateTime(referenceDate.year, referenceDate.month, referenceDate.day).subtract(const Duration(days: 1));
    
    bool updated = false;
    try {
      final sp = await SharedPreferences.getInstance();
      
      while (processDate.isBefore(referenceDate) || (processDate.year == yesterday.year && processDate.month == yesterday.month && processDate.day == yesterday.day)) {
        final key = _dateKey(processDate);
        
        // Get the vitality of that day (default to 0.0 if they didn't log in)
        final dayVitality = _dailyVitalityMap[key] ?? 0.0;
        debugPrint('[TwiC] Loop: processDate=$processDate, key=$key, dayVitality=$dayVitality');
        
        // Process XP for this day
        await _addXPPoints(dayVitality.round(), sp);
        
        _lastXpUpdateDate = key;
        await sp.setString('last_xp_update_date', _lastXpUpdateDate);
        updated = true;
        
        processDate = processDate.add(const Duration(days: 1));
      }
    } catch (e) {
      debugPrint('Error processing past XP: $e');
    }
    
    if (updated) {
      notifyListeners();
    }
  }
  
  // Adds XP points and handles level ups or coin conversions
  Future<void> _addXPPoints(int points, SharedPreferences sp) async {
    if (points <= 0) return;
    
    if (_chickLevel < 6) {
      _chickXp += points;
      
      // Level thresholds:
      // Lvl 1: 0 - 100 XP
      // Lvl 2: 101 - 300 XP
      // Lvl 3: 301 - 600 XP
      // Lvl 4: 601 - 1000 XP
      // Lvl 5: 1001 - 1500 XP
      // Lvl 6: 1501+ XP
      int newLevel = 1;
      if (_chickXp <= 100) {
        newLevel = 1;
      } else if (_chickXp <= 300) {
        newLevel = 2;
      } else if (_chickXp <= 600) {
        newLevel = 3;
      } else if (_chickXp <= 1000) {
        newLevel = 4;
      } else if (_chickXp <= 1500) {
        newLevel = 5;
      } else {
        newLevel = 6;
      }
      
      if (newLevel > _chickLevel) {
        _chickLevel = newLevel;
        await sp.setInt('chick_level', _chickLevel);
      }
      await sp.setInt('chick_xp', _chickXp);
    } else {
      // Level 6 (Adult): convert every 200 XP to 1 star (coin)
      _overflowXp += points;
      if (_overflowXp >= 200) {
        final extraStars = _overflowXp ~/ 200;
        _stars += extraStars;
        _overflowXp = _overflowXp % 200;
        
        await sp.setInt('stars', _stars);
      }
      await sp.setInt('overflow_xp', _overflowXp);
    }
  }

  // Calculates the historical XP, level, and overflow XP of the chick for a given selected date
  Map<String, dynamic> getHistoricalStateForDate(DateTime targetDate) {
    // Normalize targetDate to midnight
    final targetMidnight = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    int level = 1;
    int xp = 0;
    int overflowXp = 0;
    
    if (_firstAccessDate.isEmpty) {
      return {'level': level, 'xp': xp, 'overflowXp': overflowXp};
    }
    
    // Parse first access date
    DateTime firstDate;
    try {
      final parts = _firstAccessDate.split('-');
      firstDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return {'level': level, 'xp': xp, 'overflowXp': overflowXp};
    }
    
    debugPrint('[TwiC] getHistoricalStateForDate: targetMidnight=$targetMidnight, _firstAccessDate=$_firstAccessDate, firstDate=$firstDate');
    
    // If firstDate is after targetMidnight, auto-adjust firstAccessDate to targetMidnight
    if (firstDate.isAfter(targetMidnight)) {
      firstDate = targetMidnight;
      _firstAccessDate = _dateKey(targetMidnight);
      SharedPreferences.getInstance().then((sp) {
        sp.setString('first_access_date', _firstAccessDate);
      });
    }

    // Self-correct firstDate if there are earlier records in the daily vitality map (e.g. from past system clock shifts)
    DateTime earliestRecorded = firstDate;
    for (final key in _dailyVitalityMap.keys) {
      try {
        final parts = key.split('-');
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        if (date.isBefore(earliestRecorded)) {
          earliestRecorded = date;
        }
      } catch (_) {}
    }
    
    if (earliestRecorded.isBefore(firstDate)) {
      firstDate = earliestRecorded;
      _firstAccessDate = _dateKey(firstDate);
      SharedPreferences.getInstance().then((sp) {
        sp.setString('first_access_date', _firstAccessDate);
      });
    }
    
    // Loop through all days from firstDate up to targetMidnight (inclusive)
    DateTime processDate = firstDate;
    
    // Only count days strictly before the target date:
    // a day's vitality is converted to XP starting the next day.
    while (processDate.isBefore(targetMidnight)) {
      final key = _dateKey(processDate);
      final dayVitality = _dailyVitalityMap[key] ?? 0.0;
      final points = dayVitality.round();
      debugPrint('HistLoop: processDate=$processDate, key=$key, dayVitality=$dayVitality, points=$points');
      
      if (points > 0) {
        if (level < 6) {
          xp += points;
          if (xp <= 100) {
            level = 1;
          } else if (xp <= 300) {
            level = 2;
          } else if (xp <= 600) {
            level = 3;
          } else if (xp <= 1000) {
            level = 4;
          } else if (xp <= 1500) {
            level = 5;
          } else {
            level = 6;
          }
        } else {
          overflowXp += points;
          if (overflowXp >= 200) {
            overflowXp = overflowXp % 200;
          }
        }
      }
      
      processDate = processDate.add(const Duration(days: 1));
    }
    
    return {'level': level, 'xp': xp, 'overflowXp': overflowXp};
  }

  // Claim goal rewards and save the claimed flags directly to SharedPreferences
  Future<void> claimGoalRewards(
    String dateKey, {
    required bool stepsDone,
    required bool sleepDone,
    required bool exerciseDone,
    required int stepsPoints,
    required int sleepPoints,
    required int exercisePoints,
  }) async {
    if (_isLoading) return;

    final sp = await SharedPreferences.getInstance();
    bool updated = false;

    if (stepsDone) {
      final key = 'goal_claimed_${dateKey}_steps';
      if (!(sp.getBool(key) ?? false)) {
        _stars += stepsPoints;
        await sp.setBool(key, true);
        updated = true;
      }
    }

    if (sleepDone) {
      final key = 'goal_claimed_${dateKey}_sleep';
      if (!(sp.getBool(key) ?? false)) {
        _stars += sleepPoints;
        await sp.setBool(key, true);
        updated = true;
      }
    }

    if (exerciseDone) {
      final key = 'goal_claimed_${dateKey}_exercise';
      if (!(sp.getBool(key) ?? false)) {
        _stars += exercisePoints;
        await sp.setBool(key, true);
        updated = true;
      }
    }

    if (updated) {
      await sp.setInt('stars', _stars);
      notifyListeners();
    }
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
    _chickXp = 0;
    _chickLevel = 1;
    _overflowXp = 0;
    _lastXpUpdateDate = '';
    _firstAccessDate = '';
    _dailyVitalityMap.clear();
    
    // Clear all date-specific mood check-in data
    _savedMoodMap.clear();
    _savedChipsMap.clear();
    _moodDoneMap.clear();
    // Reset the flags
    _isDataLoaded = false;
    _isLoading = false;

    notifyListeners();

    try {
      // Non cancelliamo l'intero database locale (SharedPreferences) al logout
      // per preservare il nome del pulcino e i progressi di gioco dell'utente.
      // I token di sessione vengono già rimossi separatamente tramite deleteTokens().
    } catch (e) {
      debugPrint('Error clearing user data in UserProvider: $e');
    }
  }

// Method to buy an item with stars 

Future<void> buyItem(String itemId, int price) async {
  if (_stars < price) return;
  _stars -= price;
  _ownedItems.add(itemId);
  final sp = await SharedPreferences.getInstance();
  await sp.setInt('stars', _stars);
  await sp.setStringList('owned_items', _ownedItems.toList());
  notifyListeners();
}

Future<void> equipBackground(String itemId) async {
  _equippedBackground = itemId;
  final sp = await SharedPreferences.getInstance();
  await sp.setString('equipped_background', itemId);
  notifyListeners();
}

Future<void> equipAccessory(String? itemId) async {
  _equippedAccessory = itemId;
  final sp = await SharedPreferences.getInstance();
  if (itemId != null) {
    await sp.setString('equipped_accessory', itemId);
  } else {
    await sp.remove('equipped_accessory');
  }
  notifyListeners();
}

Future<void> equipColor(String? itemId) async {
  _equippedColor = itemId == 'color_0' ? null : itemId;
  final sp = await SharedPreferences.getInstance();
  if (_equippedColor != null) {
    await sp.setString('equipped_color', _equippedColor!);
  } else {
    await sp.remove('equipped_color');
  }
  notifyListeners();
}
}