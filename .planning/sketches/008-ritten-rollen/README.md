---
sketch: 008
name: ritten-rollen
question: "Hoe lees je aan een rit af welke rol jij erin hebt, en hoe kom je vanaf een gedeelde rit in één tik bij het detailscherm?"
winner: null
tags: [ritten, peloton, rollen, navigatie, lijst]
---

# Schets 008: Ritten en rollen

## Design Question

Een rit kan vier dingen zijn: **je moet er nog op antwoorden**, **jij organiseert hem**, **je gaat
mee met iemand anders**, of **je rijdt alleen**. Vandaag is dat onderscheid niet af te lezen aan de
rit zelf, alleen aan waar hij toevallig staat. En bij een gedeelde rit kom je nergens.

## Wat er nu misgaat (in de code, niet in het gevoel)

| Ritsoort | Home | Rides → Mijn ritten | Rides → Peloton |
|---|---|---|---|
| Zelf gepland | ✅ | ✅ | — |
| Ik ga mee (geaccepteerd) | ✅ met "Met Peter" | ❌ | ✅ eigen sectie |
| **Ik organiseer** | **❌ nergens** | ❌ | ✅ eigen sectie |
| Uitnodiging, nog te beantwoorden | ❌ | ❌ | ✅ eigen sectie |

Drie concrete gebreken:

1. **Gedeelde ritten hebben geen dag.** `_formatRide()` in `peloton_tab.dart` drukt `09:00 – 13:00`
   af — geen datum, geen dagnaam. Je ziet niet wanneer de rit is.
2. **Gedeelde ritten zijn niet aan te tikken.** `_JoinedRideRow` en `_OwnedRideRow` zijn `ListTile`s
   zonder `onTap`, terwijl elke eigen ritkaart naar `/detail` springt.
3. **Joined en owned dragen hetzelfde icoon** (`AppIcons.usersThree`). De rol zit in de sectiekop,
   niet in de rit.

## How to View

```bash
python3 -m http.server 8765          # vanuit de repo-root, anders laadt het lettertype niet
open http://localhost:8765/.planning/sketches/008-ritten-rollen/index.html
```

## Variants

- **A: Eén lijst met filterrij** — alle ritten chronologisch, rol als gekleurde regel onder de tijd,
  en een tekstfilterrij met telling (`Alles 5 · Ik organiseer 2 · Ik ga mee 1 · Alleen ik 1`).
  Dezelfde vorm als het periodefilter op Home.
- **B: Vier secties onder elkaar** — vier `SectionCard`s met kop en telling. Kleinste ingreep: de
  component bestaat al, de rijen worden alleen tikbaar en krijgen hun datum. Kost je wel de
  chronologie: zaterdag staat boven dinsdag omdat de rol sorteert.
- **C: Rolstrook op de kaart** — chronologisch met weekkoppen; de rol is een gekleurde strook links
  plus een chip bovenaan de kaart. Af te lezen zonder te lezen. Geen filter, geen koppen.

Alle drie tonen dezelfde vijf ritten, alle drie met de hele regel tikbaar (chevron rechts). De
kolom ernaast is in alle drie hetzelfde: **waar je dan uitkomt** — het bestaande detailscherm met
er één blok bij, wie er meegaat en wie nog moet antwoorden.

## What to Look For

- **Chronologie versus rol.** A en C laten je week op volgorde zien; B hakt hem in vieren. Wat wil
  je als eerste weten: *wanneer* rijd ik, of *wat organiseer ik*?
- **Telling versus opsomming.** In A en B staat het aantal per rol als getal (`Ik organiseer 2`);
  in C moet je tellen. Beantwoordt dat getal de vraag al?
- **De vier iconen.** Vlag = jij organiseert, drie mensen = je gaat mee, fietser = alleen jij,
  zandloper = wacht op jou. Zijn die vier op 20px uit elkaar te houden?
- **De uitnodiging.** In alle drie staat "Ik ga mee / Kan niet" ín de lijst, zodat je niet eerst
  naar een ander tabblad hoeft. Weegt dat op tegen de extra hoogte van die kaart?
- **Het tweede tabblad.** In alle drie krimpt Peloton tot **Maatjes** — alleen nog wie je maatjes
  zijn en hoe je er een bij krijgt. Alle ritten staan links.
