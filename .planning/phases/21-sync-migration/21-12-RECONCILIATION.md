# 21-12 — samenvoeging van twee parallelle takken

Op 2026-08-04 is dezelfde bug twee keer, onafhankelijk, opgelost. Deze notitie legt vast wat
waarvandaan komt, zodat niemand later denkt dat er dubbel werk in de historie zit dat weg kan.

## Wat er gebeurde

Twee sessies liepen tegelijk. Beide vonden dat `AvailabilityRepository` de kale urenmap als
outbox-payload enqueuede, waardoor PostgREST de urensleutels als kolomnamen las
(`PGRST204: Could not find the '1-0' column of 'availability'`), en beide vonden dat
`_drainInternal` faalde zonder te loggen.

- **Op main** (commits `0e7f837`…`395e214`, als plan 21-12): payloadvorm gefixt, per-rij
  faallogging, een **attempt-plafond** (`kMaxSendAttempts = 5`) dat een rij na vijf mislukkingen
  wéggooit, plus `test/data/database/outbox_payload_shape_test.dart` — een invariant die
  bewaakt dat elke outbox-payload een echte rij is.
- **Op de tak `worktree-21-12-outbox-observability`** (als 21-12 + 21-13): dezelfde payloadfix en
  faallogging, plus een **samenvattingsregel per drain**, een **debugmenu** om de outbox op het
  toestel te bekijken en te wissen, de **versieweergave**, de **§0-correctie** hieronder, en —
  als enige van de twee — **verificatie op een echt toestel tegen de echte database**.

Deze tak is main plus dat tweede lijstje. Niets van main is weggegooid; het attempt-plafond en de
invarianttest staan er onveranderd in.

## De ene plek waar de twee elkaar tegenspraken

Main had een test met de naam *"a drain where every row succeeds logs nothing"* en de assertie
`expect(messages, isEmpty)`. Die is bewust omgedraaid naar een test die juist één
samenvattingsregel eist. De reden is niet smaak maar wat er die dag gebeurde:

1. **Zwijgen bij succes maakt "de drain vond niets" niet te onderscheiden van "de drain heeft
   nooit gedraaid".** Dat onderscheid is in 21-10 en 21-11 twee keer verkeerd gelezen, en kostte
   allebei de keren een toestelsessie.
2. **Een kale telling is niet herleidbaar.** Een drain meldde `1 sent` terwijl
   `availability.updated_at` in Postgres aantoonbaar onaangeroerd bleef — de geslaagde send was
   een `profile`-rij. Dat leverde bijna een onterechte SYNC-05 PASS op. Daarom staan de
   entiteitsnamen er nu bij: `2 sent (availability, profile)`.

De prijs is één regel per foreground-cyclus in logcat. Dat is goedkoper dan een sessie diagnose.

## Openstaand punt voor Joost, geen actie van mij

Main's attempt-plafond gooit een rij na vijf mislukte pogingen weg. Dat is een bewuste keuze van
die tak en hij staat er nog in — maar het betekent wel dat een beschikbaarheidswijziging
stilzwijgend kan sneuvelen als er iets structureels mis is. Nu de payloadbug gefixt is, is het
risico klein; het is de moeite waard om er een keer bewust ja tegen te zeggen in plaats van het
mee te laten liften.

## Bewijs

Zie de secties "Device session 3" en "Tweede, onafhankelijke SYNC-05-meting" in
`MANUAL-VERIFICATION-21.md`: twee metingen, in tegengestelde richting, elk bevestigd in zowel
logcat als de Supabase Table Editor.
