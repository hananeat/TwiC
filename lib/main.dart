import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/health_data_provider.dart';
import 'screens/splash_logo.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Ensure that the Flutter framework is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => HealthDataProvider()),
      ],
      child: const MyApp(),
    ),
  );
} //main

class MyApp extends StatelessWidget {
  const MyApp({super.key});

   @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TwiC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Sets Poppins as the default font for the entire application
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const SplashLogoScreen(),
    );
  } 
}