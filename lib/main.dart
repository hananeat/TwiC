import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login.dart';
import 'screens/homepage.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final sp = await SharedPreferences.getInstance();
  // Controlliamo se abbiamo memorizzato i token di accesso (utente autenticato)
  final hasAccess = sp.getString('access') != null;
  // Controlliamo se l'onboarding è completato (ossia se è salvato il nome del pulcino)
  final hasChickName = sp.getString('chickName') != null;

  runApp(MyApp(
    hasAccess: hasAccess,
    hasChickName: hasChickName,
  ));
} //main

class MyApp extends StatelessWidget {
  final bool hasAccess;
  final bool hasChickName;

  const MyApp({
    super.key,
    required this.hasAccess,
    required this.hasChickName,
  });

  @override
  Widget build(BuildContext context) {
    // Decidiamo quale schermata iniziale mostrare
    Widget initialScreen;
    if (hasAccess && hasChickName) {
      initialScreen = const HomePage();
    } else if (hasAccess && !hasChickName) {
      initialScreen = const OnboardingScreen();
    } else {
      initialScreen = const LoginPage();
    }

    return MaterialApp(
      title: 'TwiC',
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  } //build
}//MyApp