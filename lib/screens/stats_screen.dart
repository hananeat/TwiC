import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _subTab = 'Settimana'; // 'Settimana', 'Mese', 'Trend'

  Map<String, String> getMetrics() {
    switch (_subTab) {
      case 'Mese':
        return {
          'title': 'QUESTO MESE',
          'passi': '6.850',
          'sonno': '7h 10m',
          'mood': '3.5 / 5',
          'monete': '+512',
          'corrTitle': 'Correlazione mensile',
          'corrSub': 'Con una media passi di 7k+, la frequenza cardiaca a riposo si è ridotta di 3 bpm.',
          'freqTitle': 'Frequenza cardiaca a riposo',
          'freqSub': '63 bpm questo mese — stabile rispetto al mese scorso.',
        };
      case 'Trend':
        return {
          'title': 'TREND GENERALI',
          'passi': '+8% / mese',
          'sonno': '+15m / mese',
          'mood': '+0.3 / mese',
          'monete': '+1.240 tot',
          'corrTitle': 'Andamento positivo',
          'corrSub': 'Il tuo sonno è migliorato del 5% grazie a orari di riposo più regolari.',
          'freqTitle': 'Frequenza cardiaca',
          'freqSub': 'Mostra una tendenza alla riduzione nelle ultime 8 settimane.',
        };
      case 'Settimana':
      default:
        return {
          'title': 'QUESTA SETTIMANA',
          'passi': '6.240',
          'sonno': '6h 55m',
          'mood': '3.2 / 5',
          'monete': '+128',
          'corrTitle': 'Correlazione rilevata',
          'corrSub': 'Nei giorni con 7h+ di sonno il tuo umore era in media 0.8 punti più alto.',
          'freqTitle': 'Frequenza cardiaca a riposo',
          'freqSub': '62 bpm questa settimana — in calo rispetto alle 65 bpm di 4 settimane fa.',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = getMetrics();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // White Container (Device View)
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sub-Tabs Row
                        Row(
                          children: [
                            _buildSubTabButton('Settimana'),
                            _buildSubTabButton('Mese'),
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
                        // Grid 2x2
                        Row(
                          children: [
                            _buildMetricCard('Media passi', metrics['passi']!),
                            const SizedBox(width: 12),
                            _buildMetricCard('Media sonno', metrics['sonno']!),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildMetricCard('Mood medio', metrics['mood']!),
                            const SizedBox(width: 12),
                            _buildMetricCard('Monete guadagnate', metrics['monete']!),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Correlazione Card
                        _buildInfoCard(
                          metrics['corrTitle']!,
                          metrics['corrSub']!,
                          const Color(0xFFF2EFFF),
                          const Color(0xFF5D59B5),
                        ),
                        const SizedBox(height: 12),
                        // Frequenza cardiaca Card
                        _buildInfoCard(
                          metrics['freqTitle']!,
                          metrics['freqSub']!,
                          const Color(0xFFE8F6F1),
                          const Color(0xFF0A7C5F),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(String label) {
    final bool isActive = _subTab == label;
    return GestureDetector(
      onTap: () => setState(() => _subTab = label),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEDEAFE) : const Color(0xFFF7F6F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? const Color(0xFF5D59B5) : Colors.black45,
          ),
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
}

// ovviamente sono dati fittizzi che poi verranno sostituiti con quelli reali