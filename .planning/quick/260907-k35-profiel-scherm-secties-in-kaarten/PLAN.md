---
task_id: 260907-k35
slug: profiel-scherm-secties-in-kaarten
date: 2026-09-07
milestone: v4.0
phase: 23
status: complete
---

# Profiel: kaarten per sectie

Laatste open punt uit fase 23 waarvoor Joost al gekozen heeft (zie STATE.md,
"Stand na 2026-09-07", punt 1). Het is het enige scherm dat de papier-omkering
nog niet heeft: `profile_screen.dart` is één platte `ListView` waarin acht
secties als losse kinderen naast elkaar liggen, gescheiden door niets dan een
koptekst. Op een papieren achtergrond leest dat als één lange lijst zonder
groepen — precies de vlakheid die deze epic moet wegnemen.

## Wat er verandert

Elke sectie krijgt de behandeling die Home en Ride Detail al hebben: een witte
kaart (`surfaceContainerLowest`) met een haarlijn (`surfaceContainerHigh`) op
radius 18, met de sectiekop erbóven op de achtergrond. De kop blijft dus buiten
de kaart staan — dat is wat een groep leesbaar maakt: het label hoort bij het
blok, niet erin.

Secties: Account, Locatie, Notificaties, Taal, Thema, Toleranties, Rijlengte,
Naam, Over.

## De drie dingen die mis kunnen gaan

1. **Inkt buiten de vorm.** `Material.clipBehavior` staat standaard op
   `Clip.none`, dus de inkt van een `ListTile` vult de rechthoek en niet de
   afgeronde kaart. In een kaart vol `ListTile`s en `SwitchListTile`s is dat bij
   élke tik zichtbaar. Dit is dezelfde val die op 2026-09-07 een ronde kostte op
   Home — de sectiekaart wordt daarom een `Material` met
   `clipBehavior: Clip.antiAlias`, niet een `Container` met `BoxDecoration`.

2. **Dubbele inspringing.** De kaart staat 16 van de schermrand; `ListTile` legt
   daar zijn eigen 16 bovenop. Dat is gewenst en consistent — maar de
   niet-`ListTile`-kinderen (sliders, `SegmentedButton`, chips) hebben hun eigen
   `horizontal: 16` en moeten die hóuden, anders lopen ze niet in de rooilijn
   van de tegels.

3. **De twee locatiebanners.** De web-stad-CTA en de "GPS geblokkeerd"-banner
   zijn nu losse `Card`s mét eigen marge. Als losse kaarten náást de
   sectiekaart breken ze de groep. Ze worden vlakke, volle-breedte stroken
   bovenin de locatiekaart — de `clipBehavior` van de kaart rondt ze mee af, dus
   ze hebben zelf geen radius nodig.

## Taken

- [ ] T1 — `SettingsSection` als gedeelde widget (`settings_section.dart`),
      publiek zodat `account_section.dart` hem ook kan gebruiken (Dart-privacy
      is per bestand; dat is de reden dat `_AccountSectionHeader` nu een
      duplicaat is).
- [ ] T2 — `profile_screen.dart`: acht secties omwikkelen, de twee
      locatiebanners platslaan, `_SectionHeader` opruimen.
- [ ] T3 — `account_section.dart`: `SettingsSection` gebruiken, de dubbele
      `_AccountSectionHeader` weg.
- [ ] T4 — `flutter analyze` + `flutter test` schoon.

## Meegenomen, apart gecommit

Punt 4 uit de open lijst: de notificatie-toggles ogen dood. Oorzaak is niet de
kaart maar het thema — `switchTheme` in `main.dart` zet wel een trackkleur maar
geen `trackOutlineColor`, dus de uit-stand is een randloze vlek. Het is een
themawijziging, dus hij landt overal tegelijk; daarom een eigen commit.

## Verificatie

Web-build naar Firebase Hosting en op de Oppo bekijken. Aanraakgedrag (de inkt
van punt 1) verifieer je op het toestel, niet in Chrome — zie STATE.md.
