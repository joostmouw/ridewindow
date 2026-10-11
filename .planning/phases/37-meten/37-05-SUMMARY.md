---
phase: 37-meten
plan: 05
subsystem: tooling
tags: [meten, nulmeting, vloeren, plafonds, dicht-huis, adb]
requires:
  - "37-03: tool/usage_report.dart, tool/usage/usage_floors.dart"
  - "37-04: 0014 live, service-role-route bewezen"
provides:
  - "37-NULMETING.md: gemeten historie + Oppo-sessie, vloeren (3x), voorgestelde plafonds fase 38/39 (10x)"
  - "usage_floors.dart op gemeten vloeren, kop verwijst naar de nulmeting van 2026-10-11"
  - "usage_report.dart haalt de telling in pagina's op (geen stille afkapping op 1000 rijen meer)"
affects: [37-06, 38, 39]
tech-stack:
  added: []
  patterns: ["PostgREST-rpc in pagina's ophalen met offset/limit in de query; Range-header werkt niet bij POST"]
key-files:
  created:
    - .planning/phases/37-meten/37-NULMETING.md
  modified:
    - tool/usage/usage_floors.dart
    - tool/usage_report.dart
decisions:
  - "Joost koos op 2026-10-11 voor 'beide': lezen en Oppo-sessie (D-19)"
  - "Vloeren = 3x gemeten waarde, naar boven afgerond op een rond getal en minimaal 5; plafonds = 10x het drukste toestel/account"
  - "De testgroepsrit ging naar één maatje in plaats van een groep, zodat zo weinig mogelijk echte mensen hem konden zien"
  - "Na de productie-uitrol de vloeren opnieuw meten: de mediaan is nu bijna overal 0, dus in de praktijk beslist alleen de vloer"
metrics:
  duration: "~35 min"
  completed: 2026-10-11
  tasks: 3
  files: 3
---

# Fase 37 Plan 05: Nulmeting Samenvatting

De nulmeting staat vast in `37-NULMETING.md` en komt uit twee bronnen: de volledige historie (200 dagen) en één bewust zware Oppo-sessie van ongeveer acht minuten. De vloeren in `usage_floors.dart` zijn nu gemeten en niet meer geschat. Per bron staat er een voorgesteld plafond voor fase 38 en 39.

## Taak 1: toestemming (D-19)

**Joost koos "beide" (lezen en Oppo-sessie), op 2026-10-11, via de vraag van de orchestrator in de chat.** Vastgelegd om 20:40 CEST, bij de start van deze uitvoering. Vóór die keuze is niets gelezen.

## Taak 2: meten (geen repo-commit; werkbestanden in de scratchpad)

- **Historie:** het rapport en de ruwe rpc over 200 dagen, t/m gisteren. De drukste dagen zijn klein: `app_events` 27, `accounts_google` 12, `friend_invites` 9, de rest 4 of minder. Het hoogste per afzender: `app_events` 9 en `friend_invites` 7.
- **Oppo-sessie:** build 1.0.59 (70) via Play, statistiek aan. Snapshot 1 om 20:46:41, snapshot 2 om 20:54:31. Verschil: `app_events` +6 (dat toestel kwam vandaag op 12), `feedback_account` +2, `friend_invites` +1, `group_rides` +1, `group_ride_options` +3. `group_invites` bleef 0, omdat de app een nog geldige groepslink hergebruikt.
- **Opruimen:** de testgroepsrit is via de app verwijderd ("Cancel ride"). De tweede testrit is weer uitgepland. Snapshot 3 (20:57:12) laat `group_rides` terug op 1 en `group_ride_options` op 0 voor vandaag zien. De ritlijst in de app is weer zoals vóór de sessie: alleen Joosts eigen rit op dinsdag 13 oktober. De twee feedbackberichten ("nulmeting 37, test 1" en "test 2") blijven staan, zoals afgesproken. De maatjeslink is niet gedeeld en verloopt vanzelf.
- `git status` toont buiten `.planning` en `usage_floors.dart` niets van de meting.

## Taak 3: nulmeting en vloeren (60c78d6)

Vloeren in `usage_floors.dart`, regel voor regel vergeleken met de tabel "Vloeren" in 37-NULMETING.md. Alles komt overeen:

| Bron | kFloorTotal | kFloorSender |
|------|------------:|-------------:|
| feedback_account | 10 | 10 |
| feedback_anoniem | 10 | geen |
| app_events | 100 | 40 |
| friend_invites | 30 | 25 |
| group_invites | 10 | 10 |
| group_rides | 10 | 10 |
| group_ride_options | 15 | 15 |
| accounts_google | 40 | geen |
| accounts_email | 10 | geen |
| accounts_overig | 5 | geen |

De sleutelsets zijn ongewijzigd. `flutter test test/tool/` geeft 45/45 groen en `dart analyze tool` meldt niets.

## Afwijkingen van het plan

**1. [Regel 1, bug] usage_report kapte stilzwijgend af op 1000 rijen** (059ddc7, en 040ef88 voor een lint-komma)
- **Gevonden bij:** Taak 2. Met `--days 120` eindigde het rapport op 2026-08-24 en noemde die dag "vandaag".
- **Oorzaak:** PostgREST geeft per verzoek hoogstens 1000 rijen (`max-rows`). 148 dagen keer 10 bronnen is 1480 rijen. Boven ongeveer 72 dagen klopte het rapport dus niet meer.
- **Fix:** ophalen in pagina's met `?offset=&limit=` in de query, met een vangnet op het aantal pagina's. Een eerste poging met een `Range`-header liep vast: PostgREST negeert die bij een POST-rpc, dus de lus kreeg steeds dezelfde pagina terug. Dat is gezien en vervangen voordat er iets gecommit werd.
- De Action (`usage_check` via psql, 30 dagen) had hier geen last van.

**2. Testgroepsrit naar één maatje.** De app kan geen groepsrit maken zonder iemand uit te nodigen. Daarom is de rit naar één maatje gegaan (de vaste tester van groepsritten) en niet naar een groep van 3 of 4 leden. De app stuurt geen pushmelding bij een uitnodiging. Dat maatje kon de rit dus alleen zien als hij de app opende in de ongeveer vijf minuten dat hij bestond.

## Incident tijdens de Oppo-sessie: tikken kwamen in WhatsApp terecht

Tijdens het laatste stuk van de sessie heeft een Back-toets (na "Show tips") Ridewindow verlaten. Een reeks blinde tikken kwam daarna in WhatsApp terecht. Achteraf stond daar een gesprek open (`com.whatsapp/.Conversation`), en de laatste dump liet een contactkaart zien.
- Er is in WhatsApp **geen tekst getypt** en er is niet op de verzendknop rechtsonder getikt.
- Eén tik viel op de plek rechtsboven in een gespreksbalk, waar WhatsApp de belknop zet. **Of daarmee een oproep gestart is, kon ik niet vaststellen** zonder WhatsApp verder te openen, en dat heb ik bewust niet gedaan. Bij controle liep er geen gesprek: telecom had geen calls en de audiomodus was normaal.
- **Joost: kijk in WhatsApp bij Oproepen en in het bovenste gesprek of er om ongeveer 20:53 een oproep of iets anders uitging.**
- Vanaf dat moment is vóór elke tik gecontroleerd dat Ridewindow vooraan stond (`fg.sh`). Het opruimen gebeurde zo.
- De meting zelf is er niet door geraakt: snapshot 2 is na die tikken genomen, en wat in WhatsApp gebeurde levert geen rijen in Ridewindow op.

## Hoe goedlopende apps het doen

Niet van toepassing: dit plan raakt geen interactie in de app.

## Self-Check: PASSED

- .planning/phases/37-meten/37-NULMETING.md: aanwezig
- tool/usage/usage_floors.dart: verwijst naar 37-NULMETING.md
- commits 059ddc7, 040ef88, 60c78d6: aanwezig
