---
quick_id: 260908-n3r
slug: feedback-vertrok-niet
date: 2026-09-08
status: complete
---

# Feedback zei "bedankt" maar vertrok nooit

## Wat Joost zag

Feedback verstuurd vanuit de app, niets terug te vinden in Supabase.

## Wat er aan de hand was

De hele keten was goed op één schakel na. Nagelopen, van onder naar boven:

| Laag | Stand |
|---|---|
| Tabel `public.feedback` | Kolommen kloppen: `id, user_id, rating, comment, context, created_at` |
| RLS-policy | `user_id is null or auth.uid() = user_id` — anoniem mag |
| Grant | `insert` naar `anon` én `authenticated` (migratie 0004) |
| Drain | Doet een échte `insert` voor feedback, geen upsert — de tabel heeft geen UPDATE-recht |
| `reconcileOnForeground` | Roept `drainOutbox()` vóór de "wie is ingelogd"-controle, dus uitgelogd werkt |
| **`_submit` in de dialoog** | **Schreef alleen naar de lokale outbox en toonde "bedankt". Startte niets.** |

De rij bleef dus op het toestel staan tot de app toevallig een
voorgrondovergang maakte. Verstuur je feedback en blijf je in de app, dan
gebeurt er niets — terwijl het scherm zegt dat het gelukt is. Dat is het
slechtst mogelijke van twee werelden: de gebruiker denkt klaar te zijn en de
ontvanger ziet niets.

## De fix

`unawaited(reconciler.drainOutbox())` direct na het opslaan.

**Bewust niet afgewacht.** De outbox bestaat juist om het schrijven los te
koppelen van het versturen (FB-04): wie zonder bereik feedback schrijft, mag
die niet kwijtraken. Mislukt de drain, dan blijft de rij staan en gaat hij mee
met de volgende. Deze aanroep maakt alleen normaal wat eerst toeval was.
`drainOutbox` heeft een eigen try/catch en een re-entrancy-guard, dus hij kan
geen scherm raken.

De reconciler wordt vóór de `await` uit `ref` gelezen, net als `messenger` en
`navigator` — dit scherm sluit zichzelf, en `ref.read` op een afgebroken widget
gooit.

## Verificatie

Test 7 in `test/features/feedback_dialog_test.dart`: verzenden zet één rij in
de outbox én roept `drain` aan. In-memory Drift plus een
`_RecordingSyncOutboxService`, dezelfde vorm als in
`outbox_drain_wiring_test.dart`.

**De test is ook op falen gecontroleerd**: met de nieuwe regel uitgezet valt
hij om op `Expected: true / Actual: false`. Een test die niet kan falen is geen
test.

Volledige suite: 523 groen.

## Wat dit niet verklaart, en wat Joost zelf moet nakijken

1. **Feedback van vóór vandaag is weg.** Die stond in de lokale outbox op het
   toestel, en de app-data daar is verdwenen (zie de kloonprofiel-notitie in
   STATE.md). Niet te herstellen.
2. **Of migratie 0004 op de gehoste database staat.** Zonder die grant strandt
   anonieme feedback op het tabelrecht, nog vóór de policy. Controlequery staat
   onderaan `supabase/migrations/0004_feedback_anonymous_insert.sql`; verwacht
   precies twee regels, INSERT voor `anon` en INSERT voor `authenticated`.
3. **Het plafond van vijf pogingen.** `SyncOutboxService.kMaxSendAttempts` = 5;
   daarna wordt een rij definitief weggegooid. Feedback die vijf keer op een
   ontbrekende grant strandde, bestaat niet meer.

Het verborgen debugmenu onder Profiel ("Inspect sync outbox") laat zien wat er
nog wacht.
