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
  bool _moodDone = false;
  int _savedMood = -1; // -1 indicates no mood has been saved yet
  List<String> _savedChips = []; // Start with an empty list of chips
  bool _isLoading = true;
  bool _isDataLoaded = false; // Flag to prevent async race conditions

  // Getters for the user data: these allow other parts of the app to access the user data without directly modifying it
  String get chickName => _chickName;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get sex => _sex;
  int get age => _age;
  int get stars => _stars;
  bool get moodDone => _moodDone;
  int get savedMood => _savedMood;
  List<String> get savedChips => _savedChips;
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
        _savedMood = sp.getInt('saved_mood') ?? -1;
        _savedChips = sp.getStringList('saved_chips') ?? [];
        _moodDone = sp.getBool('mood_done') ?? false;
        
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
  // If moodDone is false, add 5 stars to the user's stars
  // Set moodDone to true
  // Save the user's mood and chips/tags to SharedPreferences
  Future<bool> saveCheckIn(int moodIndex, List<String> chips) async {
    _isDataLoaded = true;
    _savedMood = moodIndex; // Save the user's mood (index from 0 to 4)
    _savedChips = chips; // Save the user's chips/tags
    
    bool coinsAdded = false; // Variable to check if coins have been added
    if (!_moodDone) {
      _stars += 5; // Add 5 stars to the user's stars
      _moodDone = true; // Set moodDone to true
      coinsAdded = true; // Set coinsAdded to true
    }
    
    notifyListeners(); // Notify the listeners that the user data has been updated
    
    // Save the user data to SharedPreferences (local database)
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('saved_mood', _savedMood);
      await sp.setStringList('saved_chips', _savedChips);
      // If coins have been added, save them to SharedPreferences
      if (coinsAdded) {
        await sp.setInt('stars', _stars);
        await sp.setBool('mood_done', true);
      }
    } catch (e) {
      debugPrint('Error saving check-in in UserProvider: $e');
      // catch the error and print it (gestire eventuali errori)
    }

    return coinsAdded;
  }
}

