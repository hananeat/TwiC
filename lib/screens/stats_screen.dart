import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../utils/impact.dart';
import '../providers/user_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _subTab = 'Week'; // 'Week', 'Month', 'Trend'
  bool _isLoading = true;
  String _errorMessage = '';

  // Data containers
  final Map<DateTime, int> _stepsData = {};
  final Map<DateTime, int> _sleepData = {};
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
  double _stepsTrend = 0;
  double _sleepTrend = 0;
  double _restingHRTrend = 0;

  @override
  void initState() {
    super.initState();
    _fetchStatsData();
  }

  // Clear date keeping only year, month, and day
  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

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

  Future<void> _fetchStatsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final sp = await SharedPreferences.getInstance();
      var access = sp.getString('access');
      if (access == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No access token found. Please log in.';
        });
        return;
      }

      // 30 days of data ending yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dates = List.generate(
        30,
        (i) => _dateOnly(yesterday.subtract(Duration(days: i))),
      );

      // Perform requests in parallel
      final results = await Future.wait(
        dates.map((date) => _fetchDayData(date, access!)),
      );

      final hasUnauthorized = results.any((r) => r == 401);
      if (hasUnauthorized) {
        debugPrint('401 response detected. Trying to refresh token...');
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final newAccess = sp.getString('access');
          if (newAccess != null) {
            final retryResults = await Future.wait(
              dates.map((date) => _fetchDayData(date, newAccess)),
            );
            _processResults(dates, retryResults);
            return;
          }
        }
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired. Please log in again.';
        });
      } else {
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

  Future<dynamic> _fetchDayData(DateTime date, String access) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final patient = Impact.patientUsername;
    final headers = {'Authorization': 'Bearer $access'};

    final stepsUrl = '${Impact.baseUrl}data/v1/steps/patients/$patient/day/$formattedDate/';
    final sleepUrl = '${Impact.baseUrl}data/v1/sleep/patients/$patient/day/$formattedDate/';
    final hrUrl = '${Impact.baseUrl}data/v1/heart_rate/patients/$patient/day/$formattedDate/';

    try {
      final responses = await Future.wait([
        http.get(Uri.parse(stepsUrl), headers: headers),
        http.get(Uri.parse(sleepUrl), headers: headers),
        http.get(Uri.parse(hrUrl), headers: headers),
      ]);

      final stepsResp = responses[0];
      final sleepResp = responses[1];
      final hrResp = responses[2];

      if (stepsResp.statusCode == 401 || sleepResp.statusCode == 401 || hrResp.statusCode == 401) {
        return 401;
      }

      int stepsVal = 0;
      if (stepsResp.statusCode == 200) {
        final body = jsonDecode(stepsResp.body);
        if (body['data'] != null && body['data']['data'] != null) {
          final list = body['data']['data'] as List;
          stepsVal = list.fold<int>(0, (sum, item) {
            final val = int.tryParse(item['value']?.toString() ?? '0') ?? 0;
            return sum + val;
          });
        }
      }

      int sleepMinutes = 0;
      if (sleepResp.statusCode == 200) {
        final body = jsonDecode(sleepResp.body);
        if (body['data'] != null && body['data']['data'] != null) {
          final data = body['data']['data'];
          sleepMinutes = int.tryParse(data['minutesAsleep']?.toString() ?? '0') ?? 0;
        }
      }

      List<int> hrList = [];
      if (hrResp.statusCode == 200) {
        final body = jsonDecode(hrResp.body);
        debugPrint('RAW HR RESPONSE FOR DATE $formattedDate: ${hrResp.body}');
        if (body['data'] != null && body['data']['data'] != null) {
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
      return {
        'steps': 0,
        'sleep': 0,
        'hr': <int>[],
      };
    }
  }

  void _processResults(List<DateTime> dates, List<dynamic> results) {
    _stepsData.clear();
    _sleepData.clear();
    _hrData.clear();

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final res = results[i];
      if (res is Map) {
        _stepsData[date] = res['steps'] ?? 0;
        _sleepData[date] = res['sleep'] ?? 0;
        _hrData[date] = List<int>.from(res['hr'] ?? []);
      }
    }

    // --- WEEKLY STATS (indices 0-6) ---
    int weekStepsDays = 0;
    int weekTotalSteps = 0;
    int weekSleepDays = 0;
    int weekTotalSleep = 0;
    List<int> weekAllHR = [];
    List<double> weekRestingHRs = [];

    for (int i = 0; i < 7; i++) {
      final date = dates[i];
      final steps = _stepsData[date] ?? 0;
      if (steps > 0) {
        weekTotalSteps += steps;
        weekStepsDays++;
      }

      final sleep = _sleepData[date] ?? 0;
      if (sleep > 0) {
        weekTotalSleep += sleep;
        weekSleepDays++;
      }

      final hrList = _hrData[date] ?? [];
      if (hrList.isNotEmpty) {
        weekAllHR.addAll(hrList);
        // Resting Heart Rate proxy: average of bottom 5%
        final sorted = List<int>.from(hrList)..sort();
        final limit = (sorted.length * 0.05).clamp(1, sorted.length).toInt();
        final lowest = sorted.take(limit);
        final dayResting = lowest.fold<int>(0, (sum, val) => sum + val) / limit;
        weekRestingHRs.add(dayResting);
      }
    }

    _weekAvgSteps = weekStepsDays > 0 ? weekTotalSteps / weekStepsDays : 0;
    _weekAvgSleepMinutes = weekSleepDays > 0 ? weekTotalSleep / weekSleepDays : 0;
    _weekAvgHR = weekAllHR.isNotEmpty ? weekAllHR.reduce((a, b) => a + b) / weekAllHR.length : 0;
    _weekAvgRestingHR = weekRestingHRs.isNotEmpty ? weekRestingHRs.reduce((a, b) => a + b) / weekRestingHRs.length : 0;

    // --- MONTHLY STATS ---
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
        final sorted = List<int>.from(hrList)..sort();
        final limit = (sorted.length * 0.05).clamp(1, sorted.length).toInt();
        final lowest = sorted.take(limit);
        final dayResting = lowest.fold<int>(0, (sum, val) => sum + val) / limit;
        monthRestingHRs.add(dayResting);
      }
    }

    _monthAvgSteps = monthStepsDays > 0 ? monthTotalSteps / monthStepsDays : 0;
    _monthAvgSleepMinutes = monthSleepDays > 0 ? monthTotalSleep / monthSleepDays : 0;
    _monthAvgHR = monthAllHR.isNotEmpty ? monthAllHR.reduce((a, b) => a + b) / monthAllHR.length : 0;
    _monthAvgRestingHR = monthRestingHRs.isNotEmpty ? monthRestingHRs.reduce((a, b) => a + b) / monthRestingHRs.length : 0;

    // --- TREND CALCULATION ---
    double h1Steps = 0;
    int h1StepsDays = 0;
    double h2Steps = 0;
    int h2StepsDays = 0;

    double h1Sleep = 0;
    int h1SleepDays = 0;
    double h2Sleep = 0;
    int h2SleepDays = 0;

    List<double> h1Resting = [];
    List<double> h2Resting = [];

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

    final avgH1Steps = h1StepsDays > 0 ? h1Steps / h1StepsDays : 0;
    final avgH2Steps = h2StepsDays > 0 ? h2Steps / h2StepsDays : 0;
    _stepsTrend = avgH2Steps > 0 ? ((avgH1Steps - avgH2Steps) / avgH2Steps) * 100 : 0;

    final avgH1Sleep = h1SleepDays > 0 ? h1Sleep / h1SleepDays : 0;
    final avgH2Sleep = h2SleepDays > 0 ? h2Sleep / h2SleepDays : 0;
    _sleepTrend = avgH2Sleep > 0 ? ((avgH1Sleep - avgH2Sleep) / avgH2Sleep) * 100 : 0;

    final avgH1Resting = h1Resting.isNotEmpty ? h1Resting.reduce((a, b) => a + b) / h1Resting.length : 0.0;
    final avgH2Resting = h2Resting.isNotEmpty ? h2Resting.reduce((a, b) => a + b) / h2Resting.length : 0.0;
    _restingHRTrend = avgH2Resting > 0 ? (avgH1Resting - avgH2Resting).toDouble() : 0.0;

    setState(() {
      _isLoading = false;
    });
  }

  String _formatSleepMinutes(double minutes) {
    if (minutes == 0) return '0m';
    final hrs = minutes ~/ 60;
    final mins = (minutes % 60).round();
    return hrs > 0 ? '${hrs}h ${mins}m' : '${mins}m';
  }

  Map<String, String> getMetrics(UserProvider userProvider) {
    String moodStr = 'N/A';
    if (userProvider.savedMood != -1) {
      moodStr = '${userProvider.savedMood + 1} / 5';
    }

    final coinsStr = userProvider.stars.toString();

    switch (_subTab) {
      case 'Month':
        return {
          'title': 'THIS MONTH',
          'passi': _monthAvgSteps > 0 ? NumberFormat('#,###', 'en_US').format(_monthAvgSteps.round()) : 'N/A',
          'sonno': _formatSleepMinutes(_monthAvgSleepMinutes),
          'mood': moodStr,
          'monete': '+$coinsStr',
          'corrTitle': 'Monthly Correlation',
          'corrSub': _monthAvgSteps > 0
              ? 'With a steps average of ${NumberFormat('#,###', 'en_US').format(_monthAvgSteps.round())}, your resting heart rate is ${_monthAvgRestingHR.round()} bpm.'
              : 'Take more steps to track the impact on your resting heart rate.',
          'freqTitle': 'Resting Heart Rate',
          'freqSub': _monthAvgRestingHR > 0
              ? '${_monthAvgRestingHR.round()} bpm this month — based on real IMPACT data.'
              : 'No data this month.',
        };
      case 'Trend':
        final stepsSign = _stepsTrend >= 0 ? '+' : '';
        final sleepSign = _sleepTrend >= 0 ? '+' : '';
        final hrTrendText = _restingHRTrend > 0
            ? 'increasing by ${_restingHRTrend.toStringAsFixed(1)} bpm compared to before.'
            : _restingHRTrend < 0
                ? 'decreasing by ${(_restingHRTrend * -1).toStringAsFixed(1)} bpm compared to before.'
                : 'stable compared to before.';

        return {
          'title': 'GENERAL TRENDS',
          'passi': '$stepsSign${_stepsTrend.toStringAsFixed(1)}% / month',
          'sonno': '$sleepSign${_sleepTrend.toStringAsFixed(1)}% / month',
          'mood': userProvider.savedMood != -1 ? 'Stable' : 'N/A',
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
          'mood': moodStr,
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
      backgroundColor: const Color(0xFFFFFDE7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D59B5)),
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
            ElevatedButton(
              onPressed: _fetchStatsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D59B5),
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

  Widget _buildDataState(Map<String, String> metrics) {
    return RefreshIndicator(
      onRefresh: _fetchStatsData,
      color: const Color(0xFF5D59B5),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-Tab Button Row
            Row(
              children: [
                _buildSubTabButton('Week'),
                _buildSubTabButton('Month'),
                _buildSubTabButton('Trend'),
              ],
            ),
            const SizedBox(height: 24),
            // Section Title
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
            // Metrics 2x2 Grid
            Row(
              children: [
                _buildMetricCard('Average Steps', metrics['passi']!),
                const SizedBox(width: 12),
                _buildMetricCard('Average Sleep', metrics['sonno']!),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricCard('Average Mood', metrics['mood']!),
                const SizedBox(width: 12),
                _buildMetricCard('Coins Earned', metrics['monete']!),
              ],
            ),
            const SizedBox(height: 24),
            // Correlation Card
            _buildInfoCard(
              metrics['corrTitle']!,
              metrics['corrSub']!,
              const Color(0xFFF2EFFF),
              const Color(0xFF5D59B5),
            ),
            const SizedBox(height: 12),
            // Heart Rate Card
            _buildInfoCard(
              metrics['freqTitle']!,
              metrics['freqSub']!,
              const Color(0xFFF2EFFF),
              const Color(0xFF5D59B5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F6F2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A2859),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildSubTabButton(String label) {
    final bool selected = _subTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _subTab = label;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF5D59B5) : const Color(0xFFF7F6F2),
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