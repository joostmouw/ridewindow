---
quick_id: 261011-rtk
status: complete
date: 2026-10-11
---

Alleen documentatie, geen code, geen toesteltests (de Oppo was bezet met de nulmeting van 37-05).
`ROUTE-EPIC.md` toegevoegd, `BACKLOG.md` #96 aangevuld.

**Belangrijkste vondsten.**

1. **Strava's API is per 1 juni 2026 een betaald programma geworden.** #96 zei "athlete capacity 1,
   review nodig"; de werkelijke drempel is nu een verplicht Strava-abonnement voor de ontwikkelaar
   (VS $ 11,99/maand) plus een server-uitzondering voor de token-ruil plus review boven tien atleten.
   Dat maakt "Strava met inloggen" tot een bewuste €0-breuk in plaats van een vervelende hobbel.
   Advies in het onderzoek: nee, tenzij testers erom vragen.
2. **Strava-routelinks zijn sinds ~april 2026 achter de login** (r/Strava-meldingen over club-routes).
   Zonder OAuth is er dus geen Strava-lijn; de deel-link blijft fase-1-waarde (opent Strava zelf).
   Antwoord op ROUTE-INGANG-vraag 4 staat in het Strava-helpcentrum: delen stuurt de route-URL als
   tekst; privé-routes zijn uit de app niet deelbaar.
3. **Kaarttegels:** CARTO blijft gratis tot 5 M tegelverzoeken/maand voor niet-commercieel, maar
   vraagt nu een gratis API-sleutel per e-mail. OpenFreeMap is sleutel- en limietloos maar
   vector-only met een minder rijpe Flutter-plug-in. Conclusie: silhouet eerst (offline-bestendig,
   past bij de kern van de app), raster-tegels daarna.
4. **#89 (Komoot-groepsplanning) is beantwoord** met de Group Rides-feiten: account- en
   notificatieplicht voor deelname, startregio ontgrendeld, routewijzigingen propageren, QR/link
   intrekbaar, datum-tijd via route-comments, nul weer- of beschikbaarheidsfuncties. Overlap met
   Ridewindow is alleen "route bij de groepsrit" (fase 4). Positionering: Komoot kiest het waar,
   Ridewindow het wanneer. Voorstel: #89 sluiten.
5. **Health Connect valt af** als Strava-omweg: Strava schrijft op Android alleen tijd/afstand/
   calorieën weg, geen routes (routes alleen via Apple Health op iOS).

**Open voor Joost:** het privé-tour-testprotocol onderaan ROUTE-EPIC.md (5 minuten; bepaalt of
fase 2 alle Komoot-tours dekt), silhouet-eerst bevestigen, eventueel de CARTO-sleutel aanvragen
(gratis per e-mail). Milestone-vorming (v5.0-voorstellen, requirements) is bewust aan de
`/gsd`-milestone-stap gelaten.
