# v4.0 "Eigen gezicht" — startpunt

> Aangemaakt 2026-09-07. Dit bestand is de werkstand van de epic; **begin hier.**
> Backlog-epic: **#64** in `BACKLOG.md`. Voorganger: v3.0, afgesloten — zie
> `.planning/milestones/v3.0-CLOSEOUT.md`.
>
> ## AFGESLOTEN op 2026-09-08 — `1.0.28+29` staat op Play
>
> **Stand in één zin:** alle vijf de fases zijn af en zitten in de build die de testers hebben.
> De app heeft een eigen gezicht: papier en inkt, Outfit, Phosphor voor alle 83 iconen, een
> bewegend welkomscherm, het kledingadvies als gevoelstemperatuur-schaal, en uitleg die je terug
> kunt halen.
>
> **De epic is gesloten "voor nu", niet gearchiveerd** — er staan nog vier losse punten open, zie
> "Wat er open bleef" onderaan dit bestand. Ze zijn geen van alle blokkerend en geen van alle
> onderdeel van de oorspronkelijke belofte.
>
> **Begin bij het blok "Wat er waar live staat" in `STATE.md`.** Daar staat ook wat een halve dag
> kostte aan vierkante sleephoeken en wat een spookrecord in Oppo's kloonprofiel deed, zodat je
> die valkuilen niet opnieuw inloopt.
>
> Live: **https://my-project-joost.web.app**

## Waar deze epic over gaat, en waarom hij nodig is

Joost heeft eerder een MD3-ronde gedaan en zei achteraf: *"de app ziet er hetzelfde uit."* Op
2026-09-07 is gemeten waaróm — en het antwoord is níét dat er tokens ontbreken.

**Wat al goed staat (niet opnieuw doen):**

- Merkkleuren zijn doorgevoerd: `brandLight #C5D4B6` en `brandDark #234934` in
  `lib/theme/app_colors.dart`, met `seed = brandDark` dat het hele M3-schema voedt.
- Handmatige `BoxShadow` is weg uit Home en Rides (nog één in `ride_detail_screen.dart`).
- MD3-componenten zijn in gebruik: `SegmentedButton`, `NavigationBar`, `FilterChip`,
  `Card.outlined`. De tonale oppervlakken (`surfaceContainer*`) worden gebruikt.
- Hardcoded kleuren staan alleen nog in twee overlay-bestanden (`screen_hint_overlay.dart`,
  `app_tour_overlay.dart`).
- Er is een tokenlaag voor vorm en beweging: `app_shapes.dart`, `app_motion.dart`.

**De werkelijke diagnose**, na een dag naar echte schermen kijken:

> **De app is een muur van dezelfde groentint zonder hiërarchie.** Achtergrond, dagstrip,
> periodefilter, geplande kaart en ritkaart hebben allemaal ongeveer hetzelfde gewicht en dezelfde
> afgeronde vorm. Er is niets dat het oog trekt. De weerbalken lezen als versiering in plaats van
> als informatie. Typografisch was alles ongeveer even groot.

Dat is waarom een MD3-checklist afvinken niets veranderde: het probleem is niet naleving, het is
durven contrasteren.

## Wat er al gebouwd is in deze epic

| Onderdeel | Waar | Commit |
|---|---|---|
| Huisletter Outfit (variabel, 111 kB) | `assets/fonts/Outfit.ttf`, `lib/theme/app_typography.dart` | `750189f` |
| Score als groot getal + woord i.p.v. smiley-pil | `lib/features/shared/score_display.dart`, gebruikt op de ritkaarten van Home | `750189f` |
| Hiërarchierichting gekozen: **B "Papier en inkt"** | `.planning/sketches/001-home-hierarchie/` (schets + implementatielijst) | `65d8cc1`, `8eedba0` |

**De regels die het logo oplegt** (het icoon is een RW-monogram in één ononderbroken lijn):

1. Monoline — overal dezelfde lijndikte, geen dik/dun-contrast.
2. Ronde lijnuiteinden.
3. Cirkelvormige bochten.
4. Geen enkele scherpe hoek.

Outfit is door Joost gekozen uit vier kandidaten die naast elkaar in de échte ritkaart met de échte
merkkleuren zijn gerenderd. Het levert regel 1, 3 en 4 maar heeft **vlakke** terminals. Dat werkt
hier omdat de rondheid al in de vórmen zit (kaarten op radius 24, `StadiumBorder`-knoppen); het
lettertype zet er contrast tegenover in plaats van nóg een laag zachtheid. De volledige afweging,
inclusief waar je op moet letten bij wijzigingen, staat in `app_typography.dart`.

**Werkwijze die zich bewees:** de vier lettertypes zijn als HTML-specimen naast elkaar gezet en
gescreenshot; Joost koos binnen een minuut. Bij een visuele keuze is *laten zien* sneller en
betrouwbaarder dan beschrijven. Herhaal dat voor de hiërarchieslag.

## De volgende stap

**Fase 23 uitvoeren: variant B in Dart.** De richting ligt vast, de vraag "eerst schetsen of
meteen in Dart" is beantwoord — er is geschetst (`.planning/sketches/001-home-hierarchie/`) en
Joost koos op 2026-09-07 variant **B "Papier en inkt"**. De volledige implementatielijst staat
onderaan de README van die schets; hieronder alleen wat je moet weten vóór je begint.

**De omkering die alles draagt:** `AppColors.lightSurface == brandLight` (`#C5D4B6`). De
achtergrond *is* de merkkleur, en de ritkaarten staan op `surfaceContainerHigh` (`#E4EAD7`) —
geen 8% helderheidsverschil. Dáárom veranderde de MD3-ronde niets: de tokens klopten, maar de
oppervlakkenladder had geen bereik om verschil mee te maken. B zet `lightSurface` op
`surfaceContainerLowest` (`#FCFDF8`) en degradeert `brandLight` van behang naar accent.

Preciezer nog: het gaat niet alleen om bereik in de ladder. De eigenlijke breker is dat **een
slagschaduw niet leest op een middentoon** — en schaduw is nu juist hét gereedschap om één ding
vóór de rest te zetten. In B zijn beide kaarten wit en komt het onderscheid uit schaduw en rand,
wat alleen kan op een lichte, neutrale grond.

Twee dingen om te weten voor je begint:

- **De contrastvraag is gemeten en valt mee** (2026-09-07). De ratio's uit backlog #9 zijn op
  brandLight gemeten, dus ze golden niet meer — maar élke tekstkleur krijgt op papier méér ruimte.
  `lightTextTertiary` gaat van 4,55:1 naar 6,94:1 en `lightTextHint` van 4,51:1 naar 6,89:1. De
  volledige tabel staat in de README van schets 001. **Gebruik die marge:** die twee mogen weer
  lichter, en zonder dat verschil verplaats je de vlakheid alleen van kleur naar typografie.
  Berekend, niet gezien — #9 is op Roboto gemeten en Outfit oogt lichter, dus 11–12 punt op de
  Oppo controleren vóór je iets lichter zet.
- **De beste kaart wil een slagschaduw, maar `_buildRideCard` wikkelt hem in een `ClipRRect`** voor
  de `Dismissible`, en die snijdt `elevation` weg — het commentaar in de code waarschuwt daar al
  voor. De schaduw moet buiten die clip, zonder de swipe-to-schedule te breken. Dit is de enige
  echt onzekere ingreep van de fase.

Verder ongewijzigd geldig: de weerbalken zijn onleesbaar per constructie (ideaalzone `≤0,5 mm` op
een schaal van `0–10 mm` is 5% van de balk), en de typografische schaal staat er wel maar wordt
niet gebruikt — op Home is vrijwel alles even groot.

**Consistentie-sweep hoort hierbij, niet erna:** de oppervlakomkering raakt élk scherm. Rides,
Ride Detail (waar ook de laatste handmatige `BoxShadow` staat), Peloton, Profiel, Beschikbaarheid,
en de twee overlays met hardcoded kleuren.

## Fase 25 — wrijving die op 2026-09-07 is waargenomen

Concreet, met de plek erbij. Alles zelf gezien op een toestel, niet bedacht:

- **Peloton-tab:** "Ritten waar je aan meedoet" en "Ritten die jij organiseert" staan ónder het
  invulveld voor een uitnodigingscode. De inhoud die ertoe doet hangt onder een formulier.
- **"My rides" liegt:** toont "No rides planned yet" terwijl er één tab verder een gedeelde rit
  staat. Bewuste keuze (persoonlijk vs. gedeeld), maar de lege staat vertelt dat niet.
- **Twee manieren om dezelfde rit te openen:** vanaf Home opent hij het detailscherm, vanaf Rides
  eerst een bottom sheet met "View details".
- **Nederlands lekt door de Engelse interface:** `3u` op de kaarten, `km/u` in de uurregels,
  `Kort/kort` bij het kledingadvies (`clothing_tip.dart`). Verwant aan backlog #58/#59.
- **Backlog #63:** iPhone-tester komt niet terug uit het beschikbaarheidsscherm. De knop bestáát
  (`SafeBackButton` in alle drie de takken), dus dit is een safe-area-kwestie op iOS-standalone;
  `viewport-fit=cover` en de safe-area-padding staan al in `web/index.html`, dus daar hoeft niemand
  te zoeken.

## Fase 24 — iconografie

Het kledingadvies (`lib/features/shared/clothing_tip.dart`) tekent losse Unicode-emoji
(`\u{1F455}` t-shirt, `\u{1FA73}` korte broek, `\u{1F9E5}` jas) in een `Text` op fontSize 20. Die
worden door het besturingssysteem getekend, dus Android, iOS en het web laten elk iets anders zien.
Het is bovendien het meest menselijke stukje van het product en daarmee de eerste plek voor eigen
beeldtaal. Eis: een eigen pictogram voor "lange mouw" moet zonder tekst herkenbaar zijn, anders is
een systeememoji die iedereen kent beter — toets dat op iemand die de app niet kent.

## Praktisch (bespaart een halve sessie)

- **Deployen duurt ~3 minuten:** `flutter build web --release && firebase deploy --only hosting`.
  De PWA is de snelle testroute; de Play-build loopt bewust achter (1.0.23+24, zonder Peloton).
- **De cache-val is opgelost** (`d99b3bd`): `index.html`, `flutter_bootstrap.js` en `main.dart.js`
  staan nu op `no-cache, must-revalidate`. Vóór die fix liep een toestel tot een uur achter na een
  deploy. Zie `PELOTON.md` voor de truc om tijdens debuggen deterministisch een verse bundel te
  forceren.
- **Toestel:** Oppo Find X9 Pro aan adb (`~/Library/Android/sdk/platform-tools/adb`, volledig pad —
  staat niet op PATH). Screenshots via `adb exec-out screencap -p`, verkleinen met `sips -Z 1000`.
- **Specimens vergelijken:** schrijf een HTML-bestand, serveer met `python3 -m http.server`, open in
  Chrome en screenshot. Zo is Outfit gekozen.

## Wat uit v3.0 blijft liggen (niet van deze epic, wel van dit project)

- iOS-verificatie: 5 vinkjes in `19-auth/REGRESSION-CHECKLIST.md`. Geen iPhone in het project;
  hoort bij de tester die #63 meldde.
- De oorzaak van de mislukte `onSignIn` bij joost.oppo. Symptoom is gedicht met een vangnet
  (`_ensureCloudProfileRow`) en een mislukking is nu zichtbaar. Repareer de oorzaak zodra hij zich
  laat zien.
- **Epic #65 "Peloton v2"** — meekijken zonder account, meerdere geschoorde vensters voorleggen,
  gedeelde beschikbaarheid, maatjes vinden via gebruikersnaam en contacten. Volledig uitgewerkt in
  `BACKLOG.md`.
- **Te bevestigen:** log opnieuw in als joost.oppo en controleer of hij daarna in Joosts
  maatjeslijst verschijnt — dat toetst het vangnet uit `ef391bf`.

## Eén werkafspraak die deze epic stuurt

**De app mag geen huiswerk achterlaten.** Een tester opende een deel-link, kreeg "log eerst in en
voer deze code in" te zien zónder inlogknop, en vroeg "En nu?" — terwijl de app die code al kende,
want hij stond in de URL. Loop bij elke wijziging het pad van de gebruiker één keer helemaal af en
vraag per scherm: weet de app dit al (vraag het dan niet), en kan de gebruiker vanaf hier verder
(zet die stap dan als knop neer). Dit is geen stijlkwestie maar de reden dat deze epic bestaat.

---

# Wat er open bleef

Toegevoegd bij de afsluiting op 2026-09-08. Geen van deze vier is blokkerend, en geen van deze
vier hoorde bij de belofte van de epic — ze zijn onderweg opgemerkt.

| | Waar | Waarom het bleef liggen |
|---|---|---|
| **De radii vormen geen systeem** | 24 op ritkaarten, 18 op detail- en sectiekaarten, 16 op PLANNED-regels, 12 en 3 elders | Material 3 kent 12, 16 en 20; **18 en 24 zijn geen token**. Een aparte opruimronde waard, maar het valt niemand op zolang het consistent oogt |
| **`ScoreBadge` naast `ScoreDisplay`** | `lib/features/shared/` | Twee vormtalen naast elkaar, bewust (zie de klassennoot), maar nooit tegen het papier-uiterlijk gehouden |
| **#63 — iPhone-tester komt niet terug uit beschikbaarheid** | `BACKLOG.md` | Niet op te lossen zonder iPhone. De knop bestáát in alle drie de takken, dus het is een safe-area-kwestie op iOS-standalone |
| **#66 / #67** | `BACKLOG.md` | Afgezegde ritten blijven onbereikbaar, en notificaties zijn hardgecodeerd Nederlands. Allebei opgemerkt tijdens deze epic, allebei buiten zijn scope |

## Wat deze epic heeft opgeleverd

| Fase | Wat |
|---|---|
| 23 | Papier en inkt: de achtergrond werd papier, de beste kaart kreeg gewicht, de weerbalken werden leesbaar |
| 24 | Iconografie: 71 Material-iconen en 12 emoji werden Phosphor Regular; het kledingadvies werd een gevoelstemperatuur-schaal |
| 25 | De wrijvingspunten: Peloton-volgorde, lege staten, één route naar een rit, en al het Nederlands uit de Engelse interface |
| — | Het welkomscherm werd een animatie, op 1,75× |
| — | De uitleg werd een Material 3 rich tooltip met terugknop, in beide talen, op alle drie de schermen terug te halen |

## De lessen die het meest hebben opgeleverd

1. **Laten zien is sneller dan beschrijven.** Outfit, variant B, de iconenfamilie, het introtempo en
   de uitlegvoet zijn allemaal gekozen binnen een minuut nadat ze als HTML naast elkaar stonden met
   de échte kleuren en de échte inhoud. Elke keer dat er eerst geschetst is, was de keuze meteen
   raak.
2. **Een klacht is een waarneming, geen diagnose.** "De app ziet er hetzelfde uit" bleek gebrek aan
   contrast, niet gebrek aan tokens. "Font is lastig te lezen met kleuren" bleek een animatie die
   1170 ms over zichzelf deed, niet een kleur. Twee keer zou de letterlijke lezing het verkeerde
   hebben gerepareerd.
3. **Test wat aan een screenshot niet te zien is.** De sterrenbug was tweemaal hetzelfde icoon met
   alleen een kleurverschil; de feedbackbug was een knop die "bedankt" zei zonder iets te versturen.
   Beide overleefden maanden. De tests die er nu op staan vergelijken `fontFamily` en of een drain
   werkelijk is aangeroepen — en zijn allebei op fálen gecontroleerd.
