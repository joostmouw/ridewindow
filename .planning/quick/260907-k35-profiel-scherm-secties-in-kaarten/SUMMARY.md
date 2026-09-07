---
task_id: 260907-k35
slug: profiel-scherm-secties-in-kaarten
date: 2026-09-07
milestone: v4.0
phase: 23
status: complete
commits:
  - eac9519 feat(profiel) elke sectie op een eigen kaart
  - 820357c fix(home) beste kaart een markering, planned-blauw klopt
  - ef53829 fix(profiel) koppen gelijk, schakelaars niet meer kapot
---

# Profiel: kaarten per sectie — afgerond

Alle vier de taken uit PLAN.md zijn gedaan, plus twee dingen die Joost er
tussendoor bij vroeg en twee die pas zichtbaar werden toen de kaarten er
stonden. 498 tests groen, `flutter analyze` zonder fouten of waarschuwingen
(171 info-meldingen, één minder dan de 172 waarmee we begonnen).

Live op **https://my-project-joost.web.app** — hard herladen (⌘⇧R), anders zie
je de vorige bundel.

## Wat er staat

`SettingsSection` (`lib/features/profile/settings_section.dart`) is de gedeelde
sectiewidget: kop bóven een witte kaart (`surfaceContainerLowest`, haarlijn
`surfaceContainerHigh`, radius 18). Negen secties gebruiken hem, en
`account_section.dart` ook — waarmee het letterlijke duplicaat
`_AccountSectionHeader` kon vervallen. `SettingsBanner` is de volle-breedte
strook voor een melding bovenin een kaart.

## De drie valkuilen uit het plan, en hoe ze uitpakten

1. **Inkt buiten de vorm** — voorkomen. De kaart is een `Material` met
   `clipBehavior: Clip.antiAlias`, geen `Container` met `BoxDecoration`.
2. **De twee locatiebanners** — als losse `Card`s braken ze de groep; nu
   stroken die door de clip van de kaart meeronden.
3. **Dubbele inspringing** — dit was de enige die echt beet. Een rij in een
   kaart is 32px smaller dan in de oude platte lijst, en de drie
   tolerantie-labels liepen 26px over. De testsuite ving het: vijf tests in
   `profile_screen_test.dart` vielen om op een `RenderFlex overflowed`. Opgelost
   door de labels in een `Expanded` te zetten in plaats van er een `Spacer`
   achter — nu mogen ze krimpen.

## Wat er tussendoor bij kwam (Joost, tijdens de uitvoering)

- **De beste kaart op Home droeg drie markeringen** — pil, groene staaf én
  slagschaduw — terwijl de rest er geen had. Joost koos: staaf en schaduw
  eruit, alleen de pil blijft, en de kaart krijgt dezelfde haarlijn als alle
  andere. Daarmee vervielen ook de `DecoratedBox` buiten de `ClipRRect` (die
  bestond alleen om de schaduw langs de clip te krijgen) en de extra
  ondermarge (die bestond alleen om die schaduw niet over de volgende kaart te
  laten vallen).
- **Planned-blauw kwam niet overeen met de Agenda.** Zelfde token
  (`plannedRide` `#1565C0`), maar op Home stond de rand op alpha 60 en in de
  agenda op volle sterkte met 2px. Home staat nu gelijk aan de agendacel.

De keuze over de beste kaart is gemaakt op een HTML-specimen met de echte
tokens, drie varianten naast elkaar. Dat kostte een paar minuten en de keuze
was er meteen — dezelfde werkwijze als bij het kiezen van Outfit.

## Wat de kaarten zichtbaar maakten

- **`sectionAccount` stond als enige niet in kapitalen** in de `.arb`. In een
  platte lijst viel dat niet op, boven een kaart meteen wel. `SettingsSection`
  kapitaliseert nu zelf; de vertalingen bleven ongemoeid en het probleem kan
  niet terugkomen bij een volgende sectie.
- **De notificatie-schakelaars ogen niet meer dood.** Dat lag niet aan de kaart
  maar aan `switchTheme` in `main.dart`: er stond wel een trackkleur maar geen
  `trackOutlineColor`, dus de uit-stand was een randloze olijfvlek. Dit was
  punt 4 uit de open lijst van fase 23 en het geldt meteen overal waar een
  `Switch` staat.

## Nog open in fase 23

- Stap 3 — de typografische schaal echt gebruiken.
- Stap 5 — dagstrip en periodefilter rustiger.
- Peloton-kaarten missen hun haarlijn.

## Eén waarschuwing voor de volgende sessie

Chrome scrollt de Flutter-canvas niet met synthetische wielgebeurtenissen — ik
kon Profiel niet voorbij de sectie NOTIFICATIES bekijken in de browser. De
bovenkant is visueel geverifieerd, de rest leunt op de testsuite (die de
overflow ook echt ving, op 400px breed — smaller dan een echte telefoon).
Wil je het onderste stuk met eigen ogen zien, dan is dat het toestel.
