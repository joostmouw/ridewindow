---
quick_id: 260919-g1b
slug: analytics
status: complete
date: 2026-09-19
commits: [66286f4, 3efcae2]
---

# Gebruiksstatistiek — wat er staat en wat jij nog moet doen

## De constraint is bewust herschreven, niet opgerekt

`CLAUDE.md` en `PROJECT.md` beloofden: *"een uitgelogde gebruiker zijn data verlaat het
toestel nooit"*. Daar staat nu één voorwaarde bij: **na een expliciete ja**. Zonder
toestemming vertrekt er niets, uitgelogd noch ingelogd. Geen derde sub-processor — dezelfde
Supabase in Parijs, via de outbox die sinds fase 21 bestaat.

## Drie sloten

1. **Geen toestemming, geen rij.**
2. **Alleen namen uit een gesloten lijst** (`lib/core/analytics_events.dart`, tien stuks).
   Een onbekende naam wordt geweigerd. Telemetrie groeit anders vanzelf uit tot "meet alles".
3. **Props worden gesnoeid** tot getallen, booleans en codes van hooguit 24 tekens. Een zin
   komt er niet door — en migratie 0008 dwingt dat ook in Postgres af.

Een rij draagt **nooit** een `user_id`. De kolom bestaat alleen zodat de RLS-policy een
uitgelogde insert kan toestaan. Of iemand ingelogd was zegt de prop `signed_in`.

## De vraag komt bij de tweede start

Niet de eerste — fase 29 gaat er juist over dat die minuut niet volloopt met overlays, en een
vraag over statistiek gaat over jou, niet over de tester. Twee gelijke knoppen, geen vinkje:
een voorgevinkt vakje is geen geldige toestemming en een leeg vakje wordt genegeerd.
Intrekken in Profiel gooit de toestel-id weg, dus de draad naar eerdere rijen wordt
doorgeknipt.

## Wat er gemeten wordt

`first_run` · `app_open` · `onboarding_done` · `slot_opened` · `ride_planned` ·
`ride_unplanned` · `availability_edited` · `peloton_invite` · `location_warning` ·
`feedback_sent`

Vier daarvan zijn aangesloten (`first_run`, `app_open`, `onboarding_done`, `ride_planned`,
`ride_unplanned`, `location_warning`). De overige drie namen bestaan wel maar hebben nog geen
aanroep — bewust, zodat de lijst leidend is en niet de code.

`location_warning` is degene die de Aruba-melding van vandaag zichtbaar had gemaakt voordat
een mens hem zag.

## Het rapport

    dart run tool/analytics_report.dart --days 30
    dart run tool/analytics_report.dart --html ~/Desktop/gebruik.html

Leest met de service-role sleutel, buiten de app om — `app_events` heeft met opzet geen
select-grant. Een artifact kan het niet doen: de CSP daar blokkeert fetch naar Supabase.

## Wat jij nog moet doen

| | Wat | Waar |
|---|---|---|
| **1** | **Migratie 0008 draaien** op het Supabase-project. Zonder dit bestaat de tabel niet en blijven alle rijen in de lokale outbox staan (waar ze niets stukmaken). | Supabase > SQL Editor, plak `supabase/migrations/0008_app_events.sql` |
| **2** | **De service-role sleutel in je omgeving zetten** — anders kan het rapport niet lezen. | Project Settings > API > `service_role`, dan `export SUPABASE_SERVICE_ROLE_KEY='eyJ...'` |
| **3** | **Privacybeleid bijwerken**: een alinea over anonieme statistiek na toestemming. De tekst staat op GitHub Pages. | `docs/` |
| **4** | **Data Safety-formulier** in de Play Console: "App activity → App interactions", optioneel, niet gedeeld met derden. | Play Console |

Punt 1 en 2 zijn Console-instellingen; die doe ik voor je zodra je zegt dat het mag. Punt 3
en 4 zijn teksten die ik kan schrijven maar die jij moet indienen.

## Verificatie

- `flutter analyze`: 0 fouten
- `flutter test`: 606/606 groen (11 nieuwe, allemaal op de drie sloten)
- `dart analyze tool/analytics_report.dart`: schoon
- Het rapport zonder sleutel legt uit wat er ontbreekt in plaats van te crashen

## Niet met eigen ogen gezien

Er is nog geen enkele rij geschreven — de tabel bestaat nog niet. De hele keten
(toestemming → outbox → drain → Postgres) is per schakel getest maar nooit in zijn geheel
gelopen. Dat kan pas na punt 1.
