import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/splash_logo.dart';
void main() {
  runApp(const MyApp());
} //main

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: LoginPage(),
      home: SplashLogoScreen(),
    );
  } //build
}//MyApp