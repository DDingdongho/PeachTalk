import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const PeachTalkApp());
}

class PeachTalkApp extends StatelessWidget {
  const PeachTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeachTalk',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
