---
quick_id: 260908-p6w
slug: welkomtekst-leesbaar
date: 2026-09-08
status: complete
---

# "Font is lastig te lezen met kleuren" — het was de kleur niet

## De melding

Een tester stuurde een screenshot van het welkomscherm met bleke tekst en een
lichtgroene knop, met de tekst *"Font is lastig te lezen met kleuren"*. Op de
webapp.

## Wat het niet was

**De kleuren.** Doorgerekend tegen `brandLight` (`#C5D4B6`), de achtergrond van
dit scherm:

| | op brandLight | AA-drempel |
|---|---|---|
| titel (`onSurface`) | **9,63:1** | 4,5 |
| subtitel (`onSurfaceVariant`) | **5,54:1** | 4,5 |

Allebei ruim voldoende. Een kleurwijziging zou niets hebben opgelost.

## Wat het wel was

De screenshot zelf gaf het weg: de fiets erboven was kaarsscherp, alleen het
tékstblok was verwassen — inclusief de knop, die lichtgroen was in plaats van
`brandDark`. Dat is geen kleur maar dekking.

De oorzaak stond in één regel:

```dart
final fadeIn = CurvedAnimation(
  parent: _settle,
  curve: const Interval(0.35, 1.0, curve: AppMotion.effectsCurve),
);
final slideIn = Tween(...).animate(fadeIn);   // ← dezelfde animatie
```

Dekking en verplaatsing hingen aan hetzelfde interval. Het tekstblok stond dus
**1170 ms lang halfzichtbaar op zijn definitieve plek**. Je oog begint te lezen
en faalt — en dan is de conclusie "dat font leest slecht".

De test die dit nu bewaakt meet op dat moment een dekking van **0,67**: exact
de staat die de tester fotografeerde.

## De keuze

Drie varianten als HTML-specimen naast elkaar, met de echte kleuren en de echte
timing. Joost koos **B**: dekking klaar in ~200 ms, daarna alleen nog beweging.

Het principe erachter: tekst hoort er niet te zijn, of leesbaar te zijn —
nooit iets ertussenin. Een seconde op 40% dekking is geen zachte introductie
maar een moment waarin het scherm iets belooft wat het niet waarmaakt. Variant
A (helemaal geen fade) loste het ook op maar verscheen abrupt, wat botst met de
rust van dit scherm.

`Interval(0.35, 0.46)` — ruwweg 200 ms van de 1800 ms. `_settleAt` en de duur
van de verschuiving zijn ongewijzigd; alleen dekking en beweging zijn nu twee
dingen.

## Terloops opgemerkt

De oude dekking hing aan `AppMotion.effectsCurve`, een veer met
dempingsverhouding 0,71 — die is onderdempt en schiet dus dóór voorbij 1,0. Voor
een verplaatsing is dat de bedoeling; voor een dekking is het een waarde die
niet bestaat. De nieuwe fade gebruikt `Curves.easeOut`.

## Verificatie

Test 3 in `test/features/welcome_screen_test.dart`. Twee stappen pumpen is geen
omweg: de verschuiving start via een `Timer` op 3144 ms, en één grote pump laat
die timer wél vuren maar geeft de controller daarna geen tijd meer.

**Op falen gecontroleerd**: met het interval terug op `(0.35, 1.0)` valt de test
om op `Expected: 1.0 / Actual: 0.6697…`.

Volledige suite: 524 groen.
