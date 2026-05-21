import 'package:flutter/material.dart';
import 'package:speech_balloon/speech_balloon.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routename = 'OnboardingScreen';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  // Variables for the onboarding screen
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controller for the name text field
  final TextEditingController _nameController = TextEditingController();
  String _chickName = 'Pip'; // default name

  late final AnimationController _lottieController1;
  late final AnimationController _lottieController2;
  late final AnimationController _lottieController3;

  @override
  void initState() {
    super.initState();
    _lottieController1 = AnimationController(vsync: this);
    _lottieController2 = AnimationController(vsync: this);
  }


 // Colors for the onboarding screen
  static const Color primaryYellow = Color(0xFFFFD158); // giallo
  static const Color primaryGreen = Color(0xFF4CAF50);  // verde
  static const Color bgColor = Color(0xFFFFFDE7);       // sfondo giallo chiarissimo
  static const Color textDark = Color(0xFF2A2859);      // testo scuro

  @override
  void dispose() {
    _lottieController1.dispose();
    _lottieController2.dispose();
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Salva il nome del pulcino in SharedPreferences
      final sp = await SharedPreferences.getInstance();
      await sp.setString('chickName', _chickName);
      debugPrint('Nome del pulcino salvato in SharedPreferences: $_chickName');

      if (mounted) {
        // Vai alla homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: ((context) => const HomePage())),
        );
      }
    }
  }

  // Build the dots for the page indicator
  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? primaryGreen : primaryGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // To avoid errors when the keyboard opens
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // SafeArea Assicura che tutto quello che c'è al suo interno venga disegnato lontano 
          //dal "Notch" o oltre la barra in basso degli iPhone, per evitare che i tuoi testi siano coperti dalle icone del telefono.
          SafeArea( 
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildPage1(),
                      _buildPage2(),
                      _buildPage3(),
                    ],
                  ),
                ),
                // Indicatori di pagina in basso
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) => _buildDot(index)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PAGINA 1 ---
  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animazione 
          Lottie.asset(
            'assets/hatching_chick.json',
            width: 150,
            height: 150,   
            controller: _lottieController1,
            onLoaded: (composition) {
              _lottieController1.duration = composition.duration;
              
              // Puoi modificare questi valori tra 0.0 (inizio) e 1.0 (fine)
              final double startPoint = 0.25; // Punto di partenza
              final double endPoint = 0.43;  // Punto finale

              //_lottieController1.value = startPoint;
              //_lottieController1.animateTo(endPoint); 
              
              // Se invece volessi farla ripetere in loop tra questi due punti, potresti usare:
                _lottieController1.repeat(
                 min: startPoint,
                 max: endPoint, 
                 period: const Duration(milliseconds: 1000)); 
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Start this beautiful\njourney\nwith us',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              color: textDark,
              fontFamily: 'serif', // Stile elegante simile all'immagine
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Every step, every night of sleep,\nevery smile...it all counts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          _buildButton('Begin the journey!'),
        ],
      ),
    );
  }

  // --- PAGINA 2 ---
  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpeechBalloon(
            nipLocation: NipLocation.bottom,
            color: Colors.white,
            borderColor: primaryGreen,
            borderWidth: 3,
            borderRadius: 20,
            height: 63,
            width: 120,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Hi! What's my name?",
                style: TextStyle(color: primaryGreen),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Animazione del pulcino
            Lottie.asset(
            'assets/hatching_chick.json',
            width: 150,
            height: 150,   
            controller: _lottieController2,
            onLoaded: (composition) {
              _lottieController2.duration = composition.duration;
              
              // Puoi modificare questi valori tra 0.0 (inizio) e 1.0 (fine)
              final double startPoint = 0.25; // Punto di partenza //0.43
              final double endPoint = 0.6;  // Punto finale

              // Se invece volessi farla ripetere in loop tra questi due punti, potresti usare:
                _lottieController2.repeat(
                 min: startPoint,
                 max: endPoint, 
                 period: const Duration(milliseconds: 1200)); 
            },
          ),
          const SizedBox(height: 5),
          const Text(
            'MEET YOUR CHICK',
            style: TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Give it a name!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              color: textDark,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            "It'll be by your side every day.\nChoose wisely!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          
          // Griglia dei nomi suggeriti
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: ['Pip', 'Sol', 'Brio', 'Luna', 'Fil'].map((name) {
              final isSelected = _chickName == name;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _chickName = name;
                    _nameController.clear();
                    // Nascondiamo tastiera se era aperta
                    FocusScope.of(context).unfocus(); 
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGreen.withOpacity(0.3) : primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          // Testo Libero per nome
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: primaryGreen, width: 1.5),
            ),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              onChanged: (val) {
                if (val.isNotEmpty) {
                  setState(() {
                    _chickName = val;
                  });
                } else {
                  setState(() {
                    _chickName = 'Pip'; // default fallback se si svuota il campo
                  });
                }
              },
              style: const TextStyle(color: primaryGreen, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'or type your own...',
                hintStyle: TextStyle(color: primaryGreen.withOpacity(0.5), fontSize: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Pulsante sfumato per confermare o disabilitato visualmente
          Opacity(
            opacity: _currentPage == 1 ? 1.0 : 0.5,
            child: _buildButton("That's the name!", isLight: true),
          ),
        ],
      ),
    );
  }

  // --- PAGINA 3 ---
  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpeechBalloon(
            nipLocation: NipLocation.bottom,
            color: Colors.white,
            borderColor: primaryGreen,
            borderWidth: 3,
            borderRadius: 30,
            height: 80,
            width: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
              "Hi! I'm $_chickName,\nnice to meet you!",
              style: const TextStyle(color: primaryGreen),
              ),
            ),
          ),

          const SizedBox(height: 20),
         
          Lottie.asset(
            'assets/hatching_chick.json',
            width: 150,
            height: 150,
          ),

          const SizedBox(height:10),
         
          const Text(
            'WELCOME',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              color: Color.fromARGB(255, 239, 176, 3),
              fontFamily: 'serif',
            ),
          ),

          const SizedBox(height: 24),
          Text(
            "$_chickName can't wait\nto grow alongside you!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 48),
          _buildButton("Let's get started!"),
        ],
      ),
    );
  }

  // --- PULSANTE GENERICO ---
  Widget _buildButton(String text, {bool isLight = false}) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: isLight ? primaryGreen.withOpacity(0.4) : primaryGreen,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _nextPage,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isLight ? Colors.white : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
} //SplashScreen