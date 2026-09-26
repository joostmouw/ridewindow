---
quick_id: 260926-plankaart-kleur-en-rolregel
date: 2026-09-26
status: complete
---

# Plankaartjes onder GEPLAND: één kleur per kaart, rolregel maakt zijn zin af

## Wat er gebouwd is (één code-commit)

1. **Eén kleur per kaartje.** Het getal op de plankaartjes stond in een
   groene tierpil op een gepland-blauw kaartje: twee kleuren op één kaart.
   `ScoreBadge` kreeg een optionele `color` die op de getalvariant de
   tierkleur overruled; Home geeft `rw.plannedRide` mee. De vulling van de
   pil staat op alpha 40 tegenover alpha 18 van het kaartje, zodat de pil
   ook op een blauw kaartje nog als pil leest. Het oordeel blijft
   beschikbaar in het Semantics-label ("Toprit, 97") en op het detail in
   woord én tierkleur.
2. **De rolregel maakt zijn zin af.** Op het smalle plankaartje kaptte
   "On the Roll · You're organising" af tot "You're o...". Het label van
   `RideRoleLine` mag nu omslaan naar twee regels en blijft één regel
   zolang het past. De groepsnaam houdt zijn cap van 45 procent (schets
   016).

## Vondsten

1. **De OCR-route (BACKLOG #88) is weer opgebouwd:** `/usr/bin/swift` met
   Apple Vision (`VNRecognizeTextRequest`), script opnieuw in `/tmp`
   geschreven. Hij bracht de afgekapte rolregel en de kleurmismatch boven
   water. Ruis in de uitlees ("Upd1ted", "Agend1") is OCR-noise, geen
   appfouten.
2. **De afkapping was een ontwerpkeuze met een lekkage.** Schets 016 capte
   de groepsnaam op 45 procent zodat "de rol altijd de rest" krijgt, maar
   op het circa 180 dp brede plankaartje is die rest te krap voor de rolzin
   zelf. De cap blijft staan; de zin valt nu om in plaats van afgekapt te
   worden, en daarmee blijft de belofte overeind die de cap moest geven.
3. **Geen test raakte aan de pillkleur of de regellengte**, en een widgettest
   zou hier weinig zeggends hebben: `find.text` vindt de volledige tekst
   óók achter een ellips. De suite bleef daarom ongewijzigd groen; het
   visuele oordeel is aan de goedkeuringsronde.

## Bewijs en grenzen

- Volledige suite: **986 tests groen** (gelijk aantal; geen nieuw gedrag
  dat een test verdient).
- `flutter analyze`: **201 infos**, precies de bestaande baseline.
- Geen ARB-wijzigingen, geen serverwerk, geen versiebump, geen release.
- **Goedkeuren is Joost's ronde**: de web-PWA en de Oppo met oog op de
  kleur van het getal en de omvallende rolregel.
