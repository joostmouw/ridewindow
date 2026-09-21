// lib/theme/ride_mark.dart
// Het merkteken links op een geplande rit: één fietser als je alleen gaat,
// een peloton van drie als de rit gedeeld is (schets 014, gekozen 2026-09-21).
//
// **Waarom dit een pad is en geen icoon uit het font.** Elk ander icoon in deze
// app is een `IconData` uit `Phosphor.ttf`, en dat blijft zo -- maar `Icon` legt
// zijn glyph altijd in een vierkant van `size x size`, en het peloton is 2,3 keer
// zo breed als hoog. Als `IconData` zou het over de tekst ernaast heen lopen
// terwijl de lay-out denkt dat het 20px breed is.
//
// **Waar de tekening vandaan komt.** Het is de échte Phosphor-fietser
// (`person-simple-bike`, 0xe734) drie keer over elkaar, met dezelfde uitsparing
// die Phosphor zelf gebruikt waar figuren elkaar overlappen. Schaal 0,82,
// onderlinge afstand 420, tussenruimte 86 en de helft van het lijndikteverschil
// hersteld -- krimpen maakt de lijn dunner dan de iconen ernaast, volledig
// herstellen maakt hem te vet en loopt de wielen dicht (gemeten in
// `.planning/sketches/014-peloton-rij/icoon.html`). De vormen zijn daarna tot
// één pad samengevoegd; de coordinaten hieronder zijn uitgedrukt in eenheden
// waarin de hoogte 1,0 is, zodat `size` net als bij `Icon` de hoogte bepaalt.
//
// Opnieuw genereren gaat met het script in de schetsmap; handmatig sleutelen aan
// de getallen heeft geen zin.

import 'package:flutter/widgets.dart';

/// Wat voor rit dit is: alleen jij, of met een peloton.
enum RideMarkKind { solo, peloton }

/// Het merkteken, op dezelfde hoogte als een `Icon` van dezelfde `size`.
///
/// De breedte volgt uit de tekening ([RideMarkKind.peloton] is breder dan hoog),
/// dus geef hem geen vaste breedte mee -- hij meet zichzelf op.
class RideMark extends StatelessWidget {
  const RideMark({
    super.key,
    required this.kind,
    required this.size,
    this.color,
  });

  final RideMarkKind kind;

  /// De hoogte, precies zoals `Icon.size` de hoogte van een icoon bepaalt.
  final double size;

  /// Standaard de kleur van de omliggende `IconTheme`, net als `Icon`.
  final Color? color;

  double get _aspect => switch (kind) {
        RideMarkKind.solo => _soloAspect,
        RideMarkKind.peloton => _pelotonAspect,
      };

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return ExcludeSemantics(
      child: SizedBox(
        width: size * _aspect,
        height: size,
        child: CustomPaint(
          painter: _RideMarkPainter(kind: kind, color: resolved, size: size),
        ),
      ),
    );
  }
}

class _RideMarkPainter extends CustomPainter {
  const _RideMarkPainter({
    required this.kind,
    required this.color,
    required this.size,
  });

  final RideMarkKind kind;
  final Color color;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final path = switch (kind) {
      RideMarkKind.solo => _soloPath(canvasSize.height),
      RideMarkKind.peloton => _pelotonPath(canvasSize.height),
    };
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RideMarkPainter old) =>
      old.kind != kind || old.color != color || old.size != size;
}

const double _soloAspect = 1.1509;
const double _pelotonAspect = 2.3207;

Path _soloPath(double s) => Path()
      ..moveTo(0.7453 * s, 0.3113 * s)
      ..quadraticBezierTo(0.7995 * s, 0.3113 * s, 0.8384 * s, 0.2724 * s)
      ..quadraticBezierTo(0.8774 * s, 0.2335 * s, 0.8774 * s, 0.1792 * s)
      ..quadraticBezierTo(0.8774 * s, 0.1250 * s, 0.8384 * s, 0.0861 * s)
      ..quadraticBezierTo(0.7995 * s, 0.0472 * s, 0.7453 * s, 0.0472 * s)
      ..quadraticBezierTo(0.6910 * s, 0.0472 * s, 0.6521 * s, 0.0861 * s)
      ..quadraticBezierTo(0.6132 * s, 0.1250 * s, 0.6132 * s, 0.1792 * s)
      ..quadraticBezierTo(0.6132 * s, 0.2335 * s, 0.6521 * s, 0.2724 * s)
      ..quadraticBezierTo(0.6910 * s, 0.3113 * s, 0.7453 * s, 0.3113 * s)
      ..close()
      ..moveTo(0.7453 * s, 0.1226 * s)
      ..quadraticBezierTo(0.7689 * s, 0.1226 * s, 0.7854 * s, 0.1392 * s)
      ..quadraticBezierTo(0.8019 * s, 0.1557 * s, 0.8019 * s, 0.1792 * s)
      ..quadraticBezierTo(0.8019 * s, 0.2028 * s, 0.7854 * s, 0.2193 * s)
      ..quadraticBezierTo(0.7689 * s, 0.2358 * s, 0.7453 * s, 0.2358 * s)
      ..quadraticBezierTo(0.7217 * s, 0.2358 * s, 0.7052 * s, 0.2193 * s)
      ..quadraticBezierTo(0.6887 * s, 0.2028 * s, 0.6887 * s, 0.1792 * s)
      ..quadraticBezierTo(0.6887 * s, 0.1557 * s, 0.7052 * s, 0.1392 * s)
      ..quadraticBezierTo(0.7217 * s, 0.1226 * s, 0.7453 * s, 0.1226 * s)
      ..close()
      ..moveTo(0.9151 * s, 0.5755 * s)
      ..quadraticBezierTo(0.8373 * s, 0.5755 * s, 0.7818 * s, 0.6309 * s)
      ..quadraticBezierTo(0.7264 * s, 0.6863 * s, 0.7264 * s, 0.7642 * s)
      ..quadraticBezierTo(0.7264 * s, 0.8420 * s, 0.7818 * s, 0.8974 * s)
      ..quadraticBezierTo(0.8373 * s, 0.9528 * s, 0.9151 * s, 0.9528 * s)
      ..quadraticBezierTo(0.9929 * s, 0.9528 * s, 1.0483 * s, 0.8974 * s)
      ..quadraticBezierTo(1.1038 * s, 0.8420 * s, 1.1038 * s, 0.7642 * s)
      ..quadraticBezierTo(1.1038 * s, 0.6863 * s, 1.0483 * s, 0.6309 * s)
      ..quadraticBezierTo(0.9929 * s, 0.5755 * s, 0.9151 * s, 0.5755 * s)
      ..close()
      ..moveTo(0.9151 * s, 0.8774 * s)
      ..quadraticBezierTo(0.8679 * s, 0.8774 * s, 0.8349 * s, 0.8443 * s)
      ..quadraticBezierTo(0.8019 * s, 0.8113 * s, 0.8019 * s, 0.7642 * s)
      ..quadraticBezierTo(0.8019 * s, 0.7170 * s, 0.8349 * s, 0.6840 * s)
      ..quadraticBezierTo(0.8679 * s, 0.6509 * s, 0.9151 * s, 0.6509 * s)
      ..quadraticBezierTo(0.9623 * s, 0.6509 * s, 0.9953 * s, 0.6840 * s)
      ..quadraticBezierTo(1.0283 * s, 0.7170 * s, 1.0283 * s, 0.7642 * s)
      ..quadraticBezierTo(1.0283 * s, 0.8113 * s, 0.9953 * s, 0.8443 * s)
      ..quadraticBezierTo(0.9623 * s, 0.8774 * s, 0.9151 * s, 0.8774 * s)
      ..close()
      ..moveTo(0.2358 * s, 0.5755 * s)
      ..quadraticBezierTo(0.1580 * s, 0.5755 * s, 0.1026 * s, 0.6309 * s)
      ..quadraticBezierTo(0.0472 * s, 0.6863 * s, 0.0472 * s, 0.7642 * s)
      ..quadraticBezierTo(0.0472 * s, 0.8420 * s, 0.1026 * s, 0.8974 * s)
      ..quadraticBezierTo(0.1580 * s, 0.9528 * s, 0.2358 * s, 0.9528 * s)
      ..quadraticBezierTo(0.3137 * s, 0.9528 * s, 0.3691 * s, 0.8974 * s)
      ..quadraticBezierTo(0.4245 * s, 0.8420 * s, 0.4245 * s, 0.7642 * s)
      ..quadraticBezierTo(0.4245 * s, 0.6863 * s, 0.3691 * s, 0.6309 * s)
      ..quadraticBezierTo(0.3137 * s, 0.5755 * s, 0.2358 * s, 0.5755 * s)
      ..close()
      ..moveTo(0.2358 * s, 0.8774 * s)
      ..quadraticBezierTo(0.1887 * s, 0.8774 * s, 0.1557 * s, 0.8443 * s)
      ..quadraticBezierTo(0.1226 * s, 0.8113 * s, 0.1226 * s, 0.7642 * s)
      ..quadraticBezierTo(0.1226 * s, 0.7170 * s, 0.1557 * s, 0.6840 * s)
      ..quadraticBezierTo(0.1887 * s, 0.6509 * s, 0.2358 * s, 0.6509 * s)
      ..quadraticBezierTo(0.2830 * s, 0.6509 * s, 0.3160 * s, 0.6840 * s)
      ..quadraticBezierTo(0.3491 * s, 0.7170 * s, 0.3491 * s, 0.7642 * s)
      ..quadraticBezierTo(0.3491 * s, 0.8113 * s, 0.3160 * s, 0.8443 * s)
      ..quadraticBezierTo(0.2830 * s, 0.8774 * s, 0.2358 * s, 0.8774 * s)
      ..close()
      ..moveTo(0.8774 * s, 0.5000 * s)
      ..lineTo(0.6887 * s, 0.5000 * s)
      ..quadraticBezierTo(0.6887 * s, 0.5000 * s, 0.6887 * s, 0.5000 * s)
      ..quadraticBezierTo(0.6887 * s, 0.5000 * s, 0.6887 * s, 0.5000 * s)
      ..quadraticBezierTo(0.6804 * s, 0.5000 * s, 0.6739 * s, 0.4971 * s)
      ..quadraticBezierTo(0.6675 * s, 0.4941 * s, 0.6616 * s, 0.4894 * s)
      ..lineTo(0.5377 * s, 0.3644 * s)
      ..lineTo(0.4399 * s, 0.4623 * s)
      ..lineTo(0.6026 * s, 0.6238 * s)
      ..quadraticBezierTo(0.6073 * s, 0.6297 * s, 0.6103 * s, 0.6362 * s)
      ..quadraticBezierTo(0.6132 * s, 0.6427 * s, 0.6132 * s, 0.6509 * s)
      ..quadraticBezierTo(0.6132 * s, 0.6509 * s, 0.6132 * s, 0.6509 * s)
      ..quadraticBezierTo(0.6132 * s, 0.6509 * s, 0.6132 * s, 0.6509 * s)
      ..lineTo(0.6132 * s, 0.8774 * s)
      ..quadraticBezierTo(0.6132 * s, 0.8927 * s, 0.6020 * s, 0.9039 * s)
      ..quadraticBezierTo(0.5908 * s, 0.9151 * s, 0.5755 * s, 0.9151 * s)
      ..quadraticBezierTo(0.5601 * s, 0.9151 * s, 0.5489 * s, 0.9039 * s)
      ..quadraticBezierTo(0.5377 * s, 0.8927 * s, 0.5377 * s, 0.8774 * s)
      ..lineTo(0.5377 * s, 0.6663 * s)
      ..lineTo(0.3597 * s, 0.4894 * s)
      ..quadraticBezierTo(0.3550 * s, 0.4835 * s, 0.3520 * s, 0.4770 * s)
      ..quadraticBezierTo(0.3491 * s, 0.4705 * s, 0.3491 * s, 0.4623 * s)
      ..quadraticBezierTo(0.3491 * s, 0.4540 * s, 0.3520 * s, 0.4475 * s)
      ..quadraticBezierTo(0.3550 * s, 0.4410 * s, 0.3597 * s, 0.4351 * s)
      ..lineTo(0.5106 * s, 0.2842 * s)
      ..quadraticBezierTo(0.5165 * s, 0.2795 * s, 0.5230 * s, 0.2765 * s)
      ..quadraticBezierTo(0.5295 * s, 0.2736 * s, 0.5377 * s, 0.2736 * s)
      ..quadraticBezierTo(0.5460 * s, 0.2736 * s, 0.5525 * s, 0.2765 * s)
      ..quadraticBezierTo(0.5590 * s, 0.2795 * s, 0.5649 * s, 0.2842 * s)
      ..lineTo(0.7040 * s, 0.4245 * s)
      ..lineTo(0.8774 * s, 0.4245 * s)
      ..quadraticBezierTo(0.8927 * s, 0.4245 * s, 0.9039 * s, 0.4357 * s)
      ..quadraticBezierTo(0.9151 * s, 0.4469 * s, 0.9151 * s, 0.4623 * s)
      ..quadraticBezierTo(0.9151 * s, 0.4776 * s, 0.9039 * s, 0.4888 * s)
      ..quadraticBezierTo(0.8927 * s, 0.5000 * s, 0.8774 * s, 0.5000 * s)
      ..close();

Path _pelotonPath(double s) => Path()
      ..moveTo(0.2433 * s, 0.5693 * s)
      ..quadraticBezierTo(0.1660 * s, 0.5693 * s, 0.1109 * s, 0.6244 * s)
      ..quadraticBezierTo(0.0559 * s, 0.6794 * s, 0.0559 * s, 0.7567 * s)
      ..quadraticBezierTo(0.0559 * s, 0.8340 * s, 0.1109 * s, 0.8891 * s)
      ..quadraticBezierTo(0.1660 * s, 0.9441 * s, 0.2433 * s, 0.9441 * s)
      ..quadraticBezierTo(0.3206 * s, 0.9441 * s, 0.3756 * s, 0.8891 * s)
      ..quadraticBezierTo(0.4307 * s, 0.8340 * s, 0.4307 * s, 0.7567 * s)
      ..quadraticBezierTo(0.4307 * s, 0.6794 * s, 0.3756 * s, 0.6244 * s)
      ..quadraticBezierTo(0.3206 * s, 0.5693 * s, 0.2433 * s, 0.5693 * s)
      ..close()
      ..moveTo(2.0774 * s, 0.5693 * s)
      ..quadraticBezierTo(2.0001 * s, 0.5693 * s, 1.9450 * s, 0.6244 * s)
      ..quadraticBezierTo(1.8900 * s, 0.6794 * s, 1.8900 * s, 0.7567 * s)
      ..quadraticBezierTo(1.8900 * s, 0.8340 * s, 1.9450 * s, 0.8891 * s)
      ..quadraticBezierTo(2.0001 * s, 0.9441 * s, 2.0774 * s, 0.9441 * s)
      ..quadraticBezierTo(2.1547 * s, 0.9441 * s, 2.2097 * s, 0.8891 * s)
      ..quadraticBezierTo(2.2648 * s, 0.8340 * s, 2.2648 * s, 0.7567 * s)
      ..quadraticBezierTo(2.2648 * s, 0.6794 * s, 2.2097 * s, 0.6244 * s)
      ..quadraticBezierTo(2.1547 * s, 0.5693 * s, 2.0774 * s, 0.5693 * s)
      ..close()
      ..moveTo(0.8303 * s, 0.5693 * s)
      ..quadraticBezierTo(0.7530 * s, 0.5693 * s, 0.6979 * s, 0.6244 * s)
      ..quadraticBezierTo(0.6429 * s, 0.6794 * s, 0.6429 * s, 0.7567 * s)
      ..quadraticBezierTo(0.6429 * s, 0.8340 * s, 0.6979 * s, 0.8891 * s)
      ..quadraticBezierTo(0.7530 * s, 0.9441 * s, 0.8303 * s, 0.9441 * s)
      ..quadraticBezierTo(0.9076 * s, 0.9441 * s, 0.9626 * s, 0.8891 * s)
      ..quadraticBezierTo(1.0177 * s, 0.8340 * s, 1.0177 * s, 0.7567 * s)
      ..quadraticBezierTo(1.0177 * s, 0.6794 * s, 0.9626 * s, 0.6244 * s)
      ..quadraticBezierTo(0.9076 * s, 0.5693 * s, 0.8303 * s, 0.5693 * s)
      ..close()
      ..moveTo(1.4173 * s, 0.5693 * s)
      ..quadraticBezierTo(1.3400 * s, 0.5693 * s, 1.2849 * s, 0.6244 * s)
      ..quadraticBezierTo(1.2299 * s, 0.6794 * s, 1.2299 * s, 0.7567 * s)
      ..quadraticBezierTo(1.2299 * s, 0.8340 * s, 1.2849 * s, 0.8891 * s)
      ..quadraticBezierTo(1.3400 * s, 0.9441 * s, 1.4173 * s, 0.9441 * s)
      ..quadraticBezierTo(1.4946 * s, 0.9441 * s, 1.5496 * s, 0.8891 * s)
      ..quadraticBezierTo(1.6047 * s, 0.8340 * s, 1.6047 * s, 0.7567 * s)
      ..quadraticBezierTo(1.6047 * s, 0.6794 * s, 1.5496 * s, 0.6244 * s)
      ..quadraticBezierTo(1.4946 * s, 0.5693 * s, 1.4173 * s, 0.5693 * s)
      ..close()
      ..moveTo(2.0407 * s, 0.5040 * s)
      ..quadraticBezierTo(2.0573 * s, 0.5040 * s, 2.0693 * s, 0.4920 * s)
      ..quadraticBezierTo(2.0814 * s, 0.4799 * s, 2.0814 * s, 0.4633 * s)
      ..quadraticBezierTo(2.0814 * s, 0.4468 * s, 2.0693 * s, 0.4347 * s)
      ..quadraticBezierTo(2.0573 * s, 0.4226 * s, 2.0407 * s, 0.4226 * s)
      ..lineTo(1.8739 * s, 0.4226 * s)
      ..lineTo(1.7399 * s, 0.2874 * s)
      ..quadraticBezierTo(1.7397 * s, 0.2873 * s, 1.7395 * s, 0.2871 * s)
      ..quadraticBezierTo(1.7334 * s, 0.2822 * s, 1.7266 * s, 0.2792 * s)
      ..quadraticBezierTo(1.7195 * s, 0.2759 * s, 1.7106 * s, 0.2759 * s)
      ..quadraticBezierTo(1.7018 * s, 0.2759 * s, 1.6947 * s, 0.2792 * s)
      ..quadraticBezierTo(1.6879 * s, 0.2822 * s, 1.6818 * s, 0.2871 * s)
      ..quadraticBezierTo(1.6816 * s, 0.2873 * s, 1.6814 * s, 0.2874 * s)
      ..lineTo(1.5347 * s, 0.4341 * s)
      ..quadraticBezierTo(1.5346 * s, 0.4343 * s, 1.5345 * s, 0.4345 * s)
      ..quadraticBezierTo(1.5296 * s, 0.4406 * s, 1.5265 * s, 0.4473 * s)
      ..quadraticBezierTo(1.5233 * s, 0.4544 * s, 1.5233 * s, 0.4633 * s)
      ..quadraticBezierTo(1.5233 * s, 0.4722 * s, 1.5265 * s, 0.4793 * s)
      ..quadraticBezierTo(1.5296 * s, 0.4861 * s, 1.5345 * s, 0.4922 * s)
      ..quadraticBezierTo(1.5346 * s, 0.4924 * s, 1.5348 * s, 0.4925 * s)
      ..lineTo(1.7066 * s, 0.6633 * s)
      ..lineTo(1.7066 * s, 0.8667 * s)
      ..quadraticBezierTo(1.7066 * s, 0.8833 * s, 1.7187 * s, 0.8954 * s)
      ..quadraticBezierTo(1.7308 * s, 0.9074 * s, 1.7473 * s, 0.9074 * s)
      ..quadraticBezierTo(1.7639 * s, 0.9074 * s, 1.7759 * s, 0.8954 * s)
      ..quadraticBezierTo(1.7880 * s, 0.8833 * s, 1.7880 * s, 0.8667 * s)
      ..lineTo(1.7880 * s, 0.6467 * s)
      ..quadraticBezierTo(1.7880 * s, 0.6378 * s, 1.7848 * s, 0.6307 * s)
      ..quadraticBezierTo(1.7817 * s, 0.6239 * s, 1.7768 * s, 0.6178 * s)
      ..quadraticBezierTo(1.7767 * s, 0.6176 * s, 1.7765 * s, 0.6175 * s)
      ..lineTo(1.6212 * s, 0.4633 * s)
      ..lineTo(1.7106 * s, 0.3739 * s)
      ..lineTo(1.8281 * s, 0.4925 * s)
      ..quadraticBezierTo(1.8283 * s, 0.4927 * s, 1.8285 * s, 0.4928 * s)
      ..quadraticBezierTo(1.8346 * s, 0.4977 * s, 1.8413 * s, 0.5008 * s)
      ..quadraticBezierTo(1.8484 * s, 0.5040 * s, 1.8573 * s, 0.5040 * s)
      ..close()
      ..moveTo(1.4537 * s, 0.5040 * s)
      ..quadraticBezierTo(1.4626 * s, 0.5040 * s, 1.4702 * s, 0.5005 * s)
      ..quadraticBezierTo(1.4632 * s, 0.4831 * s, 1.4632 * s, 0.4633 * s)
      ..quadraticBezierTo(1.4632 * s, 0.4435 * s, 1.4702 * s, 0.4261 * s)
      ..quadraticBezierTo(1.4626 * s, 0.4226 * s, 1.4537 * s, 0.4226 * s)
      ..lineTo(1.2869 * s, 0.4226 * s)
      ..lineTo(1.1529 * s, 0.2874 * s)
      ..quadraticBezierTo(1.1527 * s, 0.2873 * s, 1.1525 * s, 0.2871 * s)
      ..quadraticBezierTo(1.1464 * s, 0.2822 * s, 1.1396 * s, 0.2792 * s)
      ..quadraticBezierTo(1.1326 * s, 0.2759 * s, 1.1237 * s, 0.2759 * s)
      ..quadraticBezierTo(1.1148 * s, 0.2759 * s, 1.1077 * s, 0.2792 * s)
      ..quadraticBezierTo(1.1009 * s, 0.2822 * s, 1.0948 * s, 0.2871 * s)
      ..quadraticBezierTo(1.0946 * s, 0.2873 * s, 1.0945 * s, 0.2874 * s)
      ..lineTo(0.9478 * s, 0.4341 * s)
      ..quadraticBezierTo(0.9476 * s, 0.4343 * s, 0.9475 * s, 0.4345 * s)
      ..quadraticBezierTo(0.9426 * s, 0.4406 * s, 0.9395 * s, 0.4473 * s)
      ..quadraticBezierTo(0.9363 * s, 0.4544 * s, 0.9363 * s, 0.4633 * s)
      ..quadraticBezierTo(0.9363 * s, 0.4722 * s, 0.9395 * s, 0.4793 * s)
      ..quadraticBezierTo(0.9426 * s, 0.4861 * s, 0.9475 * s, 0.4922 * s)
      ..quadraticBezierTo(0.9476 * s, 0.4924 * s, 0.9478 * s, 0.4925 * s)
      ..lineTo(1.1196 * s, 0.6633 * s)
      ..lineTo(1.1196 * s, 0.8667 * s)
      ..quadraticBezierTo(1.1196 * s, 0.8833 * s, 1.1317 * s, 0.8954 * s)
      ..quadraticBezierTo(1.1438 * s, 0.9074 * s, 1.1603 * s, 0.9074 * s)
      ..quadraticBezierTo(1.1769 * s, 0.9074 * s, 1.1890 * s, 0.8954 * s)
      ..quadraticBezierTo(1.1974 * s, 0.8869 * s, 1.2000 * s, 0.8762 * s)
      ..quadraticBezierTo(1.1698 * s, 0.8226 * s, 1.1698 * s, 0.7567 * s)
      ..quadraticBezierTo(1.1698 * s, 0.6908 * s, 1.2000 * s, 0.6372 * s)
      ..quadraticBezierTo(1.1992 * s, 0.6338 * s, 1.1978 * s, 0.6307 * s)
      ..quadraticBezierTo(1.1947 * s, 0.6239 * s, 1.1898 * s, 0.6178 * s)
      ..quadraticBezierTo(1.1897 * s, 0.6176 * s, 1.1895 * s, 0.6175 * s)
      ..lineTo(1.0342 * s, 0.4633 * s)
      ..lineTo(1.1236 * s, 0.3739 * s)
      ..lineTo(1.2411 * s, 0.4925 * s)
      ..quadraticBezierTo(1.2413 * s, 0.4927 * s, 1.2415 * s, 0.4928 * s)
      ..quadraticBezierTo(1.2476 * s, 0.4977 * s, 1.2544 * s, 0.5008 * s)
      ..quadraticBezierTo(1.2615 * s, 0.5040 * s, 1.2703 * s, 0.5040 * s)
      ..close()
      ..moveTo(0.8667 * s, 0.5040 * s)
      ..quadraticBezierTo(0.8756 * s, 0.5040 * s, 0.8832 * s, 0.5005 * s)
      ..quadraticBezierTo(0.8762 * s, 0.4831 * s, 0.8762 * s, 0.4633 * s)
      ..quadraticBezierTo(0.8762 * s, 0.4435 * s, 0.8832 * s, 0.4261 * s)
      ..quadraticBezierTo(0.8756 * s, 0.4226 * s, 0.8667 * s, 0.4226 * s)
      ..lineTo(0.6999 * s, 0.4226 * s)
      ..lineTo(0.5659 * s, 0.2874 * s)
      ..quadraticBezierTo(0.5657 * s, 0.2873 * s, 0.5655 * s, 0.2871 * s)
      ..quadraticBezierTo(0.5594 * s, 0.2822 * s, 0.5527 * s, 0.2792 * s)
      ..quadraticBezierTo(0.5456 * s, 0.2759 * s, 0.5367 * s, 0.2759 * s)
      ..quadraticBezierTo(0.5278 * s, 0.2759 * s, 0.5207 * s, 0.2792 * s)
      ..quadraticBezierTo(0.5139 * s, 0.2822 * s, 0.5078 * s, 0.2871 * s)
      ..quadraticBezierTo(0.5076 * s, 0.2873 * s, 0.5075 * s, 0.2874 * s)
      ..lineTo(0.3608 * s, 0.4341 * s)
      ..quadraticBezierTo(0.3606 * s, 0.4343 * s, 0.3605 * s, 0.4345 * s)
      ..quadraticBezierTo(0.3556 * s, 0.4406 * s, 0.3525 * s, 0.4473 * s)
      ..quadraticBezierTo(0.3493 * s, 0.4544 * s, 0.3493 * s, 0.4633 * s)
      ..quadraticBezierTo(0.3493 * s, 0.4722 * s, 0.3525 * s, 0.4793 * s)
      ..quadraticBezierTo(0.3556 * s, 0.4861 * s, 0.3605 * s, 0.4922 * s)
      ..quadraticBezierTo(0.3606 * s, 0.4924 * s, 0.3608 * s, 0.4925 * s)
      ..lineTo(0.5326 * s, 0.6633 * s)
      ..lineTo(0.5326 * s, 0.8667 * s)
      ..quadraticBezierTo(0.5326 * s, 0.8833 * s, 0.5447 * s, 0.8954 * s)
      ..quadraticBezierTo(0.5568 * s, 0.9074 * s, 0.5733 * s, 0.9074 * s)
      ..quadraticBezierTo(0.5899 * s, 0.9074 * s, 0.6020 * s, 0.8954 * s)
      ..quadraticBezierTo(0.6105 * s, 0.8869 * s, 0.6130 * s, 0.8762 * s)
      ..quadraticBezierTo(0.5828 * s, 0.8226 * s, 0.5828 * s, 0.7567 * s)
      ..quadraticBezierTo(0.5828 * s, 0.6908 * s, 0.6130 * s, 0.6372 * s)
      ..quadraticBezierTo(0.6122 * s, 0.6338 * s, 0.6108 * s, 0.6307 * s)
      ..quadraticBezierTo(0.6077 * s, 0.6239 * s, 0.6028 * s, 0.6178 * s)
      ..quadraticBezierTo(0.6027 * s, 0.6176 * s, 0.6025 * s, 0.6175 * s)
      ..lineTo(0.4473 * s, 0.4633 * s)
      ..lineTo(0.5367 * s, 0.3739 * s)
      ..lineTo(0.6541 * s, 0.4925 * s)
      ..quadraticBezierTo(0.6543 * s, 0.4927 * s, 0.6545 * s, 0.4928 * s)
      ..quadraticBezierTo(0.6606 * s, 0.4977 * s, 0.6674 * s, 0.5008 * s)
      ..quadraticBezierTo(0.6745 * s, 0.5040 * s, 0.6834 * s, 0.5040 * s)
      ..close()
      ..moveTo(1.9123 * s, 0.3207 * s)
      ..quadraticBezierTo(1.9667 * s, 0.3207 * s, 2.0057 * s, 0.2817 * s)
      ..quadraticBezierTo(2.0447 * s, 0.2427 * s, 2.0447 * s, 0.1883 * s)
      ..quadraticBezierTo(2.0447 * s, 0.1339 * s, 2.0057 * s, 0.0949 * s)
      ..quadraticBezierTo(1.9667 * s, 0.0559 * s, 1.9123 * s, 0.0559 * s)
      ..quadraticBezierTo(1.8580 * s, 0.0559 * s, 1.8190 * s, 0.0949 * s)
      ..quadraticBezierTo(1.7800 * s, 0.1339 * s, 1.7800 * s, 0.1883 * s)
      ..quadraticBezierTo(1.7800 * s, 0.2427 * s, 1.8190 * s, 0.2817 * s)
      ..quadraticBezierTo(1.8580 * s, 0.3207 * s, 1.9123 * s, 0.3207 * s)
      ..close()
      ..moveTo(0.7384 * s, 0.3207 * s)
      ..quadraticBezierTo(0.7928 * s, 0.3207 * s, 0.8318 * s, 0.2817 * s)
      ..quadraticBezierTo(0.8708 * s, 0.2427 * s, 0.8708 * s, 0.1883 * s)
      ..quadraticBezierTo(0.8708 * s, 0.1339 * s, 0.8318 * s, 0.0949 * s)
      ..quadraticBezierTo(0.7928 * s, 0.0559 * s, 0.7384 * s, 0.0559 * s)
      ..quadraticBezierTo(0.6840 * s, 0.0559 * s, 0.6450 * s, 0.0949 * s)
      ..quadraticBezierTo(0.6060 * s, 0.1339 * s, 0.6060 * s, 0.1883 * s)
      ..quadraticBezierTo(0.6060 * s, 0.2427 * s, 0.6450 * s, 0.2817 * s)
      ..quadraticBezierTo(0.6840 * s, 0.3207 * s, 0.7384 * s, 0.3207 * s)
      ..close()
      ..moveTo(1.3254 * s, 0.3207 * s)
      ..quadraticBezierTo(1.3797 * s, 0.3207 * s, 1.4187 * s, 0.2817 * s)
      ..quadraticBezierTo(1.4577 * s, 0.2427 * s, 1.4577 * s, 0.1883 * s)
      ..quadraticBezierTo(1.4577 * s, 0.1339 * s, 1.4187 * s, 0.0949 * s)
      ..quadraticBezierTo(1.3797 * s, 0.0559 * s, 1.3254 * s, 0.0559 * s)
      ..quadraticBezierTo(1.2710 * s, 0.0559 * s, 1.2320 * s, 0.0949 * s)
      ..quadraticBezierTo(1.1930 * s, 0.1339 * s, 1.1930 * s, 0.1883 * s)
      ..quadraticBezierTo(1.1930 * s, 0.2427 * s, 1.2320 * s, 0.2817 * s)
      ..quadraticBezierTo(1.2710 * s, 0.3207 * s, 1.3254 * s, 0.3207 * s)
      ..close()
      ..moveTo(0.2433 * s, 0.8627 * s)
      ..quadraticBezierTo(0.1991 * s, 0.8627 * s, 0.1682 * s, 0.8318 * s)
      ..quadraticBezierTo(0.1373 * s, 0.8009 * s, 0.1373 * s, 0.7567 * s)
      ..quadraticBezierTo(0.1373 * s, 0.7125 * s, 0.1682 * s, 0.6816 * s)
      ..quadraticBezierTo(0.1991 * s, 0.6507 * s, 0.2433 * s, 0.6507 * s)
      ..quadraticBezierTo(0.2875 * s, 0.6507 * s, 0.3184 * s, 0.6816 * s)
      ..quadraticBezierTo(0.3493 * s, 0.7125 * s, 0.3493 * s, 0.7567 * s)
      ..quadraticBezierTo(0.3493 * s, 0.8009 * s, 0.3184 * s, 0.8318 * s)
      ..quadraticBezierTo(0.2875 * s, 0.8627 * s, 0.2433 * s, 0.8627 * s)
      ..close()
      ..moveTo(2.0774 * s, 0.8627 * s)
      ..quadraticBezierTo(2.0332 * s, 0.8627 * s, 2.0023 * s, 0.8318 * s)
      ..quadraticBezierTo(1.9714 * s, 0.8009 * s, 1.9714 * s, 0.7567 * s)
      ..quadraticBezierTo(1.9714 * s, 0.7125 * s, 2.0023 * s, 0.6816 * s)
      ..quadraticBezierTo(2.0332 * s, 0.6507 * s, 2.0774 * s, 0.6507 * s)
      ..quadraticBezierTo(2.1215 * s, 0.6507 * s, 2.1525 * s, 0.6816 * s)
      ..quadraticBezierTo(2.1834 * s, 0.7125 * s, 2.1834 * s, 0.7567 * s)
      ..quadraticBezierTo(2.1834 * s, 0.8009 * s, 2.1525 * s, 0.8318 * s)
      ..quadraticBezierTo(2.1215 * s, 0.8627 * s, 2.0774 * s, 0.8627 * s)
      ..close()
      ..moveTo(1.4173 * s, 0.8627 * s)
      ..quadraticBezierTo(1.3731 * s, 0.8627 * s, 1.3422 * s, 0.8318 * s)
      ..quadraticBezierTo(1.3113 * s, 0.8009 * s, 1.3113 * s, 0.7567 * s)
      ..quadraticBezierTo(1.3113 * s, 0.7125 * s, 1.3422 * s, 0.6816 * s)
      ..quadraticBezierTo(1.3731 * s, 0.6507 * s, 1.4173 * s, 0.6507 * s)
      ..quadraticBezierTo(1.4614 * s, 0.6507 * s, 1.4923 * s, 0.6816 * s)
      ..quadraticBezierTo(1.5233 * s, 0.7125 * s, 1.5233 * s, 0.7567 * s)
      ..quadraticBezierTo(1.5233 * s, 0.8009 * s, 1.4923 * s, 0.8318 * s)
      ..quadraticBezierTo(1.4614 * s, 0.8627 * s, 1.4173 * s, 0.8627 * s)
      ..close()
      ..moveTo(0.8303 * s, 0.8627 * s)
      ..quadraticBezierTo(0.7861 * s, 0.8627 * s, 0.7552 * s, 0.8318 * s)
      ..quadraticBezierTo(0.7243 * s, 0.8009 * s, 0.7243 * s, 0.7567 * s)
      ..quadraticBezierTo(0.7243 * s, 0.7125 * s, 0.7552 * s, 0.6816 * s)
      ..quadraticBezierTo(0.7861 * s, 0.6507 * s, 0.8303 * s, 0.6507 * s)
      ..quadraticBezierTo(0.8745 * s, 0.6507 * s, 0.9054 * s, 0.6816 * s)
      ..quadraticBezierTo(0.9363 * s, 0.7125 * s, 0.9363 * s, 0.7567 * s)
      ..quadraticBezierTo(0.9363 * s, 0.8009 * s, 0.9054 * s, 0.8318 * s)
      ..quadraticBezierTo(0.8745 * s, 0.8627 * s, 0.8303 * s, 0.8627 * s)
      ..close()
      ..moveTo(0.7384 * s, 0.1373 * s)
      ..quadraticBezierTo(0.7596 * s, 0.1373 * s, 0.7745 * s, 0.1522 * s)
      ..quadraticBezierTo(0.7894 * s, 0.1670 * s, 0.7894 * s, 0.1883 * s)
      ..quadraticBezierTo(0.7894 * s, 0.2095 * s, 0.7745 * s, 0.2244 * s)
      ..quadraticBezierTo(0.7596 * s, 0.2393 * s, 0.7384 * s, 0.2393 * s)
      ..quadraticBezierTo(0.7171 * s, 0.2393 * s, 0.7023 * s, 0.2244 * s)
      ..quadraticBezierTo(0.6874 * s, 0.2095 * s, 0.6874 * s, 0.1883 * s)
      ..quadraticBezierTo(0.6874 * s, 0.1670 * s, 0.7023 * s, 0.1522 * s)
      ..quadraticBezierTo(0.7171 * s, 0.1373 * s, 0.7384 * s, 0.1373 * s)
      ..close()
      ..moveTo(1.9123 * s, 0.1373 * s)
      ..quadraticBezierTo(1.9336 * s, 0.1373 * s, 1.9485 * s, 0.1522 * s)
      ..quadraticBezierTo(1.9633 * s, 0.1670 * s, 1.9633 * s, 0.1883 * s)
      ..quadraticBezierTo(1.9633 * s, 0.2095 * s, 1.9485 * s, 0.2244 * s)
      ..quadraticBezierTo(1.9336 * s, 0.2393 * s, 1.9123 * s, 0.2393 * s)
      ..quadraticBezierTo(1.8911 * s, 0.2393 * s, 1.8762 * s, 0.2244 * s)
      ..quadraticBezierTo(1.8614 * s, 0.2095 * s, 1.8614 * s, 0.1883 * s)
      ..quadraticBezierTo(1.8614 * s, 0.1670 * s, 1.8762 * s, 0.1522 * s)
      ..quadraticBezierTo(1.8911 * s, 0.1373 * s, 1.9123 * s, 0.1373 * s)
      ..close()
      ..moveTo(1.3254 * s, 0.1373 * s)
      ..quadraticBezierTo(1.3466 * s, 0.1373 * s, 1.3615 * s, 0.1522 * s)
      ..quadraticBezierTo(1.3763 * s, 0.1670 * s, 1.3763 * s, 0.1883 * s)
      ..quadraticBezierTo(1.3763 * s, 0.2095 * s, 1.3615 * s, 0.2244 * s)
      ..quadraticBezierTo(1.3466 * s, 0.2393 * s, 1.3254 * s, 0.2393 * s)
      ..quadraticBezierTo(1.3041 * s, 0.2393 * s, 1.2892 * s, 0.2244 * s)
      ..quadraticBezierTo(1.2744 * s, 0.2095 * s, 1.2744 * s, 0.1883 * s)
      ..quadraticBezierTo(1.2744 * s, 0.1670 * s, 1.2892 * s, 0.1522 * s)
      ..quadraticBezierTo(1.3041 * s, 0.1373 * s, 1.3254 * s, 0.1373 * s)
      ..close()
      ..moveTo(1.6345 * s, 0.8763 * s)
      ..quadraticBezierTo(1.6410 * s, 0.8686 * s, 1.6465 * s, 0.8606 * s)
      ..lineTo(1.6465 * s, 0.8517 * s)
      ..quadraticBezierTo(1.6413 * s, 0.8643 * s, 1.6345 * s, 0.8763 * s)
      ..close()
      ..moveTo(1.0475 * s, 0.8763 * s)
      ..quadraticBezierTo(1.0540 * s, 0.8686 * s, 1.0595 * s, 0.8606 * s)
      ..lineTo(1.0595 * s, 0.8517 * s)
      ..quadraticBezierTo(1.0543 * s, 0.8643 * s, 1.0475 * s, 0.8763 * s)
      ..close();
