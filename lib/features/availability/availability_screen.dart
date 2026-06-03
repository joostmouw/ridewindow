import 'package:flutter/material.dart';

/// AvailabilityScreen — stub voor de beschikbaarheidskalender.
///
/// Wave 3 stub: toont een lege Scaffold met AppBar 'Mijn schema'.
/// De volledige 7×24 kalender-grid wordt geimplementeerd in Phase 6.
class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mijn schema')),
      body: const Center(
        child: Text('Beschikbaarheidskalender komt in een volgende update.'),
      ),
    );
  }
}
