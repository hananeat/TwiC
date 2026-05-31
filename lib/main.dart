import 'package:flutter/material.dart';
import 'screens/splash_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
} //main

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'TwiC',
      debugShowCheckedModeBanner: false,
      home: SplashLogoScreen(),
    );
  } //build
}//MyApp