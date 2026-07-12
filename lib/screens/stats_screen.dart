/// StatsScreen displays aggregated health statistics (steps, sleep, heart rate, mood)
/// with three sub-tabs: Week, Month, and Trend.
/// Data is fetched from the IMPACT backend API for the last 30 days.
library;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/impact.dart';
import '../providers/user_provider.dart';
import 'package:TwiC/utils/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Currently selected sub-tab: 'Week', 'Month', or 'Trend'
  String _subTab = 'Week';
  // Whether the data is still being loaded from the API
  bool _isLoading = true;
  // Error message to display if data fetching fails
  String _errorMessage = '';

  // Maps storing raw fetched data keyed by date
  // Total steps per day
  final Map<DateTime, int> _stepsData = {};
  // Total sleep minutes per day
  final Map<DateTime, int> _sleepData = {};
  // List of heart rate readings per day
  final Map<DateTime, List<int>> _hrData = {};

  // Weekly averages (last 7 days)
  double _weekAvgSteps = 0;
  double _weekAvgSleepMinutes = 0;
  double _weekAvgHR = 0;
  double _weekAvgRestingHR = 0;

  // Monthly averages (last 30 days)
  double _monthAvgSteps = 0;
  double _monthAvgSleepMinutes = 0;
  double _monthAvgHR = 0;
  double _monthAvgRestingHR = 0;

  // Trend percentages
  // Percentage change between the first half (days 0-14) and the second half (days 15-29)
  double _stepsTrend = 0;
  double _sleepTrend = 0;
  // Resting HR trend is expressed as an absolute bpm difference, not a percentage
  double _restingHRTrend = 0;

  @override
  void initState() {
    super.initState();
    _fetchStatsData();
  }

  // Helper method to strip the time component from a DateTime,
  // keeping only year, month, and day for consistent date comparisons
  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Attempts to refresh the expired access token using the stored refresh token.
  // Returns true if the refresh was successful, false otherwise.
  Future<bool> _refreshAccessToken() async {
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refresh');
    if (refresh == null) return false;

    try {
      final url = '${Impact.baseUrl}${Impact.refreshEndpoint}';
      debugPrint('Refreshing tokens: $url');
      final response = await http.post(
        Uri.parse(url),
        body: {'refresh': refresh},
      );
      if (response.statusCode == 200) {
        // Store the new access and refresh tokens
        final decodedResponse = jsonDecode(response.body);
        await sp.setString('access', decodedResponse['access']);
        await sp.setString('refresh', decodedResponse['refresh']);
        return true;
      }
    } catch (e) {
      debugPrint('Error refreshing access token: $e');
    }
    return false;
  }

  // Orchestrates the fetching of the last 30 days of health data from IMPACT.
  // It fetches all days in parallel, handles 401 (unauthorized) errors by
  // refreshing the token and retrying, and delegates processing to _processResults.
  Future<void> _fetchStatsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final sp = await SharedPreferences.getInstance();
      var access = sp.getString('access');
      // If no access token is stored, prompt the user to log in
      if (access == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No access token found. Please log in.';
        });
        return;
      }

      // Generate a list of 30 dates ending yesterday (today's data may be incomplete)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dates = List.generate(
        30,
        (i) => _dateOnly(yesterday.subtract(Duration(days: i))),
      );

      // Perform all 30 day-requests in parallel for faster loading
      final results = await Future.wait(
        dates.map((date) => _fetchDayData(date, access)),
      );

      // Check if any request returned a 401 (unauthorized) status
      final hasUnauthorized = results.any((r) => r == 401);
      if (hasUnauthorized) {
        debugPrint('401 response detected. Trying to refresh token...');
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry all requests with the new access token
          final newAccess = sp.getString('access');
          if (newAccess != null) {
            final retryResults = await Future.wait(
              dates.map((date) => _fetchDayData(date, newAccess)),
            );
            _processResults(dates, retryResults);
            return;
          }
        }
        // If token refresh failed, show session expired message
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired. Please log in again.';
        });
      } else {
        // All requests succeeded, process the results
        _processResults(dates, results);
      }
    } catch (e) {
      debugPrint('Error in _fetchStatsData: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred while loading data: $e';
      });
    }
  }

  // Fetches steps, sleep, and heart rate data for a single date from the IMPACT API.
  // Returns a Map with 'steps', 'sleep', and 'hr' keys, or 401 if unauthorized.
  // Note: the query date is shifted back by 1 year to align with the 2025 database.
  Future<dynamic> _fetchDayData(DateTime date, String access) async {
    // Shift by 365 days to align with the 2025 IMPACT database
    final queryDate = DateTime(date.year - 1, date.month, date.day);
    final formattedDate = DateFormat('yyyy-MM-dd').format(queryDate);
    final patient = Impact.patientUsername;
    final headers = {'Authorization': 'Bearer $access'};

    // Build the API endpoint URLs for steps, sleep, and heart rate
    final stepsUrl = '${Impact.baseUrl}data/v1/steps/patients/$patient/day/$formattedDate/';
    final sleepUrl = '${Impact.baseUrl}data/v1/sleep/patients/$patient/day/$formattedDate/';
    final hrUrl = '${Impact.baseUrl}data/v1/heart_rate/patients/$patient/day/$formattedDate/';

    try {
      // Fetch all three endpoints in parallel for the same day
      final responses = await Future.wait([
        http.get(Uri.parse(stepsUrl), headers: headers),
        http.get(Uri.parse(sleepUrl), headers: headers),
        http.get(Uri.parse(hrUrl), headers: headers),
      ]);

      final stepsResp = responses[0];
      final sleepResp = responses[1];
      final hrResp = responses[2];

      // If any endpoint returns 401, signal the caller to refresh the token
      if (stepsResp.statusCode == 401 || sleepResp.statusCode == 401 || hrResp.statusCode == 401) {
        return 401;
      }

      // Sum all step values from the intraday data list
      int stepsVal = 0;
      if (stepsResp.statusCode == 200) {
        final body = jsonDecode(stepsResp.body);
        if (body['data'] is Map && body['data']['data'] != null) {
          final list = body['data']['data'] as List;
          stepsVal = list.fold<int>(0, (sum, item) {
            final val = double.tryParse(item['value']?.toString() ?? '0')?.round() ?? 0;
            return sum + val;
          });
        }
      }

      // Extract the total minutes asleep from the sleep summary
      int sleepMinutes = 0;
      if (sleepResp.statusCode == 200) {
        final body = jsonDecode(sleepResp.body);
        if (body['data'] is Map && body['data']['data'] != null) {
          final data = body['data']['data'];
          sleepMinutes = int.tryParse(data['minutesAsleep']?.toString() ?? '0') ?? 0;
        }
      }

      // Collect all individual heart rate readings into a list
      List<int> hrList = [];
      if (hrResp.statusCode == 200) {
        final body = jsonDecode(hrResp.body);
        debugPrint('RAW HR RESPONSE FOR DATE $formattedDate: ${hrResp.body}');
        if (body['data'] is Map && body['data']['data'] != null) {
          final list = body['data']['data'] as List;
          for (var item in list) {
            final val = int.tryParse(item['value']?.toString() ?? '');
            if (val != null) {
              hrList.add(val);
            }
          }
        }
      }

      return {
        'steps': stepsVal,
        'sleep': sleepMinutes,
        'hr': hrList,
      };
    } catch (e) {
      debugPrint('Error fetching data for date $formattedDate: $e');
      // Return zero values on error so the day is simply skipped in averages
      return {
        'steps': 0,
        'sleep': 0,
        'hr': <int>[],
      };
    }
  }

  // Processes the raw fetched results and computes weekly averages, monthly averages,
  // and trend percentages. Updates the state variables and triggers a UI rebuild.
  void _processResults(List<DateTime> dates, List<dynamic> results) {
    // Clear previous data before repopulating
    _stepsData.clear();
    _sleepData.clear();
    _hrData.clear();

    // Populate the data maps from the fetched results
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final res = results[i];
      if (res is Map) {
        _stepsData[date] = res['steps'] ?? 0;
        _sleepData[date] = res['sleep'] ?? 0;
        _hrData[date] = List<int>.from(res['hr'] ?? []);
      }
    }

    // --- WEEKLY STATS (indices 0-6, i.e. the most recent 7 days) ---
    int weekStepsDays = 0;     // Number of days with valid steps data
    int weekTotalSteps = 0;    // Cumulative steps over the week
    int weekSleepDays = 0;     // Number of days with valid sleep data
    int weekTotalSleep = 0;    // Cumulative sleep minutes over the week
    List<int> weekAllHR = [];  // All HR readings aggregated across the week
    List<double> weekRestingHRs = []; // Resting HR estimate per day

    for (int i = 0; i < 7; i++) {
      final date = dates[i];
      final steps = _stepsData[date] ?? 0;
      // Only count days that have actual step data (steps > 0)
      if (steps > 0) {
        weekTotalSteps += steps;
        weekStepsDays++;
      }

      final sleep = _sleepData[date] ?? 0;
      // Only count days that have actual sleep data (sleep > 0)
      if (sleep > 0) {
        weekTotalSleep += sleep;
        weekSleepDays++;
      }

      final hrList = _hrData[date] ?? [];
      if (hrList.isNotEmpty) {
        weekAllHR.addAll(hrList);
        // Resting Heart Rate proxy: average of the bottom 5% of HR readings.
        // This approximates the resting heart rate by taking the lowest values.
        final sorted = List<int>.from(hrList)..sort();
        final limit = (sorted.length * 0.05).clamp(1, sorted.length).toInt();
        final lowest = sorted.take(limit);
        final dayResting = lowest.fold<int>(0, (sum, val) => sum + val) / limit;
        weekRestingHRs.add(dayResting);
      }
    }

    // Compute weekly averages (avoid division by zero)
    _weekAvgSteps = weekStepsDays > 0 ? weekTotalSteps / weekStepsDays : 0;
    _weekAvgSleepMinutes = weekSleepDays > 0 ? weekTotalSleep / weekSleepDays : 0;
    _weekAvgHR = weekAllHR.isNotEmpty ? weekAllHR.reduce((a, b) => a + b) / weekAllHR.length : 0;
    _weekAvgRestingHR = weekRestingHRs.isNotEmpty ? weekRestingHRs.reduce((a, b) => a + b) / weekRestingHRs.length : 0;

    // --- MONTHLY STATS (all 30 days) ---
    int monthStepsDays = 0;
    int monthTotalSteps = 0;
    int monthSleepDays = 0;
    int monthTotalSleep = 0;
    List<int> monthAllHR = [];
    List<double> monthRestingHRs = [];

    for (int i = 0; i < 30; i++) {
      final date = dates[i];
      final steps = _stepsData[date] ?? 0;
      if (steps > 0) {
        monthTotalSteps += steps;
        monthStepsDays++;
      }

      final sleep = _sleepData[date] ?? 0;
      if (sleep > 0) {
        monthTotalSleep += sleep;
        monthSleepDays++;
      }

      final hrList = _hrData[date] ?? [];
      if (hrList.isNotEmpty) {
        monthAllHR.addAll(hrList);
        // Same resting HR proxy as the weekly calculation (bottom 5%)
        final sorted = List<int>.from(hrList)..sort();
        final limit = (sorted.length * 0.05).clamp(1, sorted.length).toInt();
        final lowest = sorted.take(limit);
        final dayResting = lowest.fold<int>(0, (sum, val) => sum + val) / limit;
        monthRestingHRs.add(dayResting);
      }
    }

    // Compute monthly averages (avoid division by zero)
    _monthAvgSteps = monthStepsDays > 0 ? monthTotalSteps / monthStepsDays : 0;
    _monthAvgSleepMinutes = monthSleepDays > 0 ? monthTotalSleep / monthSleepDays : 0;
    _monthAvgHR = monthAllHR.isNotEmpty ? monthAllHR.reduce((a, b) => a + b) / monthAllHR.length : 0;
    _monthAvgRestingHR = monthRestingHRs.isNotEmpty ? monthRestingHRs.reduce((a, b) => a + b) / monthRestingHRs.length : 0;

    // --- TREND CALCULATION ---
    // Compares the first half (h1 = days 0-14, most recent) vs the second half (h2 = days 15-29, older)
    // to determine whether the user's metrics are improving or declining
    double h1Steps = 0;
    int h1StepsDays = 0;
    double h2Steps = 0;
    int h2StepsDays = 0;

    double h1Sleep = 0;
    int h1SleepDays = 0;
    double h2Sleep = 0;
    int h2SleepDays = 0;

    List<double> h1Resting = []; // Resting HR values for the recent half
    List<double> h2Resting = []; // Resting HR values for the older half

    // First half: the most recent 15 days (days 0-14)
    for (int i = 0; i < 15; i++) {
      final date = dates[i];
      final st = _stepsData[date] ?? 0;
      if (st > 0) {
        h1Steps += st;
        h1StepsDays++;
      }
      final sl = _sleepData[date] ?? 0;
      if (sl > 0) {
        h1Sleep += sl;
        h1SleepDays++;
      }
      final hr = _hrData[date] ?? [];
      if (hr.isNotEmpty) {
        final sorted = List<int>.from(hr)..sort();
        final limit = (sorted.length * 0.05).clamp(1, sorted.length).toInt();
        h1Resting.add(sorted.take(limit).reduce((a, b) => a + b) / limit);
      }
    }

    // Second half: the older 15 days (days 15-29)
    for (int i = 15; i < 30; i++) {
      final date = dates[i];
      final st = _stepsData[date] ?? 0;
      if (st > 0) {
        h2Steps += st;
        h2StepsDays++;
      }
      final sl = _sleepData[date] ?? 0;
      if (sl > 0) {
        h2Sleep += sl;
        h2SleepDays++;
      }
      final hr = _hrData[date] ?? [];
      if (hr.isNotEmpty) {
        final sorted = List<int>.from(hr)..sort();
        final limit = (sorted.length * 0.05).clamp(1, sorted.length).toInt();
        h2Resting.add(sorted.take(limit).reduce((a, b) => a + b) / limit);
      }
    }

    // Steps trend: percentage change from the older half to the recent half
    final avgH1Steps = h1StepsDays > 0 ? h1Steps / h1StepsDays : 0;
    final avgH2Steps = h2StepsDays > 0 ? h2Steps / h2StepsDays : 0;
    _stepsTrend = avgH2Steps > 0 ? ((avgH1Steps - avgH2Steps) / avgH2Steps) * 100 : 0;

    // Sleep trend: percentage change from the older half to the recent half
    final avgH1Sleep = h1SleepDays > 0 ? h1Sleep / h1SleepDays : 0;
    final avgH2Sleep = h2SleepDays > 0 ? h2Sleep / h2SleepDays : 0;
    _sleepTrend = avgH2Sleep > 0 ? ((avgH1Sleep - avgH2Sleep) / avgH2Sleep) * 100 : 0;

    // Resting HR trend: absolute bpm difference (positive = increase, negative = decrease)
    final avgH1Resting = h1Resting.isNotEmpty ? h1Resting.reduce((a, b) => a + b) / h1Resting.length : 0.0;
    final avgH2Resting = h2Resting.isNotEmpty ? h2Resting.reduce((a, b) => a + b) / h2Resting.length : 0.0;
    _restingHRTrend = avgH2Resting > 0 ? (avgH1Resting - avgH2Resting).toDouble() : 0.0;

    // Data processing complete, trigger UI rebuild
    setState(() {
      _isLoading = false;
    });
  }

  // Helper method to format sleep minutes into a human-readable string (e.g. "7h 30m")
  String _formatSleepMinutes(double minutes) {
    if (minutes == 0) return '0m';
    final hrs = minutes ~/ 60;
    final mins = (minutes % 60).round();
    return hrs > 0 ? '${hrs}h ${mins}m' : '${mins}m';
  }

  // Returns a Map of display strings for the currently selected sub-tab.
  // Each key corresponds to a UI element: title, steps, sleep, mood, coins,
  // correlation card title/subtitle, and heart rate card title/subtitle.
  Map<String, String> getMetrics(UserProvider userProvider) {
    // Get average mood from the UserProvider for both weekly and monthly periods
    final weekAvgMood = userProvider.getAverageMood(7);
    final monthAvgMood = userProvider.getAverageMood(30);
    
    // Format mood values as display strings
    final weekMoodStr = weekAvgMood > 0 ? '${weekAvgMood.toStringAsFixed(1)} / 5' : 'N/A';
    final monthMoodStr = monthAvgMood > 0 ? '${monthAvgMood.toStringAsFixed(1)} / 5' : 'N/A';
    // For the trend tab, mood is categorized as Good (≥3.5), Stable (≥2.5), or Low (<2.5)
    final trendMoodStr = monthAvgMood > 0 ? (monthAvgMood >= 3.5 ? 'Good' : (monthAvgMood >= 2.5 ? 'Stable' : 'Low')) : 'N/A';

    // Total stars (coins) earned by the user
    final coinsStr = userProvider.stars.toString();

    // Return different metrics depending on the selected sub-tab
    switch (_subTab) {
      case 'Month':
        return {
          'title': 'THIS MONTH',
          'passi': _monthAvgSteps > 0 ? NumberFormat('#,###', 'en_US').format(_monthAvgSteps.round()) : 'N/A',
          'sonno': _formatSleepMinutes(_monthAvgSleepMinutes),
          'mood': monthMoodStr,
          'monete': '+$coinsStr',
          'corrTitle': 'Monthly Correlation',
          'corrSub': _monthAvgSteps > 0
              ? 'With a steps average of ${NumberFormat('#,###', 'en_US').format(_monthAvgSteps.round())}, your resting heart rate is ${_monthAvgRestingHR.round()} bpm.'
              : 'Take more steps to track the impact on your resting heart rate.',
          'freqTitle': 'Resting Heart Rate',
          'freqSub': _monthAvgRestingHR > 0
              ? '${_monthAvgRestingHR.round()} bpm this month - based on your average resting heart rate.'
              : 'No data this month.',
        };
      case 'Trend':
        // Add a '+' sign prefix for positive trend values
        final stepsSign = _stepsTrend >= 0 ? '+' : '';
        final sleepSign = _sleepTrend >= 0 ? '+' : '';
        // Build a descriptive text for the HR trend direction
        final hrTrendText = _restingHRTrend > 0
            ? 'increasing by ${_restingHRTrend.toStringAsFixed(1)} bpm compared to before.'
            : _restingHRTrend < 0
                ? 'decreasing by ${(_restingHRTrend * -1).toStringAsFixed(1)} bpm compared to before.'
                : 'stable compared to before.';

        return {
          'title': 'GENERAL TRENDS',
          'passi': '$stepsSign${_stepsTrend.toStringAsFixed(1)}% / month',
          'sonno': '$sleepSign${_sleepTrend.toStringAsFixed(1)}% / month',
          'mood': trendMoodStr,
          'monete': '$coinsStr tot',
          'corrTitle': 'General Progress',
          'corrSub': _sleepTrend > 0
              ? 'Your sleep improved by ${_sleepTrend.toStringAsFixed(1)}% compared to the beginning of the month.'
              : 'Try to regulate your sleep schedule to improve your trend.',
          'freqTitle': 'Heart Rate',
          'freqSub': _monthAvgRestingHR > 0
              ? 'Your resting heart rate is $hrTrendText'
              : 'Insufficient data to calculate trend.',
        };
      case 'Week':
      default:
        return {
          'title': 'THIS WEEK',
          'passi': _weekAvgSteps > 0 ? NumberFormat('#,###', 'en_US').format(_weekAvgSteps.round()) : 'N/A',
          'sonno': _formatSleepMinutes(_weekAvgSleepMinutes),
          'mood': weekMoodStr,
          'monete': '+$coinsStr',
          'corrTitle': 'Correlation Detected',
          'corrSub': _weekAvgSleepMinutes > 360
              ? 'On days with 6h+ of sleep, your average physical activity level improved.'
              : 'Sleeping enough helps you have more energy to walk.',
          'freqTitle': 'Resting Heart Rate',
          'freqSub': _weekAvgRestingHR > 0
              ? '${_weekAvgRestingHR.round()} bpm this week — stable or decreasing compared to historical data.'
              : 'No heart rate data recorded this week.',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final metrics = getMetrics(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Main content card with rounded top corners and a subtle shadow
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  // Show the appropriate state: loading, error, or data
                  child: _isLoading
                      ? _buildLoadingState()
                      : _errorMessage.isNotEmpty
                          ? _buildErrorState()
                          : _buildDataState(metrics),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the loading indicator shown while data is being fetched
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
          ),
          const SizedBox(height: 16),
          Text(
            'we are working for you',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Builds the error state UI with an error icon, message, and a retry button
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            // Retry button triggers a fresh data fetch
            ElevatedButton(
              onPressed: _fetchStatsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the main data view with sub-tab buttons, metric cards, and info cards.
  // Wrapped in a RefreshIndicator to allow pull-to-refresh.
  Widget _buildDataState(Map<String, String> metrics) {
    return RefreshIndicator(
      onRefresh: _fetchStatsData,
      color: AppColors.purple,
      child: SingleChildScrollView(
        // AlwaysScrollableScrollPhysics ensures pull-to-refresh works even if content fits the screen
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-Tab Button Row: Week / Month / Trend
            Row(
              children: [
                _buildSubTabButton('Week'),
                _buildSubTabButton('Month'),
                _buildSubTabButton('Trend'),
              ],
            ),
            const SizedBox(height: 24),
            // Section Title (e.g. "THIS WEEK", "THIS MONTH", "GENERAL TRENDS")
            Text(
              metrics['title']!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            // Metrics 2x2 Grid — first row: Steps and Sleep
            Row(
              children: [
                _buildMetricCard('Average Steps', metrics['passi']!),
                const SizedBox(width: 12),
                _buildMetricCard('Average Sleep', metrics['sonno']!),
              ],
            ),
            const SizedBox(height: 12),
            // Metrics 2x2 Grid — second row: Mood and Coins
            Row(
              children: [
                _buildMetricCard('Average Mood', metrics['mood']!),
                const SizedBox(width: 12),
                _buildMetricCard('Coins Earned', metrics['monete']!),
              ],
            ),
            const SizedBox(height: 24),
            // Correlation insight card (e.g. sleep-activity correlation)
            _buildInfoCard(
              metrics['corrTitle']!,
              metrics['corrSub']!,
              const Color(0xFFF2EFFF),
              AppColors.purple,
            ),
            const SizedBox(height: 12),
            // Heart Rate insight card
            _buildInfoCard(
              metrics['freqTitle']!,
              metrics['freqSub']!,
              const Color(0xFFF2EFFF),
              AppColors.purple,
            ),
          ],
        ),
      ),
    );
  }

  // Builds a single metric card displaying a label and its corresponding value.
  // Used in the 2x2 grid layout (e.g. "Average Steps" with the step count).
  Widget _buildMetricCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6F2), // Light warm grey background
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metric label (e.g. "Average Steps")
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            // Metric value (e.g. "8,456")
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds an info card with a title and subtitle, used for the correlation
  // and heart rate insight sections at the bottom of the screen.
  Widget _buildInfoCard(String title, String subtitle, Color bg, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title (e.g. "Correlation Detected")
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          // Card subtitle with the detailed insight text
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // Builds a single sub-tab button (Week / Month / Trend).
  // The selected button is highlighted with the purple accent color,
  // while unselected buttons have a neutral grey background.
  Widget _buildSubTabButton(String label) {
    final bool selected = _subTab == label;
    return Expanded(
      child: GestureDetector(
        // When tapped, update the selected sub-tab and trigger a rebuild
        onTap: () {
          setState(() {
            _subTab = label;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.purple : const Color(0xFFF7F6F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}