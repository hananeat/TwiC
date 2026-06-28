import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_balloon/speech_balloon.dart';
import 'package:lottie/lottie.dart';
import '../providers/user_provider.dart';
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
  String _chickName = ''; // start with empty name

  // Controllers for the fourth page (profile setup)
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedSex = 'Female';

  late final AnimationController _lottieController1;
  late final AnimationController _lottieController2;
  
  @override
  void initState() {
    super.initState();
    _lottieController1 = AnimationController(vsync: this);
    _lottieController2 = AnimationController(vsync: this);

    // Listeners to update the active state of the button on Page 4
    _firstNameController.addListener(_onFormInputChanged);
    _lastNameController.addListener(_onFormInputChanged);
    _ageController.addListener(_onFormInputChanged);
  }

  void _onFormInputChanged() {
    setState(() {});
  }

  bool get _isFormValid {
    return _firstNameController.text.trim().isNotEmpty &&
           _lastNameController.text.trim().isNotEmpty &&
           _ageController.text.trim().isNotEmpty;
  }
  
 // Colors for the onboarding screen
  static const Color primaryGreen = Color(0xFF4CAF50);  // verde
  static const Color bgColor = Color(0xFFFFFDE7);       // sfondo giallo chiarissimo
  static const Color textDark = Color(0xFF2A2859);      // testo scuro

  @override
  void dispose() {
    _lottieController1.dispose();
    _lottieController2.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Validate the form fields before proceeding
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final ageText = _ageController.text.trim();
      // 1. Empty field check
      if (firstName.isEmpty || lastName.isEmpty || ageText.isEmpty) {
        debugPrint('Empty fields found in onboarding.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All fields are required.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Interrompe il metodo e non va avanti
      }
      // 2. Check if age is a valid number
      final ageValue = int.tryParse(ageText);
      if (ageValue == null) {
        debugPrint('Age is not a number.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Age must be a number.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Interrompe il metodo e non va avanti
      }

      //Save the data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Salva il nome del pulcino nel provider
      await userProvider.setChickName(_chickName);
      debugPrint('Nome del pulcino salvato in UserProvider: $_chickName');

      // Salva i dettagli del profilo dell'utente nel provider
      await userProvider.setUserProfile(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _selectedSex,
        ageValue,
      );

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
                      _buildPage4(),
                    ],
                  ),
                ),
                // Indicatori di pagina in basso
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => _buildDot(index)),
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
              const double startPoint = 0.25; // Punto di partenza
              const double endPoint = 0.43;  // Punto finale

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
          const SpeechBalloon(
            nipLocation: NipLocation.bottom,
            color: Colors.white,
            borderColor: primaryGreen,
            borderWidth: 3,
            borderRadius: 20,
            height: 55,
            width: 200,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  "Hi! What's my name?",
                  style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                ),
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
              const double startPoint = 0.25; // Punto di partenza //0.43
              const double endPoint = 0.6;  // Punto finale

              // Se invece volessi farla ripetere in loop tra questi due punti, potresti usare:
                _lottieController2.repeat(
                 min: startPoint,
                 max: endPoint, 
                 period: const Duration(milliseconds: 1900)); 
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
                setState(() {
                  _chickName = val.trim();
                });
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
            child: _buildButton(
              "That's the name!",
              isLight: _chickName.trim().isEmpty,
              isEnabled: _chickName.trim().isNotEmpty,
            ),
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
            borderRadius: 20,
            height: 80,
            width: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  "Hi! I'm $_chickName,\nnice to meet you!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                ),
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
          _buildButton("I'm ready!"),
        ],
      ),
    );
  }

  // --- PAGINA 4 ---
  Widget _buildPage4() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const SpeechBalloon(
              nipLocation: NipLocation.bottom,
              color: Colors.white,
              borderColor: primaryGreen,
              borderWidth: 3,
              borderRadius: 20,
              height: 55,
              width: 200,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(
                    "Tell me about yourself!",
                    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Lottie.asset(
              'assets/hatched-chick.json',
              width: 90,
              height: 90,
            ),
            const SizedBox(height: 16),
            const Text(
              'ALMOST THERE!',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'One last step.',
              style: TextStyle(
                fontSize: 32,
                color: textDark,
                fontFamily: 'serif',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This helps us personalise\nyour daily goals.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'First name',
              controller: _firstNameController,
              hintText: 'Sara',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Last name',
              controller: _lastNameController,
              hintText: 'Rossi',
            ),
            const SizedBox(height: 16),
            _buildSexSelector(),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Age',
              controller: _ageController,
              hintText: '15',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _buildButton("Let's get started!", isEnabled: _isFormValid),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- HELPER COMPONENTI INPUT ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: textDark, fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSexSelector() {
    final options = [
      {'id': 'Female', 'label': '♀ Female'},
      {'id': 'Male', 'label': '♂ Male'},
      {'id': 'Other', 'label': '◦ Other'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sex',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: options.map((opt) {
            final isSelected = _selectedSex == opt['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSex = opt['id']!;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGreen.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? primaryGreen : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      opt['label']!,
                      style: TextStyle(
                        color: isSelected ? primaryGreen : textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- PULSANTE GENERICO ---
  Widget _buildButton(String text, {bool isLight = false, bool isOutline = false, bool isEnabled = true}) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: isOutline 
              ? Colors.white 
              : (isLight ? primaryGreen.withOpacity(0.4) : primaryGreen),
          borderRadius: BorderRadius.circular(30),
          border: isOutline 
              ? Border.all(
                  color: isEnabled 
                      ? Colors.grey.withOpacity(0.3) 
                      : Colors.grey.withOpacity(0.2), 
                  width: 1.5,
                ) 
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: isEnabled ? _nextPage : null,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isOutline 
                      ? (isEnabled ? textDark : Colors.grey.withOpacity(0.6))
                      : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} //OnboardingScreen