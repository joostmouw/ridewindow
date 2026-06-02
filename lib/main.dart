/// Phase 1: minimal MaterialApp boot. Real UI arrives in Phase 4 (Onboarding/Home/Welcome).
library;

import 'package:flutter/material.dart';

void main() {
  runApp(const RideWindowApp());
}

class RideWindowApp extends StatelessWidget {
  const RideWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideWindow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: const Scaffold(
        body: Center(child: Text('RideWindow — domain ready')),
      ),
    );
  }
}
