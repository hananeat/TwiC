import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:TwiC/services/impact.dart';
import 'package:lottie/lottie.dart';
import 'login.dart';
import 'homepage.dart';
import 'onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:TwiC/utils/app_colors.dart';

class SplashLogoScreen extends StatefulWidget {
  const SplashLogoScreen({super.key});

  @override
  State<SplashLogoScreen> createState() => _SplashLogoScreenState();
}

class _SplashLogoScreenState extends State<SplashLogoScreen>
    with TickerProviderStateMixin {

  // One animation controller per word — controls when each word appears
  late AnimationController _tController;
  late AnimationController _wController;
  late AnimationController _iController;
  late AnimationController _cController;

  // Controls the final phase — the words disappear and only TwiC remains
  late AnimationController _finalController;

  late Animation<double> _tAnim;
  late Animation<double> _wAnim;
  late Animation<double> _iAnim;
  late Animation<double> _cAnim;

  // Controls the appearance of the large TwiC text
  late Animation<double> _twicShow;
  // Controls the size of TwiC (grows from small to large)
  late Animation<double> _twicSize;

  bool _showFinalTwiC = false; // when true, shows the large TwiC text



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

    // Each word appears with a fade-in animation (from invisible to visible)
    _tAnim = Tween<double>(begin: 0, end: 1).animate(_tController);
    _wAnim = Tween<double>(begin: 0, end: 1).animate(_wController);
    _iAnim = Tween<double>(begin: 0, end: 1).animate(_iController);
    _cAnim = Tween<double>(begin: 0, end: 1).animate(_cController);

    // TwiC fades in (opacity from 0 to 1)
    _twicShow = Tween<double>(begin: 0, end: 1).animate(_finalController);

    // TwiC grows in size (from small to large font)
    _twicSize = Tween<double>(begin: 24, end: 72).animate(
      CurvedAnimation(parent: _finalController, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _tController.forward(); // "Tiny" appears

    await Future.delayed(const Duration(milliseconds: 500));
    _wController.forward(); // "Wellness" appears

    await Future.delayed(const Duration(milliseconds: 500));
    _iController.forward(); // "interactive" appears

    await Future.delayed(const Duration(milliseconds: 500));
    _cController.forward(); // "Chick" appears

    // Wait a moment with all words visible
    await Future.delayed(const Duration(milliseconds: 900));

    // Show the final TwiC text and hide the individual words
    setState(() => _showFinalTwiC = true);
    _finalController.forward();

    // Wait and navigate to the correct destination
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      final sp = await SharedPreferences.getInstance();
      
      // Check if the tokens are still valid by attempting a refresh
      final impact = Impact();
      final refreshResult = await impact.refreshTokens();
      final hasAccess = refreshResult == 200;
      
      // Check if onboarding has been completed (chick name is present)
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
      backgroundColor: AppColors.background,
      body: Padding(
        // Left padding — all content is left-aligned
        padding: const EdgeInsets.only(left: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          // ↑ CrossAxisAlignment.start = aligns everything to the left
          children: [
            // Animated chick at the top (replaces the static emoji)
            Lottie.asset(
              'assets/hatching_chick.json',
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 16),

            // When _showFinalTwiC is false, show the individual words
            // When true, show the large TwiC text
            if (!_showFinalTwiC) ...[
              _buildRow('T', 'iny', _tAnim),
              _buildRow('W', 'ellness', _wAnim),
              _buildRow('i', 'nteractive', _iAnim),
              _buildRow('C', 'hick', _cAnim),
            ] else ...[
              // Large TwiC text that fades in and grows (using Poppins font and consistent dark color)
              FadeTransition(
                opacity: _twicShow,
                child: AnimatedBuilder(
                  animation: _twicSize,
                  builder: (context, child) {
                    return Text(
                      'TwiC',
                      style: GoogleFonts.poppins(
                        fontSize: _twicSize.value,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark, // Same dark color as the login screen
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

  // Builds a row: uppercase acronym letter + the rest of the word
  Widget _buildRow(String letter, String rest, Animation<double> anim) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Acronym letter — always visible and bold
          Text(
            letter,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.green, // Green for the main acronym letters
            ),
          ),
          // Rest of the word — appears with the fade-in animation
          FadeTransition(
            opacity: anim,
            child: Text(
              rest,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark, // Coordinated dark text color
              ),
            ),
          ),
        ],
      ),
    );
  }
}