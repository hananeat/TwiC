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

// StatefulWidget perché la pagina deve "reagire" 
// quando l'utente scrive nei campi o preme il bottone
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routename = 'LoginPage';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // Controllers: "ascoltano" cosa scrive l'utente nei campi
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Impact impact = Impact();

  // Questa variabile controlla se la password è visibile o nascosta
  bool _isPasswordVisible = false;



  // Come nell'onboarding screen, dispose() libera la memoria
  // quando l'utente lascia questa schermata
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Funzione chiamata quando l'utente preme "Login"
  Future<void> _handleLogin() async {
    // Chiude la tastiera a schermo
    FocusScope.of(context).unfocus();
    
    final username = _usernameController.text; 
    final password = _passwordController.text;

    // Nascondi eventuali snackbar precedenti prima di mostrarne una nuova
    ScaffoldMessenger.of(context).clearSnackBars();

    if (username.isEmpty || password.isEmpty) {
      debugPrint('Rilevati campi vuoti. Mostro la SnackBar.');
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
        // Legge se l'onboarding è già stato fatto in precedenza
        final sp = await SharedPreferences.getInstance();
        final chickName = sp.getString('chickName');
        final hasChickName = chickName != null && chickName.isNotEmpty;

        if (!mounted) return;

        // Ricarica tutti i dati di gioco e il profilo utente in memoria
        await Provider.of<UserProvider>(context, listen: false).loadUserData();

        if (!mounted) return;

        if (hasChickName) {
          // Successo e onboarding già fatto: naviga alla HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Successo ma onboarding da fare: naviga a Onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      } else {
        // Errore credenziali 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username or password incorrect'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Eccezione catturata durante l\'autenticazione: $e');
      // In caso di eccezione di rete o connessione
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore di connessione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // sfondo giallo chiarissimo
      body: SafeArea(
        // SafeArea evita che il contenuto finisca sotto
        // la "frangetta" o la barra in basso dell'iPhone
        child: SingleChildScrollView(
          // SingleChildScrollView permette di scorrere
          // quando la tastiera si apre e "spinge su" i widget
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
                  // Animazione pulcino
                  Lottie.asset(
                    'assets/baby-chick.json',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // --- CAMPO EMAIL ---
              // TextField è il widget di Flutter per i campi di testo
              TextField(
                controller: _usernameController, // collegato al controller
                keyboardType: TextInputType.emailAddress, // tastiera con la @
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
                    // focusedBorder = bordo quando il campo è selezionato
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.green, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- CAMPO PASSWORD ---
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, 
                // obscureText: true = mostra i pallini ••••
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
                  // suffixIcon = icona a DESTRA del campo
                  // permette di mostrare/nascondere la password
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      // setState dice a Flutter di ridisegnare
                      // il widget con il nuovo valore
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- BOTTONE LOGIN ---
              SizedBox(
                width: double.infinity, // larghezza massima
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleLogin, // chiama _handleLogin al tap
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green, // sfondo verde
                    foregroundColor: Colors.white, // testo bianco
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
              // --- TESTO SOTTO IL BOTTONE ---
              // Per ora è solo estetico, in futuro può
              // portare a una schermata di registrazione
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Non hai un account? ',
                    style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () {
                    },
                    child: const Text(
                      'Registrati',
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