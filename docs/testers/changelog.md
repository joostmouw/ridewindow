# Testers changelog — Ridewindow

> Eén blok per build, vanaf build 41. Bijgehouden terwijl er gebouwd wordt, niet
> achteraf gereconstrueerd. Wie er test en waarom staat in `.planning/TESTERS.md`.

## Build 42 — 1.0.31+42

**Datum:** 2026-09-10
**Track:** Internal testing → Closed testing "Alpha" (actief sinds 2026-09-10 23:24,
beschikbaar voor de geselecteerde testers)

**Inhoud**
- De app heet Ridewindow, overal waar een gebruiker de naam ziet — app, winkelpagina,
  privacybeleid en PWA zeggen nu hetzelfde (`a28886f`)
- De openingsintro is twee keer zo kort: 2,47 s in plaats van 4,94 s (`059e352`)

**Feedback opgelost:** geen — dit was een eigen keuze (merknaam en een snellere start).

## Build 41 — 1.0.30+41

**Datum:** 2026-09-10
**Track:** Closed testing "Alpha"

**Inhoud**
- Daglicht telt mee in de score. Een venster dat een uur na zonsondergang valt scoort
  niet langer perfect; daarvoor gold een vast raam van 06:00–22:00. De zonstand wordt
  lokaal berekend en is geijkt tegen Open-Meteo (`c3bd44f`), en de aftrek is aangesloten
  op de score, met een weerbalk, een regel op de ritkaart en een schuif in Profiel
  (`5aff9d7`)
- De vier oordelen heten nu Toprit, Fijne rit, Te doen en Binnenblijver
- De Peloton-introductie bereikt wie hem nodig heeft (`36b56f0`)

**Feedback opgelost:** Ingrid (tester) vroeg op 2026-09-09 of de app rekening houdt met
het moment van zonsondergang. Daaruit kwam backlog **#68**, en de daglichtscore hierboven
is het antwoord — de eerste testerfeedback die tot een uitgeleverde wijziging leidde.
Uit diezelfde melding kwamen ook #69 (het groene blok) en #70 (waarom dit venster), die
nog openstaan.
