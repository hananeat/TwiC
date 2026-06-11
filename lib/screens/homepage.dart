import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import 'stats_screen.dart';
import 'mood_screen.dart';

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
    final userProvider = Provider.of<UserProvider>(context);

    // Update goals dynamically from provider/selected date
    _updateGoalsForDate(_selectedDate, userProvider.moodDone);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF5D59B5).withValues(alpha: 0.15),
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
  Widget _buildDashboardContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildTopBar(),
            const SizedBox(height: 24),
            _buildDateNavigator(),
            const SizedBox(height: 24),
            _buildChickSection(),
            const SizedBox(height: 20),
            _buildVitalityBar(),
            const SizedBox(height: 28),
            _buildGoalsSection(),
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
        return _buildDashboardContent();
      case 1:
        return const MoodScreen();
      case 2:
        return const StatsScreen();
      case 3:
        return const Center(
          child: Text(
            'Shop Screen',
            style: TextStyle(
              fontSize: 24,
              color: Color(0xFF2A2859),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return _buildDashboardContent();
    }
  }

  // The initState method is called when the widget is created.
  // It is used to initialize the _goals list with the default goals.
  @override
  void initState() {
    super.initState();
    _initGoals();
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
  void _updateGoalsForDate(DateTime date, bool moodDoneToday) {
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
        'progress': moodDoneToday ? 1.0 : 0.0,
        'value': moodDoneToday ? 'Done' : '—',
        'points': '+5',
        'done': moodDoneToday,
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
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5D59B5).withValues(alpha: 0.15),
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
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF5D59B5).withValues(alpha: 0.15),
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
  Widget _buildTopBar() {
    final userProvider = Provider.of<UserProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${userProvider.firstName}!',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'How do you feel today?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A2859)
              ),
            ),
          ],
        ),

        // The Container is used to display the number of stars.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8C96B), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFE8A800), size: 18),
              const SizedBox(width: 6),
              Text(
                '${userProvider.stars}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A6200),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //Method 3: The _buildChickSection method builds the chick section.  
  Widget _buildChickSection() {
    final userProvider = Provider.of<UserProvider>(context);
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/images/egg.png',
            width: 120,
            height: 120,
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
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
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
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  done ? color : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
 
          // Valore (ora è statico)
          SizedBox(
            width: 44,
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
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              goal['points'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done
                    ? const Color(0xFF8A6200)
                    : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
