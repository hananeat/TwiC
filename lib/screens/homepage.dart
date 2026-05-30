import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //bottom bar navigation
  int _selectedIndex = 0;
  //dati generali (saranno caricati dinamicamente in futuro)
  String _chickName = '';
  final int _vitality = 68;
  final int _vitalityMax = 100;
  final int _stars = 47;

  //dati obbiettivi giornalieri (saranno caricati dinamicamente in futuro)
  final List<Map<String, dynamic>> _goals = [
    {
      'label': 'Passi',
      'color': const Color(0xFF3DBF7A),
      'progress': 0.60,
      'value': '5.8k',
      'points': '+7',
      'done': true,
    },
    {
      'label': 'Sonno',
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
      'label': 'Esercizio',
      'color': const Color(0xFF5D59B5),
      'progress': 0.50,
      'value': '1 sess.',
      'points': '+6',
      'done': true,
    },
  ];

  //logica della homepage
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildTopBar(),
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
            ), 
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  //carico nome chick (faremo lo stesso con nome_utente)
  @override
  void initState() {
    super.initState();
    _loadChickName();
  }

  Future<void> _loadChickName() async {
  final sp = await SharedPreferences.getInstance();
  final name = sp.getString('chickName');
  if (name != null && name.isNotEmpty && mounted) {
    setState(() => _chickName = name);
    }
  }

  //top bar con saluto e monetine
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ciao, nome_utente!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'How do you feel today?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A2859)
              ),
            ),
          ],
        ),

        //monetine (icona + numero da inserire dinamicamente) 
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
                '$_stars',
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
  
  //sezione con immagine chick (da caricare dinamicamente) e nome
  Widget _buildChickSection() {
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
            _chickName,
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

   //barra vitality (barra di progresso con percentuale)
  Widget _buildVitalityBar() {
    final double progress = _vitality / _vitalityMax;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey.withOpacity(0.3),
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

//Sezione obbiettivi giornalieri 
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

  //singolo obbiettivo giornaliero
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

  //bottom navigation bar con 4 icone
  Widget _buildBottomNavBar() {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.favorite_border_rounded, 'label': 'Mood'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Stats'},
      {'icon': Icons.shopping_bag_outlined, 'label': 'Shop'},
    ];
 
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final bool isActive = _selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = index);
              //   navigare alla schermata corrispondente
              //   index 0 → Home (già qui) , index 1 → MoodScreen
              //   index 2 → StatsScreen , index 3 → ShopScreen
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  navItems[index]['icon'] as IconData,
                  size: 24,
                  color: isActive ? const Color(0xFF5D59B5) : Colors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  navItems[index]['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? const Color(0xFF5D59B5) : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
