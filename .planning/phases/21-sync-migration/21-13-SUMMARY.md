# 21-13 — Samenvatting: availability werd als kolommen ge-upsert

**Status:** gefixt, en op het toestel bewezen (sessie 3, 2026-08-04 18:11-18:18, 1.0.18+19).
Dit is de bug waar SYNC-05 twee sessies op is blijven hangen.

## De fout

`AvailabilityRepository.save()` en `.enqueueCurrentState()` enqueueden allebei
`jsonEncode(toRecurringRow(hours))` als outbox-payload. Dat is de kále urenmap:

```json
{"1-9": "work", "6-14": "custom"}
```

`CloudSyncReconciler.drainOutbox` doet daar `.from('availability').upsert(payload)` mee, dus
PostgREST leest `1-9` en `6-14` als **kolomnamen**:

```
PostgrestException(message: Could not find the '1-0' column of 'availability'
in the schema cache, code: PGRST204, details: Bad Request)
```

`public.availability` heeft de kolommen `user_id`, `recurring`, `version`, `updated_at`. De
urenmap hoort dus ín `recurring`, met `user_id` ernaast — precies wat de leeskant
(`parseAvailabilityRow` → `row['recurring']`) al de hele tijd verwachtte, en precies wat
`ProfileRepository` wél goed doet via `profile.toRow(userId)`.

## Waarom 426 groene tests dit niet vingen

`test/data/repositories/availability_repository_test.dart` assertte:

```dart
expect(jsonDecode(pending.single.payload), equals(toRecurringRow(hours)));
```

De test legde de foute vorm dus vast in plaats van hem te betrappen. Een test die de
implementatie spiegelt in plaats van het contract, bewijst niets. Die assertie is vervangen door
één op de echte rijvorm, plus een expliciete controle dat de sleutelverzameling op het hoogste
niveau exact `{user_id, recurring}` is — elke andere sleutel dáár wordt door PostgREST als
kolomnaam gelezen, en dat is letterlijk het foutbeeld.

## De fix

Nieuwe `toAvailabilityRow(userId, hours)` in `lib/domain/services/availability_key.dart`, naast
`toRecurringRow`. Beide outbox-payloads gebruiken die nu.

`toRecurringRow` blijft ongewijzigd en wordt bewust niet vervangen: de
`migrate_account_data`-RPC verwacht juist de kale map als `p_availability_recurring`. Alleen de
upsert-payload had de rij-omhulling nodig. `version` en `updated_at` gaan er niet in — die
hebben een default en een `set_updated_at`-trigger in `0001_accounts_sync.sql`.

## Verificatie

- Suite: **groen** (`flutter test`, alles).
- Op het toestel, 1.0.18+19: outbox gewist via het 21-12-debugmenu, één beschikbaarheidsuur
  gewijzigd, achtergrond/voorgrond → `SyncOutbox: drain done — 1 pending, 1 sent, 0 failed`, en
  de accountsectie leest **"Synced"**.
- Nog open: de rij visueel bevestigen in Supabase Table Editor (§5a vraagt daarom; PostgREST
  accepteerde de upsert foutloos, wat sterk maar niet hetzelfde bewijs is).

## Wat dit zegt over de fase

Drie plannen op rij (21-10 caller, 21-11 disposed-Ref, 21-13 payloadvorm) waren nodig omdat elke
laag zijn eigen fout stil wegslikte. 21-12 was de kantelaar: binnen één minuut na het openen van
logcat stond de oorzaak er letterlijk. De les is niet "meer tests" — het waren er 426 — maar
**geen enkele catch zonder log**, en tests die het contract asserten in plaats van de
implementatie te herhalen.
