import 'package:flutter/material.dart';
import 'package:TwiC/services/impact.dart';
import 'onboarding_screen.dart';
import 'homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:TwiC/utils/app_colors.dart';

// StatefulWidget because the page needs to "react"
// when the user types in the fields or presses the button
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routename = 'LoginPage';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // Controllers: "listen" to what the user types in the fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Impact impact = Impact();

  // This variable controls whether the password is visible or hidden
  bool _isPasswordVisible = false;

  // As in the onboarding screen, dispose() frees memory
  // when the user leaves this screen
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function called when the user presses "Login"
  Future<void> _handleLogin() async {
    // Dismiss the on-screen keyboard
    FocusScope.of(context).unfocus();
    
    final username = _usernameController.text; 
    final password = _passwordController.text;

    // Hide any previous snackbars before showing a new one
    ScaffoldMessenger.of(context).clearSnackBars();

    if (username.isEmpty || password.isEmpty) {
      debugPrint('Empty fields detected. Showing SnackBar.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username or password missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final statusCode = await impact.getAndStoreTokens(username, password);
      debugPrint('Response status: $statusCode');

      if (!mounted) return;

      if (statusCode == 200) {
        // Check if onboarding has already been completed previously
        final sp = await SharedPreferences.getInstance();
        final chickName = sp.getString('chickName');
        final hasChickName = chickName != null && chickName.isNotEmpty;

        if (!mounted) return;

        // Reload all game data and the user profile into memory
        await Provider.of<UserProvider>(context, listen: false).loadUserData();

        if (!mounted) return;

        if (hasChickName) {
          // Success and onboarding already done: navigate to HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Success but onboarding still needed: navigate to Onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      } else {
        // Invalid credentials error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username or password incorrect'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception caught during authentication: $e');
      // In case of a network or connection exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // very light yellow background
      body: SafeArea(
        // SafeArea prevents content from going under
        // the notch or the bottom bar of the iPhone
        child: SingleChildScrollView(
          // SingleChildScrollView allows scrolling
          // when the keyboard opens and pushes the widgets up
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              const SizedBox(height: 40),

              // --- ROW HEADER ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                              height: 1.25,
                            ),
                            children: const [
                              TextSpan(text: 'Move'),
                              TextSpan(
                                text: ' your\nbody,\n',
                                style: TextStyle(color: AppColors.textDark),
                              ),
                              TextSpan(text: 'calm ', 
                                style: TextStyle(color: AppColors.green),
                                ),
                              TextSpan(text: 'your\nmind.', 
                                style: TextStyle(color: AppColors.textDark),
                                ), 
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Take care of yourself\nand your chick!',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chick animation
                  Lottie.asset(
                    'assets/baby-chick.json',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // --- USERNAME FIELD ---
              // TextField is the Flutter widget for text input fields
              TextField(
                controller: _usernameController, // linked to the controller
                keyboardType: TextInputType.text, // keyboard 
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.person_outline_outlined, 
                    color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    // focusedBorder = border when the field is focused
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.green, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- PASSWORD FIELD ---
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, 
                // obscureText: true = shows dots ••••
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.lock_outlined, 
                    color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.green, width: 2),
                  ),
                  // suffixIcon = icon on the RIGHT side of the field
                  // allows toggling password visibility
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      // setState tells Flutter to redraw
                      // the widget with the new value
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- LOGIN BUTTON ---
              SizedBox(
                width: double.infinity, // maximum width
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleLogin, // calls _handleLogin on tap
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green, // green background
                    foregroundColor: Colors.white, // white text
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Log In',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /*
              // --- TEXT BELOW THE BUTTON ---
              // For now it's just decorative, in the future it could
              // lead to a registration screen
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account? ',
                    style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () {
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              

              const SizedBox(height: 40),
              */
            ],
          ),
        ),
      ),
    );
  }
}