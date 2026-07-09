import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_balloon/speech_balloon.dart';
import 'package:lottie/lottie.dart';
import '../providers/user_provider.dart';
import 'homepage.dart';
import 'package:TwiC/utils/app_colors.dart';

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
  DateTime? _selectedDateOfBirth;
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

  }

  void _onFormInputChanged() {
    setState(() {});
  }

  bool get _isFormValid {
    return _firstNameController.text.trim().isNotEmpty &&
           _lastNameController.text.trim().isNotEmpty &&
           _selectedDateOfBirth != null;
  }
  


  @override
  void dispose() {
    _lottieController1.dispose();
    _lottieController2.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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
      // 1. Empty field check
      if (firstName.isEmpty || lastName.isEmpty || _selectedDateOfBirth == null) {
        debugPrint('Empty fields found in onboarding.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All fields are required.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Interrompe il metodo e non va avanti
      }

      //Save the data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Save the chick name in the provider
      await userProvider.setChickName(_chickName);
      debugPrint('Name of chick saved in UserProvider: $_chickName');

      // Save the user profile details in the provider
      await userProvider.setUserProfile(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _selectedSex,
        _selectedDateOfBirth!,
      );

      if (mounted) {
        // Go to the homepage
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
        color: _currentPage == index ? AppColors.green : AppColors.green.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // To avoid errors when the keyboard opens
      backgroundColor: AppColors.background,
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
                    physics: const NeverScrollableScrollPhysics(), // Disabilita lo swipe manuale tra le pagine per impedire di saltare la validazione
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
          // Pulsante Back in alto a sinistra per poter tornare indietro ma in modo controllato
          if (_currentPage > 0)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.green, size: 28),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- PAGE 1 ---
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
              
              // To make it repeat between these two points
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
              color: AppColors.textDark,
              fontFamily: 'serif', 
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

  // --- PAGE 2 ---
  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpeechBalloon(
            nipLocation: NipLocation.bottom,
            color: Colors.white,
            borderColor: AppColors.green,
            borderWidth: 3,
            borderRadius: 20,
            height: 55,
            width: 200,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  "Hi! What's my name?",
                  style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Animation of the chick
            Lottie.asset(
            'assets/hatching_chick.json',
            width: 150,
            height: 150,   
            controller: _lottieController2,
            onLoaded: (composition) {
              _lottieController2.duration = composition.duration;
              
              // You can change these values between 0.0 (start) and 1.0 (end)
              const double startPoint = 0.25; // Starting point //0.43
              const double endPoint = 0.6;  // Ending point

              // If you want it to repeat between these two points, you can use:
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
              color: AppColors.green,
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
              color: AppColors.textDark,
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
          
          // Suggested chick names grid
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
                    // Hide keyboard if it was open
                    FocusScope.of(context).unfocus(); 
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.green.withOpacity(0.3) : AppColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: AppColors.textDark,
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
              border: Border.all(color: AppColors.green, width: 1.5),
            ),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              onChanged: (val) {
                setState(() {
                  _chickName = val.trim();
                });
              },
              style: const TextStyle(color: AppColors.green, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'or type your own...',
                hintStyle: TextStyle(color: AppColors.green.withOpacity(0.5), fontSize: 18),
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

  // --- PAGE 3 ---
  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpeechBalloon(
            nipLocation: NipLocation.bottom,
            color: Colors.white,
            borderColor: AppColors.green,
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
                  style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
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

  // --- PAGE 4 ---
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
              borderColor: AppColors.green,
              borderWidth: 3,
              borderRadius: 20,
              height: 55,
              width: 200,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(
                    "Tell me about yourself!",
                    style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
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
                color: AppColors.green,
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
                color: AppColors.textDark,
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
            _buildDateOfBirthPicker(),
            const SizedBox(height: 32),
            _buildButton("Let's get started!", isEnabled: _isFormValid),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- HELPER COMPONENTS INPUT ---
  //1. Text field: parameters: label, controller, hint text, keyboard type. 
  //Return: Column with a text field. The field is decorated with a border and a shadow.
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
            color: AppColors.green,
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
            style: const TextStyle(color: AppColors.textDark, fontSize: 16),
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
                borderSide: const BorderSide(color: AppColors.green, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
  //2. Sex selector: parameters: none. 
  //Return: Column with a sex selector. 
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
            color: AppColors.green,
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
                    color: isSelected ? AppColors.green.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? AppColors.green : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      opt['label']!,
                      style: TextStyle(
                        color: isSelected ? AppColors.green : AppColors.textDark,
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

  // 3. Generic button: parameters: text, isLight, isOutline, isEnabled. 
  //Return: Button widget.
  //The button is enabled if isEnabled is true. Otherwise, it is disabled.
  Widget _buildButton(String text, {bool isLight = false, bool isOutline = false, bool isEnabled = true}) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: isOutline 
              ? Colors.white 
              : (isLight ? AppColors.green.withOpacity(0.4) : AppColors.green),
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
                      ? (isEnabled ? AppColors.textDark : Colors.grey.withOpacity(0.6))
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

  //4. Date of Birth picker: parameters: none. 
  //Return: Date of Birth picker widget.
  //The widget is a column with a text field and a date picker.
  //The date picker is initialized with the date 2005-01-01 and the user can select any date from 1920 to the current date.
  Widget _buildDateOfBirthPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDateOfBirth ?? DateTime(2005, 1, 1),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.green,
                      onPrimary: Colors.white,
                      surface: AppColors.background,
                      onSurface: AppColors.textDark,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedDateOfBirth = picked;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDateOfBirth != null
                    ? AppColors.green
                    : Colors.grey.withOpacity(0.2),
                width: _selectedDateOfBirth != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateOfBirth != null
                        ? '${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}/${_selectedDateOfBirth!.year}'
                        : 'Select your date of birth',
                    style: TextStyle(
                      color: _selectedDateOfBirth != null
                          ? AppColors.textDark
                          : Colors.grey.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  color: _selectedDateOfBirth != null
                      ? AppColors.green
                      : Colors.grey.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} //OnboardingScreen