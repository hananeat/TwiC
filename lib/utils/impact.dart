import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/steps.dart';
import '../models/sleep.dart';

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

    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = '${Impact.baseUrl}data/v1/steps/patients/$patientUsername/day/$formattedDate/';
    final headers = {'Authorization': 'Bearer $access'};

    debugPrint('Calling: $url');
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      for (var i = 0; i < decodedResponse['data']['data'].length; i++) {
        result.add(
          Steps.fromJson(
            decodedResponse['data']['date'],
            decodedResponse['data']['data'][i],
          ),
        );
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

    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = '${Impact.baseUrl}data/v1/sleep/patients/$patientUsername/day/$formattedDate/';
    final headers = {'Authorization': 'Bearer $access'};

    debugPrint('Calling: $url');
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      
      // Check if there is data for the requested day
      if (decodedResponse['data']['data'] != null) {
        return Sleep.fromJson(
          decodedResponse['data']['date'],
          decodedResponse['data']['data'],
        );
      }
    } else {
      debugPrint('Error in getSleepData: ${response.statusCode}');
    }
    return null;
  }
  
} // Impact
