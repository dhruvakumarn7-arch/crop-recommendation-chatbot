/// main.dart
/// ---------
/// The entry point of the Flutter application.
/// Sets up the theme and launches the Crop Advisor Chatbot.

import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const CropAdvisorApp());
}

class CropAdvisorApp extends StatelessWidget {
  const CropAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Recommendation Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7F4),
        fontFamily: 'Roboto',
      ),
      home: const ChatScreen(),
    );
  }
}
