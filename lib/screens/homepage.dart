import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/health_data_provider.dart';
import 'stats_screen.dart';
import 'mood_screen.dart';
import 'package:TwiC/utils/app_colors.dart';
import 'shop.dart';
import 'profile_screen.dart';
import 'login.dart';
import '../utils/impact.dart';
import '../utils/goal_calculation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //bottom bar navigation
  int _selectedIndex = 0;
  //dati generali (saranno caricati dinamicamente in futuro)
  final int _vitality = 68;
  final int _vitalityMax = 100;

  DateTime _selectedDate = DateTime.now();

  //dati obbiettivi giornalieri (caricati dinamicamente)
  late List<Map<String, dynamic>> _goals;

  //logica della homepage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF5D59B5).withOpacity(0.15),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF5D59B5)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded, color: Colors.grey),
            selectedIcon: Icon(Icons.favorite_rounded, color: Color(0xFF5D59B5)),
            label: 'Mood',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded, color: Colors.grey),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF5D59B5)),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.shopping_bag_rounded, color: Color(0xFF5D59B5)),
            label: 'Shop',
          ),
        ],
      ),
    );
  }

// The structure of the dashboard content, separated for clarity and maintainability
  Widget _buildDashboardContent(UserProvider userProvider) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildTopBar(userProvider),
            const SizedBox(height: 24),
            _buildDateNavigator(),
            const SizedBox(height: 24),
            //riquadro con il pulcino
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF5D59B5).withOpacity(0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D59B5).withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildChickSection(userProvider),
            ),
            const SizedBox(height: 20),
            _buildVitalityBar(),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF5D59B5).withOpacity(0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D59B5).withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildGoalsSection(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

// The _getPage method determines which screen to display based on the selected navigation index.
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return Consumer2<UserProvider, HealthDataProvider>(
          builder: (context, userProvider, healthProvider, child) {
            _updateGoalsForDate(_selectedDate, userProvider.isMoodDoneForDate(_selectedDate), healthProvider, userProvider);
            return healthProvider.isLoading
                ? const Scaffold(
                    backgroundColor: Color(0xFFFFFDE7),
                    body: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D59B5)),
                      ),
                    ),
                  )
                : _buildDashboardContent(userProvider);
          },
        );
      case 1:
        return MoodScreen(date: _selectedDate);
      case 2:
        return const StatsScreen();
      case 3:
        return const ShopScreen();
      default:
        return Consumer2<UserProvider, HealthDataProvider>(
          builder: (context, userProvider, healthProvider, child) {
            _updateGoalsForDate(_selectedDate, userProvider.isMoodDoneForDate(_selectedDate), healthProvider, userProvider);
            return healthProvider.isLoading
                ? const Scaffold(
                    backgroundColor: Color(0xFFFFFDE7),
                    body: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D59B5)),
                      ),
                    ),
                  )
                : _buildDashboardContent(userProvider);
          },
        );
    }
  }

  // The initState method is called when the widget is created.
  // It is used to initialize the _goals list with the default goals.
  @override
  void initState() {
    super.initState();
    _initGoals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HealthDataProvider>(context, listen: false)
          .fetchDataOfDay(_selectedDate);
    });
  }

  void _initGoals() {
    _goals = [
      {
        'label': 'Steps',
        'color': const Color(0xFF3DBF7A),
        'progress': 0.60,
        'value': '5.8k',
        'points': '+7',
        'done': true,
      },
      {
        'label': 'Sleep',
        'color': const Color(0xFF3BAEE8),
        'progress': 0.72,
        'value': '7h12',
        'points': '+10',
        'done': true,
      },
      {
        'label': 'Mood',
        'color': const Color(0xFFE85C3B),
        'progress': 0.0,
        'value': '—',
        'points': '+5',
        'done': false,
      },
      {
        'label': 'Exercise',
        'color': const Color(0xFF5D59B5),
        'progress': 0.50,
        'value': '1 sess.',
        'points': '+6',
        'done': true,
      },
    ];
  }

// The _updateGoalsForDate method updates the _goals list with the goals for the selected date.
// It takes the selected date and the moodDoneToday boolean as parameters.
    void _updateGoalsForDate(DateTime date, bool moodDoneToday, HealthDataProvider healthProvider, UserProvider userProvider) {
    final steps = healthProvider.totalSteps;
    final sleepMin = healthProvider.totalSleepMinutes;
    final exercises = healthProvider.totalExerciseSessions;
    
    // Esegue il calcolo dinamico in base all'età
    final reward = GoalCalculation.calculate(
      age: userProvider.age,
      steps: steps,
      sleepMinutes: sleepMin,
    );

    final stepsValue = NumberFormat('#,###', 'it_IT').format(steps);

    final sleepHours = sleepMin ~/ 60;
    final sleepMins = sleepMin % 60;
    final sleepValue = sleepHours > 0
        ? '${sleepHours}h${sleepMins.toString().padLeft(2, '0')}'
        : '${sleepMins}m';

    const int exerciseTargetSessions = 1;
    final exerciseProgress = exerciseTargetSessions > 0 ? (exercises / exerciseTargetSessions).clamp(0.0, 1.0) : 0.0;

    _goals = [
      {
        'label': 'Steps',
        'color': const Color(0xFF3DBF7A),
        'progress': reward.stepsProgress,
        'value': '$stepsValue / ${reward.stepsTarget}',
        'points': reward.stepsPoints > 0 ? '+${reward.stepsPoints}' : '0',
        'done': reward.stepsDone,
      },
      {
        'label': 'Sleep',
        'color': const Color(0xFF3BAEE8),
        'progress': reward.sleepProgress,
        'value': '$sleepValue / ${reward.sleepTargetMinutes ~/ 60}h',
        'points': reward.sleepPoints > 0 ? '+${reward.sleepPoints}' : '0',
        'done': reward.sleepDone,
      },
      {
        'label': 'Mood',
        'color': const Color(0xFFE85C3B),
        'progress': moodDoneToday ? 1.0 : 0.0,
        'value': moodDoneToday ? 'Done' : '—',
        'points': '+5',
        'done': moodDoneToday,
      },
      {
        'label': 'Exercise',
        'color': const Color(0xFF5D59B5),
        'progress': exerciseProgress,
        'value': exercises == 1 ? '1 sess.' : '$exercises sess.',
        'points': '+6',
        'done': exercises >= exerciseTargetSessions,
      },
    ];
  }


// METHODS FOR BUILDING THE DASHBOARD CONTENT
// Method 1: The _buildDateNavigator method builds the date navigator.  
  Widget _buildDateNavigator() {
    final formattedDate = DateFormat('E, d MMM yyyy').format(_selectedDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
            Provider.of<HealthDataProvider>(context, listen: false)
                .fetchDataOfDay(_selectedDate);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5D59B5).withOpacity(0.15),
                width: 1.5,
              ),
              color: Colors.white,
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFF5D59B5),
            ),
          ),
        ),
        Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A2859),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 1));
            });
            Provider.of<HealthDataProvider>(context, listen: false)
                .fetchDataOfDay(_selectedDate);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5D59B5).withOpacity(0.15),
                width: 1.5,
              ),
              color: Colors.white,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF5D59B5),
            ),
          ),
        ),
      ],
    );
  }

  //Method 2: The _buildTopBar method builds the top bar of the dashboard.
  //It takes the userProvider as a parameter to get the first name of the user.
  Widget _buildTopBar(UserProvider userProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Hi ${userProvider.firstName},',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Glow and help ${userProvider.chickName} grow!',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A78A0),
                ),
              ),
            ],
          ),
        ),
        
        // Add a badge for stars and 3 points in the top right corner
        // The Container is used to display the number of stars.
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.yellow),
             ),
             child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Text(
                  '${userProvider.stars}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
               ),
              ],
             ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textDark),
              color: AppColors.background,
              onSelected: (value) async{
                if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                } else if (value == 'logout') {
                  //logout functionality 
                  final impact = Impact();
                  await impact.deleteTokens(); // Elimina i token salvati
                  // Clear user data from UserProvider
                  if (mounted) {
                    await Provider.of<UserProvider>(context, listen: false).clearUserData();
                  }
                  // Navigate to the login page and remove all previous routes
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false, // Rimuove tutta la navigazione precedente
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'Profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline_rounded, color: AppColors.textDark,size: 20),
                      SizedBox(width: 12),
                      Text('Visualize Profile',
                        style: TextStyle( color: AppColors.textDark)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Logout',
                      style: TextStyle( color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  //Method 3: The _buildChickSection method builds the chick section.  
  Widget _buildChickSection(UserProvider userProvider) {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/images/chick3.png',
            width: 220,
            height: 220,
          ),
          const SizedBox(height: 12),
          Text(
            userProvider.chickName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A2859),
            ),
          ),
        ],
      ),
    );
  }

  //Method 4: The _buildVitalityBar method builds the vitality bar.
  //It takes the _vitality and _vitalityMax parameters to display the vitality progress.
  Widget _buildVitalityBar() {
    final double progress = _vitality / _vitalityMax;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D59B5)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vitality: $_vitality/$_vitalityMax',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D59B5),
          ),
        ),
      ],
    );
  }

//Method 5: The _buildGoalsSection method builds the goals section.
  Widget _buildGoalsSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Goals',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 14),
          //lista obbiettivi giornalieri 
          ...List.generate(_goals.length, (i) => _buildGoalRow(_goals[i])),
        ],
      );
  }

  //Method 6: The _buildGoalRow method builds a single goal row.
  //It takes the goal map as a parameter to display the goal progress.
  Widget _buildGoalRow(Map<String, dynamic> goal) {
    final Color color = goal['color'] as Color;
    final bool done = goal['done'] as bool;
 
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
 
            // Label
          SizedBox(
            width: 72,
            child: Text(
              goal['label'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2A2859),
              ),
            ),
          ),
          const SizedBox(width: 8),
 
          // Barra di avanzamento
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal['progress'] as double,
                minHeight: 6,
                backgroundColor: Colors.grey.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  done ? color : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
 
          // Valore (ora è statico)
          SizedBox(
            width: 60,
            child: Text(
              goal['value'] as String,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
 
          // Badge punti
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: done
                  ? const Color(0xFFFFF3D4)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              goal['points'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done
                    ? const Color(0xFF8A6200)
                    : Colors.grey.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
