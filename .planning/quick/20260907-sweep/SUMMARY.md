---
task: sweep
milestone: v4.0
phase: 23
completed: 2026-09-07
status: partial
commits: [c544e49]
---

# Stap 6 — de sweep

Vooraf uitgetekend als `stap-6-sweep.html`, met screenshots van de échte schermen uit de web-build
in plaats van een grep. Dat langslopen leverde de rode draad op die het werk klein maakte.

## De rode draad

**Een kleur die "achtergrond" betekende, betekent nu "vlak dat aandacht vraagt."** De geblokkeerde
agenda-cellen, de groene banner in Profiel, de detailkaart — allemaal dezelfde kleurfamilie,
allemaal ooit gekozen omdát ze wegvielen tegen `brandLight`. Ze waren niet stuk; hun rol was onder
ze vandaan gehaald. Eén beslissing, een paar keer toegepast.

## Gedaan

| Plek | Wat | Waarom |
|---|---|---|
| **Agenda** | Nieuw token `RideWindowTheme.gridBlocked`, neutraal grijs | `surfaceContainerHighest` was op papier het zwaarste vlak van het scherm, terwijl "geblokkeerd" juist moet wegvallen. Kleur betekent in het rooster nu nog maar één ding: hier kun je fietsen. |
| **Agenda** | Slotje van alpha 120 naar vol | Die alpha bestond om het op de olijfvulling niet te laten schreeuwen; op neutraal verdween het bijna. |
| **Agenda** | "Now"-kop: onderstreping i.p.v. vulling | Als gevuld blokje concurreerde hij met de tier-kleuren eronder. |
| **Profiel** | Stad-picker-banner tonaal met groene rand | Stond op `primaryContainer` en was daarmee het meest verzadigde vlak van het scherm — terwijl het een terugvalstaat is. Een foutmelding trok meer aandacht dan je account. |
| **Ride Detail** | Kaart naar wit + haarlijn, `BoxShadow` weg | Stond op `cs.surface`, dus sinds de omkering op precies zijn eigen kleur. Hiermee is de **laatste handmatige `BoxShadow` uit de app** verdwenen. |

## Twee correcties op het eigen voorstel

**De overlays hoeven niet mee.** De sweep-pagina noemde `screen_hint_overlay.dart` (9 hardcoded
kleuren) en `app_tour_overlay.dart` (4) als "breekt zichtbaar". Dat klopt niet: hun `Colors.white`
staat op een donkere `colorScheme.scrim.withAlpha(180)`, niet op het app-oppervlak. Ze zijn
hardcoded, maar tegen hun eigen achtergrond — vervangen door themakleuren zou ze juist stukmaken.
Wat eerder voor "breekt" werd aangezien was de overlay die deed wat hij moet doen.

**Beschikbaarheid was al goed.** Daar betekent kleur "waaróm geblokkeerd" (werk, agenda, eigen) en
vrije uren zijn nu papier. Andere semantiek dan Agenda, en die klopt. Niet aangeraakt.

## Bewust blijven liggen: kaarten per sectie in Profiel

Joost koos kaarten per sectie, en dat is **niet** in deze commit gedaan. Reden: `profile_screen.dart`
is een `ListView` van ~1200 regels waarin de secties als losse kinderen staan, deels achter
`if (isWebPlatform && …)`-condities, mét de sign-in-flow ertussen. Dat groeperen is geen
kleurwijziging maar een herstructurering van de lijst, en het haastig doen aan het eind van een
lange sessie is precies hoe je auth sloopt.

Verdient een eigen pass met een eigen verificatie. De rest van de sweep hangt er niet van af.

## Nog open in fase 23

- **Profiel: kaarten per sectie** (hierboven).
- **Stap 3** — typografische schaal.
- **Stap 5** — dagstrip en periodefilter rustiger.
- Kleiner: de notificatie-toggles in Profiel ogen dood (M3-track-kleur uit het oude schema), en
  Peloton-kaarten missen de haarlijn die ze op papier nodig hebben.
