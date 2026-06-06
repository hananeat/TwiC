import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:TwiC/utils/impact.dart';
import 'login.dart';
import 'homepage.dart';
import 'onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // per cambiare il font

class SplashLogoScreen extends StatefulWidget {
  const SplashLogoScreen({super.key});

  @override
  State<SplashLogoScreen> createState() => _SplashLogoScreenState();
}

class _SplashLogoScreenState extends State<SplashLogoScreen>
    with TickerProviderStateMixin {

  // Un controller per ogni parola — controlla quando appare
  late AnimationController _tController;
  late AnimationController _wController;
  late AnimationController _iController;
  late AnimationController _cController;

  // Controlla la fase finale — le parole spariscono e rimane TwiC
  late AnimationController _finalController;

  late Animation<double> _tAnim;
  late Animation<double> _wAnim;
  late Animation<double> _iAnim;
  late Animation<double> _cAnim;

  // Controlla la sparizione delle parole
  late Animation<double> _wordsHide;
  // Controlla l'apparizione di TwiC grande
  late Animation<double> _twicShow;
  // Controlla la dimensione di TwiC (cresce)
  late Animation<double> _twicSize;

  bool _showFinalTwiC = false; // quando true mostra TwiC grande

  //static const Color primaryPurple = Color(0xFF5D59B5);
  //static const Color bgLight = Color(0xFFEEF0FA);

  // Cambia i colori
  static const Color primaryYellow = Color(0xFFFFD158);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color bgColor = Color(0xFFFFFDE7);

  @override
  void initState() {
    super.initState();

    _tController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _wController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _iController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _cController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _finalController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    // Ogni parola appare con un fade (da invisibile a visibile)
    _tAnim = Tween<double>(begin: 0, end: 1).animate(_tController);
    _wAnim = Tween<double>(begin: 0, end: 1).animate(_wController);
    _iAnim = Tween<double>(begin: 0, end: 1).animate(_iController);
    _cAnim = Tween<double>(begin: 0, end: 1).animate(_cController);

    // Le parole spariscono (da 1 a 0)
    _wordsHide = Tween<double>(begin: 1, end: 0).animate(_finalController);

    // TwiC appare (da 0 a 1)
    _twicShow = Tween<double>(begin: 0, end: 1).animate(_finalController);

    // TwiC cresce (da piccolo a grande)
    _twicSize = Tween<double>(begin: 20, end: 72).animate(
      CurvedAnimation(parent: _finalController, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _tController.forward(); // appare "Tiny"

    await Future.delayed(const Duration(milliseconds: 500));
    _wController.forward(); // appare "Wellness"

    await Future.delayed(const Duration(milliseconds: 500));
    _iController.forward(); // appare "interactive"

    await Future.delayed(const Duration(milliseconds: 500));
    _cController.forward(); // appare "Chick"

    // Aspetta un momento con tutto visibile
    await Future.delayed(const Duration(milliseconds: 900));

    // Mostriamo TwiC e nascondiamo le parole
    setState(() => _showFinalTwiC = true);
    _finalController.forward();

    // Aspetta e vai alla destinazione corretta
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      final sp = await SharedPreferences.getInstance();
      
      // Controlliamo se i token sono validi effettuando un refresh
      final impact = Impact();
      final refreshResult = await impact.refreshTokens();
      final hasAccess = refreshResult == 200;
      
      // Controlliamo se l'onboarding è completato (nome del pulcino presente)
      final chickName = sp.getString('chickName');
      final hasChickName = chickName != null && chickName.isNotEmpty;

      Widget nextScreen;
      if (hasAccess && hasChickName) {
        nextScreen = const HomePage();
      } else if (hasAccess && !hasChickName) {
        nextScreen = const OnboardingScreen();
      } else {
        nextScreen = const LoginPage();
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  void dispose() {
    _tController.dispose();
    _wController.dispose();
    _iController.dispose();
    _cController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        // Padding a sinistra — tutto allineato a sinistra
        padding: const EdgeInsets.only(left: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          // ↑ CrossAxisAlignment.start = allinea tutto a sinistra
          children: [
            // Pulcino in alto
            const Text('🐥', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 32),

            // Quando _showFinalTwiC è false mostriamo le parole
            // Quando è true mostriamo TwiC grande
            if (!_showFinalTwiC) ...[
              _buildRow('T', 'iny', _tAnim),
              _buildRow('W', 'ellness', _wAnim),
              _buildRow('i', 'nteractive', _iAnim),
              _buildRow('C', 'hick', _cAnim),
            ] else ...[
              // TwiC grande che appare e cresce
              FadeTransition(
                opacity: _twicShow,
                child: AnimatedBuilder(
                  animation: _twicSize,
                  builder: (context, child) {
                    return Text(
                      'TwiC',
                      style: TextStyle(
                        fontSize: _twicSize.value,
                        // ↑ la dimensione cresce durante l'animazione
                        fontWeight: FontWeight.bold,
                        color: primaryYellow,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Costruisce una riga: lettera maiuscola + resto della parola
  Widget _buildRow(String letter, String rest, Animation<double> anim) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lettera dell'acronimo — sempre visibile e in grassetto
          Text(
            letter,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryYellow,
            ), // Stile del testo
          ),
          // Resto della parola — appare con il fade
          FadeTransition(
            opacity: anim,
            child: Text(
              rest,
              style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryYellow,
              ), // Stile del testo
            ),
          ),
        ],
      ),
    );
  }
}