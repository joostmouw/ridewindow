---
phase: 22-account-backed-feedback
plan: 01
status: complete
completed: 2026-09-07
requirements: [FB-01, FB-02, FB-03, FB-04, FB-05]
---

# 22-01 — Feedback naar de database

Uitgevoerd als één slice, inline in de sessie van 2026-09-07, nadat Joost koos om v3.0 af te maken
in plaats van fase 22 naar de backlog te schuiven.

## De vondst die het bouwen rechtvaardigde

`0001_accounts_sync.sql` gaf `public.feedback` een insertpolicy die anonieme feedback expliciet
toelaat:

```sql
for insert with check (user_id is null or auth.uid() = user_id)
```

Maar de grant eronder ging alleen naar `authenticated`. Postgres controleert tabelrechten **vóór**
het policies evalueert, dus een uitgelogde client strandde op de grant en bereikte de policy die hem
juist toestond nooit. FB-03 was daarmee onbereikbaar zonder dat iets dat meldde — dezelfde klasse
als de RLS-weigering op `group_rides` van diezelfde dag: twee lagen die allebei moeten kloppen.

`0004_feedback_anonymous_insert.sql` geeft `anon` een INSERT-grant, en nadrukkelijk **geen** SELECT
(FB-05) en **geen** UPDATE.

## Wat dat afdwong in het ontwerp

Geen UPDATE-grant betekent dat een upsert onmogelijk is: PostgREST stuurt bij upsert
`resolution=merge-duplicates`, en Postgres eist voor die `on conflict do update`-tak UPDATE-rechten
ook wanneer er geen conflict optreedt. Feedback moet dus met een échte insert vertrekken.

Daarom: `CloudSyncGateway.insertRow` naast de bestaande `upsertRow`, en een aparte tak in
`CloudSyncReconciler.drainOutbox`. Die tak hoort daar en niet in `SyncOutboxService`, dat bewust
niets van tabelnamen of van de cloud-SDK weet.

## Wat er staat

| Requirement | Hoe |
|---|---|
| FB-01 | `feedback_dialog.dart` schrijft naar `public.feedback`; de `mailto:`-route en `buildFeedbackMailtoUri` zijn weg |
| FB-02 | `buildFeedbackContext` vriest score, weerinvoer én de eigen tolerances in op het moment van versturen |
| FB-03 | `user_id: null` wanneer niemand is ingelogd; de drain draait vóór de "wie is ingelogd"-controle |
| FB-04 | Verzenden loopt via de outbox van fase 21 — offline geschreven feedback blijft staan en vertrekt bij de volgende voorgrondovergang |
| FB-05 | Geen select-grant en geen select-policy; `insertRow` doet bewust geen `.select()` |

**Waarom de context wordt ingevroren en niet later opgehaald:** het weerbericht van vorige week is
weg en de gebruiker heeft zijn schuifjes intussen misschien verzet. Zonder de tolerances is een
score niet te beoordelen — 18 graden is voor de een perfect en voor de ander koud. Wat er bewust
niet in gaat: geen coördinaten (alleen de stadsnaam die de gebruiker zelf ziet), geen e-mailadres,
geen uid in het contextveld.

De uuid wordt lokaal gegenereerd en dient óók als `entityKey`. Dat is niet cosmetisch: de outbox
coalesceert op (entity, entityKey), wat voor profiel en beschikbaarheid precies de bedoeling is,
maar voor feedback zou betekenen dat je tweede bericht je eerste overschrijft.

## Tests

`feedback_dialog_test.dart` is herschreven (de oude toetste de verwijderde mailto-functie): de pure
payload-opbouw, het lege-lijst-pad, en de anonieme rij. In
`cloud_sync_reconciler_gateway_test.dart` twee nieuwe tests die vastleggen dat feedback via
`insertRow` gaat en niet via `upsertRow`, en dat het uitgelogd werkt. Suite 479/479.

## Wat nog moet gebeuren

1. **`0004_feedback_anonymous_insert.sql` draaien op de live database.** Tot dat gebeurt faalt
   anonieme feedback stil in de outbox (de rij blijft `pending` en wordt na het pogingenplafond
   weggegooid). Ingelogde feedback werkt wel, want die grant stond er al.
2. **Op een toestel bevestigen** dat een verzonden bericht daadwerkelijk in `public.feedback` landt.
   Dat is niet vanuit de app te controleren — FB-05 verbiedt teruglezen met opzet — dus dit vraagt
   één blik in de Supabase-tabeleditor.
