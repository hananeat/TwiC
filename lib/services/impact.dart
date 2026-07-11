import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/steps.dart';
import '../models/sleep.dart';
import '../models/exercises.dart';

class Impact {

  static String baseUrl = 'https://impact.dei.unipd.it/bwthw/';
  static String pingEndpoint = 'gate/v1/ping/';
  static String tokenEndpoint = 'gate/v1/token/';
  static String refreshEndpoint = 'gate/v1/refresh/';
  static String patientUsername = 'Jpefaq6m58'; // Username of the patient

  // This method allows to refresh the stored JWT in SharedPreferences
  Future<int> refreshTokens() async {
    // Create the request
    final url = Impact.baseUrl + Impact.refreshEndpoint;
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refresh');
    if (refresh != null) {
      final body = {'refresh': refresh};

      // Get the response
      debugPrint('Calling: $url');
      final response = await http.post(Uri.parse(url), body: body);

      // If the response is OK, set the tokens in SharedPreferences to the new values
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final sp = await SharedPreferences.getInstance();
        await sp.setString('access', decodedResponse['access']);
        await sp.setString('refresh', decodedResponse['refresh']);
      } // if

      // Just return the status code
      return response.statusCode;
    }
    return 401;
  } // _refreshTokens

  Future<int> getAndStoreTokens(String username, String password) async {
    // Create the request
    final url = Impact.baseUrl + Impact.tokenEndpoint;
    final body = {'username': username, 'password': password};

    // Get the response
    debugPrint('Calling: $url');
    final response = await http.post(Uri.parse(url), body: body);

    // If response is OK, decode it and store the tokens. Otherwise do nothing.
    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString('access', decodedResponse['access']);
      await sp.setString('refresh', decodedResponse['refresh']);
    } // if

    // Just return the status code
    return response.statusCode;
  } // _getAndStoreTokens

  Future<void> deleteTokens() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('access');
    await sp.remove('refresh');
  } // deleteTokens

  // ============================
  //      STEPS DATA
  // ============================
  // This method allows to get the steps data from the Impact server
  Future<List<Steps>> getStepsData(DateTime date) async {
    List<Steps> result = [];
    final sp = await SharedPreferences.getInstance();
    var access = sp.getString('access');

    // Se il token è scaduto o nullo, lo aggiorna prima di inviare la richiesta
    if (access == null || JwtDecoder.isExpired(access)) {
      await refreshTokens();
      access = sp.getString('access');
    }

    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = '${Impact.baseUrl}data/v1/steps/patients/$patientUsername/day/$formattedDate/';
    final headers = {'Authorization': 'Bearer $access'};

    debugPrint('Calling: $url');
    final response = await http.get(Uri.parse(url), headers: headers);
    debugPrint('Steps response status: ${response.statusCode}');
    debugPrint('Steps response body: ${response.body}');

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      if (decodedResponse['data'] is Map && decodedResponse['data']['data'] != null) {
        final stepsList = decodedResponse['data']['data'] as List;
        for (var i = 0; i < stepsList.length; i++) {
          result.add(
            Steps.fromJson(
              decodedResponse['data']['date'].toString(),
              stepsList[i],
            ),
          );
        }
      }
    } else {
      debugPrint('Error in getStepsData: ${response.statusCode}');
    }
    return result;
  }

  // ============================
  //      SLEEP DATA
  // ============================
  // This method allows to get the sleep data from the Impact server
  Future<Sleep?> getSleepData(DateTime date) async {
    final sp = await SharedPreferences.getInstance();
    var access = sp.getString('access');

    // Se il token è scaduto o nullo, lo aggiorna prima di inviare la richiesta
    if (access == null || JwtDecoder.isExpired(access)) {
      await refreshTokens();
      access = sp.getString('access');
    }

    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = '${Impact.baseUrl}data/v1/sleep/patients/$patientUsername/day/$formattedDate/';
    final headers = {'Authorization': 'Bearer $access'};

    debugPrint('Calling: $url');
    final response = await http.get(Uri.parse(url), headers: headers);
    debugPrint('Sleep response status: ${response.statusCode}');
    debugPrint('Sleep response body: ${response.body}');

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      
      // Check if there is data for the requested day
      if (decodedResponse['data'] is Map && decodedResponse['data']['data'] != null) {
        return Sleep.fromJson(
          decodedResponse['data']['date'].toString(),
          decodedResponse['data']['data'],
        );
      }
    } else {
      debugPrint('Error in getSleepData: ${response.statusCode}');
    }
    return null;
  }
  
  // ============================
  //      ExERCISE DATA
  // ============================
  // This method allows to get the exercise data from the Impact server
  Future<List<Exercise>> getExerciseData(DateTime date) async {
    List<Exercise> result = [];  
    final sp = await SharedPreferences.getInstance();
    var access = sp.getString('access');

    // Se il token è scaduto o nullo, lo aggiorna prima di inviare la richiesta
    if (access == null || JwtDecoder.isExpired(access)) {
      await refreshTokens();
      access = sp.getString('access');
    }

    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = '${Impact.baseUrl}data/v1/exercise/patients/$patientUsername/day/$formattedDate/';
    final headers = {'Authorization': 'Bearer $access'};

    debugPrint('Calling: $url');
    final response = await http.get(Uri.parse(url), headers: headers);
    debugPrint('Exercise response status: ${response.statusCode}');
    debugPrint('Exercise response body: ${response.body}');

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      
      //check if there are exercises for the requested day
      if (decodedResponse['data'] is Map && decodedResponse['data']['data'] != null) {
        final exerciseList = decodedResponse['data']['data'] as List;
        for (var i = 0; i < exerciseList.length; i++) {
          result.add(
            Exercise.fromJson(
              decodedResponse['data']['date'].toString(),
              exerciseList[i],
            ),
          );
        }
      }
    } else {
      debugPrint('Error in getExerciseData: ${response.statusCode}');
    }
    return result;
  }
  
} // Impact