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

const _backgroundAssets = {
  'habitat_0': 'assets/images/grassland.png',
  'habitat_1': 'assets/images/desert.png',
  'habitat_2': 'assets/images/forest.png',
  'habitat_3': 'assets/images/beach.png',
};

const _accessoryAssets = {
  'accessory_1': 'assets/images/summer_hat.png',
  'accessory_2': 'assets/images/sunglasses.png',
};

const _colorAssets = {
  'color_1': 'chick6_red.png',
  'color_2': 'chick6_blu.png',
  'color_3': 'chick6_green.png',
};

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //bottom bar navigation
  int _selectedIndex = 0;
  // Calcola la vitalità corrente basata sugli obiettivi caricati
  double get _currentVitality {
    if (_goals.isEmpty) return 0.0;
    double total = 0.0;
    for (var goal in _goals) {
      final label = goal['label'] as String;
      final progress = goal['progress'] as double;
      if (label == 'Steps') {
        total += progress * 30;
      } else if (label == 'Sleep') {
        total += progress * 30;
      } else if (label == 'Exercise') {
        total += progress * 30;
      } else if (label == 'Mood') {
        total += progress * 10;
      }
    }
    return total;
  }
  

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
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                child: _buildDateNavigator(userProvider),
              ),
            ),
            const SizedBox(height: 24),
            //riquadro con il pulcino
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
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

    // Calcola e aggiorna la vitalità per la data selezionata nel provider
    final double computedVitality = (reward.stepsProgress * 30) + 
                                     (reward.sleepProgress * 30) + 
                                     (exerciseProgress * 30) + 
                                     (moodDoneToday ? 10.0 : 0.0);

    final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    // Always trigger past XP check for the selected date to process growth dynamically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider.checkAndProcessPastXP(currentDate: date);
    });

    // Claim goal rewards if completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider.claimGoalRewards(
        dateKey,
        stepsDone: reward.stepsDone,
        sleepDone: reward.sleepDone,
        exerciseDone: exercises >= exerciseTargetSessions,
        stepsPoints: reward.stepsPoints,
        sleepPoints: reward.sleepPoints,
        exercisePoints: 6,
      );
    });

    if (userProvider.getDailyVitalityForDate(date) != computedVitality) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userProvider.updateDailyVitality(dateKey, computedVitality);
      });
    }
  }


// METHODS FOR BUILDING THE DASHBOARD CONTENT
// Method 1: The _buildDateNavigator method builds the date navigator.  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _parseDateStr(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  // Method 1: The _buildDateNavigator method builds the date navigator.  
  Widget _buildDateNavigator(UserProvider userProvider) {
    final formattedDate = DateFormat('E, d MMM yyyy').format(_selectedDate);

    final firstAccessDate = userProvider.firstAccessDate.isNotEmpty 
        ? _parseDateStr(userProvider.firstAccessDate) 
        : DateTime.now();

    final bool canGoBack = _selectedDate.isAfter(firstAccessDate) && !_isSameDay(_selectedDate, firstAccessDate);
    
    // We can always go forward in time infinitely

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: canGoBack ? () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
            Provider.of<HealthDataProvider>(context, listen: false)
                .fetchDataOfDay(_selectedDate);
          } : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: canGoBack 
                    ? const Color(0xFF5D59B5).withOpacity(0.15) 
                    : const Color(0xFF5D59B5).withOpacity(0.05),
                width: 1.5,
              ),
              color: canGoBack ? Colors.white : Colors.grey.withOpacity(0.05),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: canGoBack 
                  ? const Color(0xFF5D59B5) 
                  : const Color(0xFF5D59B5).withOpacity(0.25),
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

  //Method 3: The _buildChickSection method builds the chick section with Integrated Vitality Bar.  
  Widget _buildChickSection(UserProvider userProvider) {
    // Get historical state for the currently selected date
    final historicalState = userProvider.getHistoricalStateForDate(_selectedDate);
    final int currentLevel = historicalState['level'] as int;
    final int currentXp = historicalState['xp'] as int;
    final int currentOverflowXp = historicalState['overflowXp'] as int;
    final double vitality = _currentVitality;

    // Colore equipaggiato (solo livello 6)
    final String? equippedColor = userProvider.equippedColor;
    String assetPath = 'assets/images/chick$currentLevel.png';

    if (currentLevel == 6) {
    //Usa varianti vitality
    if (vitality < 40) {
      assetPath = 'assets/images/chick6_sad.png';
    } else if (vitality >= 80) {
      assetPath = 'assets/images/chick6_smile.png';
    } else {
      assetPath = 'assets/images/chick6.png';
    }
}

    int maxXp = 100;
    if (currentLevel == 1) {
      maxXp = 100;
    } else if (currentLevel == 2) {
      maxXp = 300;
    } else if (currentLevel == 3) {
      maxXp = 600;
    } else if (currentLevel == 4) {
      maxXp = 1000;
    } else if (currentLevel == 5) {
      maxXp = 1500;
    }
    
    

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Centered Chick Information
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
                width: 350, 
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                  // Piano 1 — Sfondo (habitat)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _backgroundAssets[userProvider.equippedBackground] ??
                               'assets/images/grassland.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Piano 2 — Pulcino
                    Positioned(
                      top: 35,
                      left: 15,
                      right: 15, //centrato
                     child: FloatingAsset(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            assetPath,
                            width: 290,
                            fit: BoxFit.contain,
                          ),
                          // Piano 3 — Accessorio (se presente)
                          if (userProvider.equippedAccessory != null &&
                              _accessoryAssets.containsKey(userProvider.equippedAccessory))
                            Positioned(
                              bottom: _accessoryOffset(userProvider.equippedAccessory).dy,
                              child: Image.asset(
                                _accessoryAssets[userProvider.equippedAccessory]!,
                                width: _accessoryOffset(userProvider.equippedAccessory).dx,
                                fit: BoxFit.contain,
                              ),
                            )
                        ],
                      ),
                     ),
                    ),
                  ],
                ),  
            ),
          
            const SizedBox(height: 1),
            Text(
              userProvider.chickName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A2859), // Dark Blue
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D59B5).withOpacity(0.08), // Light purple background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level $currentLevel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D59B5),
                    ),
                  ),
                ),
                Text(
                  '  •  ',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                if (currentLevel < 6)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Color(0xFF2A2859)),
                      children: [
                        const TextSpan(
                          text: 'Growth: ',
                          style: TextStyle(
                            color: Color(0xFF8B9E78), // Sage Green
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '$currentXp / $maxXp XP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Color(0xFF2A2859)),
                          children: [
                            const TextSpan(
                              text: 'Next Star: ',
                              style: TextStyle(
                                color: Color(0xFF8B9E78), // Sage Green
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: '$currentOverflowXp / 200 XP',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFFFFFDE7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              content: const Text(
                                'Your chick is fully grown!\n\n'
                                'From now on, your daily Vitality points '
                                'keep accumulating as XP.\n\n'
                                'Every 200 XP you earn is automatically '
                                'converted into 1 ⭐ Star that you can '
                                'spend in the Shop.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xFF2A2859),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Got it!',
                                    style: TextStyle(
                                      color: Color(0xFF5D59B5),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF5D59B5).withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: Color(0xFF5D59B5),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Vitality Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'VITALITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Color(0xFF8B9E78), // Sage Green
              ),
            ),
            Text(
              '${vitality.round()} / 100',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A2859), // Dark Blue
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (vitality / 100).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: const Color(0xFF5D59B5).withOpacity(0.08), // Light purple bg
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D59B5)), // Purple progress
          ),
        ),
      ],
    );
  }

// Restituisce (width, bottom) per ogni accessorio
// dx = larghezza immagine, dy = offset dal basso
Offset _accessoryOffset(String? accessoryId) {
  switch (accessoryId) {
    case 'accessory_2': // Sunglasses
      return const Offset(90, 70);  
    case 'accessory_1': // Summer Hat
      return const Offset(80, 100); 
    default:
      return const Offset(90, 68);
  }
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

// Widget for the gentle up-and-down floating/breathing animation of the chick
class FloatingAsset extends StatefulWidget {
  final Widget child;
  const FloatingAsset({super.key, required this.child});

  @override
  State<FloatingAsset> createState() => _FloatingAssetState();
}

class _FloatingAssetState extends State<FloatingAsset> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Smooth transition from -6.0 to +6.0 pixels vertical offset
    _animation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
} 
