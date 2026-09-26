---
quick_id: 260926-build-59-ritkaart-feedback
date: 2026-09-26
status: complete
---

# Build 59-rondje: scorepil in de hoek, meerkeuze achter een vinkje, keuzeblok inklapbaar

## Wat er gebouwd is (twee code-commits)

1. **De ritkaart op Rides.** De scorepil ("99 Toprit") hing midden naast
   de kaart: de buitenste rij van `RideCard` centreerde zijn kinderen, en
   de rechterkolom (pil + "+"-regel) zweefde daardoor naast de veel
   hogere linkerkolom. De rij begint nu bovenaan: de pil staat in de
   rechterbovenhoek en de "+ sinds planning"-regel eronder, op de hoogte
   van de datumregel. "Kies samen een venster" is bovendien een kopregel
   geworden die open en dicht kan: dicht zodra jij op alle opties hebt
   gestemd ("Jij hebt overal gestemd"), open zolang er op jou gewacht
   wordt, en een tik van de gebruiker gaat altijd vóór de automatiek.
2. **Het uitnodigen.** De vensterkiezer van slice 2 kwam ongevraagd na
   het kiezen van maatjes; Joost miste de logica erachter. Die staat er
   nu in stap 1 als vinkje "Meerdere vensters voorleggen" (EN: "Select
   multiple ride dates"), standaard uit. Uit: de knop heet "Uitnodigen"
   en de rit gaat direct het ene venster in waar je vandaan kwam, zonder
   tussenstap. Aan: de knop heet "Verder: kies vensters" en de bestaande
   kiezer komt zoals hij was.

## Vondsten

1. De ongevraagde vensterkiezer was geen bug maar het ontwerp van slice
   2 ("na het kiezen van maatjes vraagt de app welke vensters je
   voorlegt"). Het venster waar je vandaan kwam stond aangevinkt, dus
   bevestigen zonder aanraken gaf gewoon de oude enkele uitnodiging --
   maar de stap zelf kwam altijd, en dat voelde als uit het niets.
2. De automatiek van het inklappen hangt aan `RideOption.voteOf` over
   alle opties. Een handmatig dichtgeklapt blok komt niet ongevraagd
   terug: `_manual` wint van de automatiek totdat je weer tikt.
3. De invite-tests hadden de verwachting "de vensterkiezer komt altijd"
   in vijf tests ingebakken. Die zijn per test omgebouwd naar
   vinkje-aan of vinkje-uit, zodat beide paden nu bewezen worden;
   zonder vinkje mag de vensterstap er níet meer zijn.
4. Het detailscherm laat de opties gewoon open staan: daar ben je voor
   het overzicht. Alleen de lijstkaart klapt.

## Bewijs en grenzen

- Volledige suite: **986 tests groen** (was 983, +3: dicht en open van
  het keuzeblok, en de maatjesflow met het vinkje aan).
- `flutter analyze`: **201 infos**, precies de bestaande baseline; de
  vier nieuwe komma-infos van de nieuwe tests zijn meteen opgeruimd.
- Nieuwe ARB-sleutels in beide talen: `pelotonMultiWindows` (+hint),
  `pelotonOptionsYouVoted`, `pelotonOptionsWaitingForYou`. Geen
  bestaande sleutel weggegooid.
- Geen versiebump, geen release; **goedkeuren op de Oppo is Joost's
  ronde**: de pil-positie en het inklapblok op de Ritten-tab, en het
  uitnodigen met en zonder het nieuwe vinkje.
