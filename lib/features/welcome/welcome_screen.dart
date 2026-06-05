import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// WelcomeScreen — het eerste scherm voor een nieuwe gebruiker.
///
/// Toont het fietsicoontje, titel, ondertitel en 'Aan de slag →'-knop.
/// Tapping de knop navigeert naar /onboard via context.go.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🚴',
                style: TextStyle(fontSize: 80),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              const Text(
                'Jouw perfecte rijmoment',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                'Combineer het weerbericht met jouw agenda en ontdek de beste windows om te fietsen.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => context.push('/onboard'),
                  child: const Text('Aan de slag \u2192'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
