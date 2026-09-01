---
quick_id: 260901-nz7
status: complete
date: 2026-09-01
commits:
  - 36f4fca  # fix(sync): het opstartpad
  - abcf557  # test(sync): regressiedekking
---

# Quick Task 260901-nz7 — backlog #61 afgerond

## Wat er nu anders is

`CloudSyncReconciler.reconcileOnStartup()` bestaat en wordt fire-and-forget aangeroepen vanuit
`HomeScreen.initState`. Een ingelogde gebruiker met lege lokale opslag krijgt zijn cloud-ritten nu
bij de eerste start, zonder achtergrond→voorgrond-cyclus. One-shot per account per app-start, dus
opnieuw naar Home navigeren kost geen tweede cloud-rondgang.

`account_section._runAccountSync()` sluit af met `reconcileOnForeground()` in plaats van een kale
`drainOutbox()`.

## De consistentie-sweep leverde een tweede gat op

`AccountSyncService.onSignIn()` behandelt uitsluitend `profile` en `availability`. Geplande ritten
komen daar alleen langs via de eerste-login-migratie-RPC, en die **pusht** (lokaal → cloud). Een
verse inlog op een tweede toestel haalde zijn ritten dus nooit op: installeren → openen (uitgelogd,
opstart-reconcile is een no-op) → inloggen → terug naar Home → lege lijst. Dezelfde bug, andere
volgorde. Alleen de opstart-reconcile repareren had dit pad laten staan.

Bewust géén `reconcileOnStartup()` op die plek: die is one-shot, en bij uitloggen + opnieuw
inloggen met hetzelfde account (§2's uitlog-ronde) zou de guard juist de drain overslaan — precies
de regressie die 21-10 dichtte. `reconcileOnForeground()` begint zelf met een drain, dus die
garantie blijft staan en de pull komt erbij.

## Wat het ontwerp bepaalde, en het was niet wat ik verwachtte

Gemeten tijdens het bouwen van de test: **een `StreamProvider` waar niemand naar luistert,
abonneert zich nooit op zijn bron.** `authStateProvider` blijft dan eeuwig `AsyncLoading`, dus
`.value` is `null` voor een gewoon ingelogde gebruiker en `.future` lost nooit op.

`reconcileOnForeground()` kwam daar weg mee omdat het pas bij een voorgrond-overgang draait,
wanneer `profile_notifier`, `availability_notifier` en `planned_rides_notifier` die listener al via
`ref.watch` houden. Bij `initState` is er nog geen enkele build geweest en geldt die aanname niet.
De naïeve versie van deze fix — `reconcileOnStartup()` die `.value` leest — zou dus op elke koude
start stil niets hebben gedaan, en dat was pas op een toestel opgevallen.

Opgelost met `_signedInUser()`: eerst de provider, anders de herstelde sessie via
`Supabase.instance.client.auth.currentSession?.user`. Dat is dezelfde bron als de seed van
`authState` zelf, en `Supabase.initialize()` is in `main()` geawait vóór `runApp()`.
`reconcileOnForeground()` gebruikt hem nu ook — dat haalt ook daar de verborgen afhankelijkheid van
"staat er toevallig al een listener" weg.

**Doodlopend pad, bewust vastgelegd:** eerst geprobeerd met `_ref.listen` om de provider wakker te
maken. Dat legt een afhankelijkheidsrand van deze provider naar `authStateProvider`, en de
eerstvolgende auth-wijziging disposet de `Ref` die `CloudSyncReconciler` over `await`-grenzen heen
vasthoudt — exact de fout die plan 21-11 dichtte. De derde test ving dat op voordat het een toestel
kon halen.

## Verificatie

- `flutter test`: **451/451**. De bekende notificatietest die na 19:00 UTC faalt, draaide hier vóór
  dat venster en is dus niet als bewijs te gebruiken.
- `flutter analyze`: **0 errors**, 21 warnings + 141 infos = 162 — exact de bestaande baseline.
  (Terzijde: STATE.md noemt die 162 "infos"; 21 ervan zijn warnings, allemaal ongebruikte locals in
  `week_agenda_screen`, `ride_detail_screen` en `home_screen`, geen van alle van deze wijziging.)
- Negatief geverifieerd: op de code van vóór de fix compileert het testbestand niet.

## Nog niet bewezen — dit heeft een toestel nodig

Deze fix is **niet** op een toestel getest. De cloud-leeskant is zonder levende backend niet
waarneembaar zolang `CloudSyncReconciler` rechtstreeks naar `Supabase.instance.client` grijpt
(backlog #60). Wat de tests bewijzen: dat het opstartpad bestaat, dat het zijn werk bereikt, en dat
de guard klopt. Wat ze niet bewijzen: dat de rijen daadwerkelijk binnenkomen.

Voorstel voor de eerstvolgende toestelsessie, aan te haken bij de openstaande stappen in
`.planning/phases/21-sync-migration/MORGEN.md`: na de §4-meting de app opnieuw installeren, inloggen
en kijken of PLANNED **meteen** gevuld is, zonder de app weg te zetten. Dat is de directe
tegenproef van device session 7.

## Meegenomen in de sweep, bewust niet aangeraakt

`profile_screen.dart:139` leest `ref.read(authStateProvider).value?.email` voor de
Calendar-mismatchcheck. Dat is dezelfde listener-afhankelijke lezing, maar de faalmodus is
goedaardig: bij `null` concludeert hij "geen mismatch" en toont niets — een fail-safe die daar
expliciet zo bedoeld is. Tegen de tijd dat ProfileScreen dit draait, houdt `AccountSection` de
listener al. Gezien, gewogen, gelaten.
