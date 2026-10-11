# Fase 37: Nulmeting

Op deze getallen rusten de vloeren van de uitschieterregel (D-15, `tool/usage/usage_floors.dart`) en de voorgestelde plafonds voor fase 38 en 39 (D-18). Er staan alleen dagtotalen in, geen rijen, ids, namen of tekst (D-19).

## Wanneer en hoe

- **Datum:** 2026-10-11, tussen 20:40 en 21:00 (Amsterdam).
- **Toestemming:** Joost koos op 2026-10-11 in de chat met de orchestrator voor **"beide"**: de productietellingen lezen (alleen totalen) en een zware Oppo-sessie draaien.
- **Historie (D-17.1):** `usage_daily_counts` over 200 dagen (2026-03-26 t/m 2026-10-10). Dat dekt alles: `app_events` bestaat sinds 2026-09-19 (0008) en accounts sinds fase 21. Vandaag telt niet mee, want die dag loopt nog. Gelezen met de service-role-sleutel, zowel met `dart run tool/usage_report.dart --days 120` als met de ruwe rpc. De werkbestanden staan in de scratchpad van de sessie, buiten de repo.
- **Oppo-sessie (D-17.2):** build 1.0.59 (70), geïnstalleerd via Play. Ingelogd als Joost, met statistiek-toestemming aan. Snapshot 1 om 20:46:41 en snapshot 2 om 20:54:31, dus ongeveer acht minuten bewust zwaar gebruik:
  - elke tab open en scrollen, tips en "Why this score" bekeken;
  - twee ritten gepland, waarvan er één een groepsrit werd met drie vensteropties;
  - een maatjeslink en een groepslink aangemaakt (de deelknop geannuleerd, niets gedeeld);
  - twee keer feedback gestuurd ("nulmeting 37, test 1/2");
  - twee keer koud herstart.

  Na snapshot 2 is de testgroepsrit via de app verwijderd en de tweede rit weer uitgepland. Snapshot 3 (20:57:12) bevestigt dat `group_rides` en `group_ride_options` voor vandaag terug zijn op hun stand van vóór de sessie.
- **Vervuiling:** het venster was kort. Volgens `distinct_senders` heeft geen ander toestel of account in dat venster rijen toegevoegd: bij elke bron met een afzender bleef het aantal afzenders gelijk of nam het alleen toe door de Oppo.

## Gemeten

"Drukste dag" is het hoogste dagtotaal in de historie. "Max per afzender" is het hoogste aantal rijen van één toestel of account op één dag. "p95 per afzender" is de 95e percentiel, over alle dagen met afzenders, van de dagelijkse p95 per afzender. Bij de Oppo-sessie staat eerst het verschil in rijen tussen snapshot 1 en 2, en dan de drukste afzender van vandaag bij snapshot 2.

| Bron | Drukste dag | Max per afzender | p95 per afzender | Oppo-sessie (rijen / max één afzender) | Ondergrens? |
|------|------------:|-----------------:|-----------------:|----------------------------------------:|:-----------:|
| feedback_account   |  3 | 3 | 3 | 2 / 2  | nee |
| feedback_anoniem   |  2 | geen afzender (F-02) | geen | 0 / geen | nee |
| app_events         | 27 | 9 | 8 | 6 / 12 | nee |
| friend_invites     |  9 | 7 | 5 | 1 / 1  | ja |
| group_invites      |  2 | 2 | 2 | 0 / geen | ja |
| group_rides        |  3 | 2 | 2 | 1 / 2  | ja |
| group_ride_options |  4 | 4 | 4 | 3 / 3  | ja |
| accounts_google    | 12 | geen afzender | geen | 0 / geen | ja |
| accounts_email     |  2 | geen afzender | geen | 0 / geen | ja |
| accounts_overig    |  0 | geen afzender | geen | 0 / geen | ja |

Toelichting:
- **Ondergrens (D-06, migratie 0014):** voor deze bronnen worden alleen rijen geteld die nu nog bestaan. Ingetrokken links, verwijderde ritten, gewiste opties en verwijderde accounts tellen niet mee, dus een vroegere dag kan drukker geweest zijn dan hier staat. De sessie liet dat zelf zien: na het verwijderen van de testrit telt vandaag weer één groepsrit en nul opties.
- **app_events:** de 12 bij de Oppo is wat dat ene toestel tot en met de sessie vandaag verstuurde, inclusief het gebruik eerder op de dag. Dat is de bovengrens van één zwaar gebruikt toestel op één dag. De app stuurt bewust weinig gebeurtenissen, vandaar de lage getallen.
- **group_invites:** de groepslink leverde geen nieuwe rij op. De app hergebruikt een nog geldige link van de groep.
- **p95** is afgerond naar het dichtstbijzijnde gehele getal.

## Vloeren

De regels (D-15):
- `vloer_totaal` = 3× de drukste dag;
- `vloer_afzender` = 3× het hoogste van de max per afzender in de historie en de Oppo-sessie.

Beide worden naar boven afgerond op een rond getal uit de reeks 5, 10, 15, 20, 25, 30, 40, 50, 75, 100, met een minimum van 5.

**Waarom 3×:** de vloer moet ruim boven een normale drukke dag liggen, zodat een tester die eens flink klikt of een kleine golf nieuwe testers geen seintje geeft. Tegelijk moet hij ruim onder het plafond van 10× uit fase 38/39 blijven, zodat Joost een opbouw ziet voordat er iets tegengehouden wordt. 3× zit daar met een factor drie marge naar beide kanten tussen.

| Bron | vloer_totaal | volgt uit | vloer_afzender | volgt uit |
|------|-------------:|-----------|---------------:|-----------|
| feedback_account   |  10 | 3×3 = 9   | 10 | 3×max(3, 2) = 9 |
| feedback_anoniem   |  10 | 3×2 = 6   | geen | geen afzender |
| app_events         | 100 | 3×27 = 81 | 40 | 3×max(9, 12) = 36 |
| friend_invites     |  30 | 3×9 = 27  | 25 | 3×max(7, 1) = 21 |
| group_invites      |  10 | 3×2 = 6   | 10 | 3×max(2, 0) = 6 |
| group_rides        |  10 | 3×3 = 9   | 10 | 3×max(2, 2) = 6 |
| group_ride_options |  15 | 3×4 = 12  | 15 | 3×max(4, 3) = 12 |
| accounts_google    |  40 | 3×12 = 36 | geen | geen afzender |
| accounts_email     |  10 | 3×2 = 6   | geen | geen afzender |
| accounts_overig    |   5 | minimum   | geen | geen afzender |

Let op: regel 1 vraagt ook meer dan 5× de mediaan van de 28 dagen ervoor, en die mediaan is nu bij bijna elke bron 0. Zolang dat zo is, beslist in de praktijk alleen de vloer. Gaat de productie-uitrol van 1.0.59 door (70 ter review), dan verwacht ik op `accounts_google` en `app_events` een paar dagen met een seintje. Dat is terecht: het is een echte sprong. Na een maand productie de vloeren opnieuw meten.

## Voorgesteld plafond

Uitgangspunt (D-18): 10× het drukste echte toestel of account, dus het hoogste van de historie-max per afzender en de Oppo-sessie, naar boven afgerond. Een plafond houdt tegen, een vloer geeft alleen een seintje.

| Bron | Drukste toestel/account | Voorgesteld plafond | Per | Fase |
|------|------------------------:|--------------------:|-----|------|
| feedback_account   |  3 |  30 per dag | afzender (account) | 38, RATE-01 |
| feedback_anoniem   |  2 (Oppo, als account gemeten) |  20 per dag | toestel; feedback heeft nog geen `device_id` (F-02), fase 38 moet dat eerst mogelijk maken | 38, RATE-01 |
| app_events         | 12 | 120 per dag | toestel (`device_id`) én afzender | 38, RATE-02 |
| friend_invites     |  7 |  70 per dag | account | 39, GRENS-01 |
| group_invites      |  2 |  20 per dag | account | 39, GRENS-01 |
| group_rides        |  2 |  20 per dag | account | 39, GRENS-01 |
| group_ride_options |  4 |  40 per dag | account | 39, GRENS-01 |
| accounts_google    | geen | geen plafond in 38/39 | nvt | 40 |
| accounts_email     | geen | geen plafond in 38/39 | nvt | 40 |
| accounts_overig    | geen | geen plafond in 38/39 | nvt | 40 |

Voor fase 39: de getallen per account voor uitnodigingen, ritten en opties zijn ondergrenzen. Een plafond van 10× een ondergrens is daardoor iets krapper dan het lijkt. Een open uitnodiging verloopt of wordt ingetrokken, dus GRENS-01 kan het beste het aantal tegelijk openstaande uitnodigingen begrenzen, en niet alleen het aantal per dag.

## Wat dit niet meet

- **Mislukte inwisselpogingen** van maatjes- en groepslinks (F-03). Die laten geen rij achter en zitten dus niet in `usage_daily_counts`. Dat hoort bij fase 39.
- **Feedback per toestel** (F-02). `feedback` heeft geen `device_id`, dus anonieme feedback heeft geen afzender en het plafond per toestel is hierboven geschat op basis van één account. Fase 38 voegt het toestel toe.
- **Ondergrens-bronnen** (`friend_invites`, `group_invites`, `group_rides`, `group_ride_options`, `accounts_*`): wat verdwenen is, telt niet mee (zie Gemeten).
- **Een gebruiker die meerdere toestellen of accounts tegelijk inzet.** Plafonds per toestel of account houden die niet tegen, de totaalvloer geeft dan wel een seintje.
