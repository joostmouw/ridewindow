// lib/features/shared/section_card.dart
// Eén sectie: kop op de achtergrond, inhoud op een kaart.
//
// Vóór v4.0 waren Profiel en Peloton platte lijsten waarin de secties alleen
// door een koptekst gescheiden werden. Op de papieren achtergrond
// (`lightSurface` is sinds fase 23 `#FCFDF8`) leest dat als één doorlopende
// lijst: er is geen vlak dat zegt waar een groep begint of eindigt. Deze widget
// geeft elke groep de behandeling die Home en Ride Detail al hebben — wit op
// papier, met een haarlijn in plaats van een schaduw.
//
// Stond tot 2026-09-07 in `features/profile/` en heette `SettingsSection`. Toen
// Peloton dezelfde behandeling nodig had bleek de naam te smal: een lijst met
// maatjes is geen instelling. Verhuisd naar `shared/` en hernoemd, waarmee ook
// de dérde kopie van dezelfde sectiekop kon verdwijnen — er stond er één in
// `profile_screen.dart`, één in `account_section.dart` en één in
// `peloton_tab.dart`, want Dart-privacy is per bestand en er was geen gedeelde
// plek.

import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // De kop staat bewust bóven de kaart, niet erin. Een label ín het
          // vlak wordt onderdeel van de inhoud en gaat concurreren met de
          // eerste regel; erbuiten benoemt het de groep en laat het de kaart
          // met rust.
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              // De kop wordt hier gekapitaliseerd, niet in de vertaling. Acht
              // van de negen `section*`-strings stonden al in kapitalen in de
              // `.arb` en `sectionAccount` niet -- die viel er zichtbaar uit
              // zodra de secties kaarten werden. Kapitalisatie is een
              // presentatiekeuze en hoort dus hier; op een string die al
              // schreeuwt verandert dit niets, dus de vertalingen konden met
              // rust blijven.
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
          _CardSurface(children: children),
        ],
      ),
    );
  }
}

/// Het witte vlak zelf.
class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      // `Material` en niet `Container(decoration:)`, en dat is geen smaak:
      // `Material.clipBehavior` staat standaard op `Clip.none`, waardoor de
      // inkt van een `ListTile` de réchthoek vult in plaats van de afgeronde
      // vorm. Zichtbaar bij elke tik, en in een kaart die vrijwel alleen uit
      // tegels bestaat is dat de helft van het scherm. Een `BoxDecoration`
      // kleurt de hoeken wel goed maar knipt de inkt niet — die val kostte op
      // 2026-09-07 al een ronde op Home.
      clipBehavior: Clip.antiAlias,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.surfaceContainerHigh),
      ),
      // Geen eigen binnenmarge: `ListTile` brengt zijn eigen hoogte mee, en een
      // strook (`SectionBanner`) moet juist tot de rand kunnen lopen. Kinderen
      // die géén tegel zijn — sliders, `SegmentedButton`, chips — houden hun
      // eigen `horizontal: 16`, zodat ze in de rooilijn van de tegels staan.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Volle-breedte strook bovenin een sectiekaart, voor een melding die bij die
/// sectie hoort (een geblokkeerde GPS, een stad die nog gekozen moet worden).
///
/// Losse `Card`s met eigen marge werkten hier niet: die zweven náást de
/// sectiekaart en breken juist de groep die deze epic wil maken. Als strook
/// hoort de melding zichtbaar bij het blok, en omdat de kaart `Clip.antiAlias`
/// heeft rondt hij vanzelf mee af — de strook heeft zelf geen radius nodig.
class SectionBanner extends StatelessWidget {
  const SectionBanner({
    super.key,
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: child,
    );
  }
}
