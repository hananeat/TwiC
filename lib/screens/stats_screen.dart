import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

//gestire la navigazione verso homepage ecc
class _StatsScreenState extends State<StatsScreen> {
  int _selectedIndex = 2; // Stats attivo
  String _tab = 'week';

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
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildTabSwitcher(),
                    const SizedBox(height: 24),
                    _buildStatsGrid(),
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

  //titolo e sottotitolo
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR STATISTICS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _tab == 'week' ? 'This week' : 'This month',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A2859),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD158),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ['week', 'month'].map((t) {
          final bool active = _tab == t;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = t),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: active
                      ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
                      : [],
                ),
                child: Text(
                  t[0].toUpperCase() + t.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? const Color(0xFF2A2859)
                        : const Color(0xFF7A6800),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  //griglia con 4 statistiche 
  Widget _buildStatsGrid() {
    final bool isWeek = _tab == 'week';
    final items = [
      {
        'label': 'mean steps',
        'value': isWeek ? '' : '',
        'icon': Icons.directions_walk_rounded,
        'accent': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF4CAF50),
      },
      {
        'label': 'mean sleep',
        'value': isWeek ? '' : '',
        'icon': Icons.bedtime_rounded,
        'accent': const Color(0xFFFFF9C4),
        'iconColor': const Color(0xFFF9A825),
      },
      {
        'label': 'mean mood',
        'value': isWeek ? '' : '',
        'icon': Icons.sentiment_satisfied_rounded,
        'accent': const Color(0xFFFFF3CD),
        'iconColor': const Color(0xFFFFD158),
      },
      {
        'label': 'Monete',
        'value': isWeek ? '' : '',
        'icon': Icons.star_rounded,
        'accent': const Color(0xFFEDE7F6),
        'iconColor': const Color(0xFF2A2859),
      },
    ];

    //calcolare dinamicamente
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.1,
      children: items.map((item) => _buildStatCard(item)).toList(),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item['accent'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item['icon'] as IconData,
                color: item['iconColor'] as Color, size: 20),
          ),
          const Spacer(),
          Text(
            item['label'] as String,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item['value'] as String,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2A2859),
            ),
          ),
        ],
      ),
    );
  }

//bottom navigation bar con 4 icone, quella di stats è attiva
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
              if (index == 0) Navigator.pop(context); // torna alla Home
            },

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  navItems[index]['icon'] as IconData,
                    size: 24,
                    color: isActive
                        ? const Color(0xFF5D59B5) : Colors.grey
                ),
                const SizedBox(height: 4),
                Text(
                  navItems[index]['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: 
                        isActive ? FontWeight.w600
                        : FontWeight.normal,
                    color: isActive
                        ? const Color(0xFF5D59B5)
                        : Colors.grey,
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
  