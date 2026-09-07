---
task: home-papier-en-inkt
milestone: v4.0
phase: 23
completed: 2026-09-07
status: complete
commits: [ffa4247, fd6ad11]
---

# Samenvatting — fase 23, stap 1+2

Beide stappen zijn af en draaien. `flutter analyze` staat onveranderd op 112 issues / 0 errors,
de suite op **479/479** (ook de bekende post-19:00-UTC-notificatietest was groen, want er is vóór
dat tijdstip gedraaid). `flutter build web --release` slaagt en is in Chrome nagelopen: Welcome →
Onboarding → Home.

## Wat er gedaan is

**`ffa4247` — de achtergrond wordt papier.** `lightSurface` van `brandLight` naar `#FCFDF8`.
Welcome en Onboarding zetten `brandLight` nu zelf. `lightTextTertiary` en `lightTextHint` zijn
lichter gezet (5,54:1 en 4,75:1 op papier), met de oude waarden bewaard als
`brandScreenTextTertiary`/`-Hint` voor de twee groene schermen.

**`fd6ad11` — de beste ritkaart licht op.** Schaduw op een `DecoratedBox` buiten de `ClipRRect`,
5px linkerrand in `brandDark`, radius links 8 / rechts 24. Overige kaarten vlak met een haarlijn.

## De onzekere ingreep is gelukt

De schaduw-buiten-de-clip werkt, en de swipe-to-schedule is onaangetast — er is niets aan de
`Dismissible` veranderd, alleen een ouder toegevoegd die de schaduw tekent. De afweging
"schaduw óf gesture" die als terugvaloptie klaarlag, is niet nodig geweest.

Drie dingen die niet in het plan stonden en pas bij het bouwen bleken:

- **De beste kaart heeft extra ondermarge nodig.** Zonder dat valt zijn schaduw over de kaart
  eronder en oogt die vies in plaats van vlak.
- **De accentrand kan geen `borderRadius` hebben.** Flutter staat een niet-uniforme `Border` met
  radius niet toe. Opgelost door de rand binnen de `ClipRRect` te zetten, die hem toch al afrondt.
- **Links radius 8 in plaats van 24.** Met de volle radius aan beide kanten leest de 5px rand als
  een sikkel in plaats van als een streep.

Ook onvoorzien, maar in de andere richting: **Onboarding had een tweede plek die meeliftte.** De
niet-geselecteerde preset-tegel gebruikte óók `colorScheme.surface` en zou dus wit op groen zijn
geworden — een wijziging aan precies het scherm dat ongemoeid moest blijven. Nu expliciet
`brandLight`.

## Gevonden én gerepareerd — "Best choice" stond op de verkeerde kaart

> **Bijgewerkt 2026-09-07:** Joost heeft beslist (hoogste score wint) en de fix zit in `0eee226`.
> De analyse hieronder blijft staan omdat ze verklaart hoe dit zo lang onopgemerkt kon blijven.
> Bij gelijke score wint de vroegste rit. De keuze zit nu in `indexOfBestSlot` naast `RideSlot`,
> met vijf tests — waaronder letterlijk de situatie van vandaag.
>
> **Kosten een kwartier, dus onthouden:** na een `flutter build web --release` toont een gewone
> herlaad in Chrome nog de óúde bundel uit de geheugencache. Geen service worker, geen
> HTTP-cachekop — `caches.keys()` was leeg en `getRegistrations()` gaf nul. Alleen ⌘⇧R hielp. Ik
> heb daardoor even geconcludeerd dat mijn code fout was terwijl hij goed was. Bij het beoordelen
> van een verse web-build dus altijd hard herladen.


Op de web-build draagt de kaart met score **99** het "Best choice"-label, terwijl de kaart
eronder **100** scoort. Dat is geen regressie van deze taak; het zit in `_buildCardsSliver`:

```dart
slots.sort((a, b) {
  final byTier = _tierOrder(a.tier).compareTo(_tierOrder(b.tier));
  return byTier != 0 ? byTier : a.start.compareTo(b.start);   // ← tiebreak is tijd, niet score
});
final isBest = index == 0 && (…tier is Perfect || Great);
```

Binnen dezelfde tier is de tiebreak **starttijd**, niet score. De vroegste `Perfect` wint dus van
een latere `Perfect` die hoger scoort.

Dit was altijd al zo, maar het weegt nu zwaarder: de kaart schreeuwt sinds deze taak dat hij de
beste is, en wijst de verkeerde aan. Dat raakt de kernwaarde van het product, niet de opmaak.

Het is bewust blijven liggen omdat het een **gedragswijziging** is en geen opmaakwijziging, en
omdat er een echte keuze onder zit: is "best" de hoogste score, of het eerstvolgende goede venster?
Allebei verdedigbaar, en dat is Joosts beslissing. Zie de vraag in de rapportage.

## Wat er nu tijdelijk niet klopt (bekend en bewust)

Alleen Home is omgezet. Rides, Ride Detail, Peloton, Profiel, Beschikbaarheid en de twee overlays
(`screen_hint_overlay.dart`, `app_tour_overlay.dart`, met hardcoded kleuren) staan nog op de oude
verhouding. De coach mark op Home viel bij het nalopen meteen op — die is stap 6.

Stap 3 (typografische schaal), 4 (weerbalken herschalen + oordeelwoord) en 5 (dagstrip en
periodefilter) staan ook nog open. De weerbalken zijn op de screenshots goed te zien als het
volgende dat opvalt: drie bijna identieke streepjes, met de regenzone nog altijd 5% breed.

## Nog te toetsen op een toestel

De lichtere `textTertiary`/`textHint` zijn **berekend, niet gezien**. Backlog #9 is op Roboto
gemeten en Outfit oogt lichter; 11–12 punt op de Oppo controleren voordat er nog iets lichter gaat.
