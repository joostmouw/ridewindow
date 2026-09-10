---
sketch: 011
name: daglicht
question: "Hoe laat de app zien dat een venster in het donker valt, in zijn eigen vormtaal?"
winner: "A + hele etmaal"
tags: [daglicht, weerbalken, scoring, profiel, fase-26]
---

# Schets 011: Daglicht

## Design Question

Backlog #68 is gerepareerd aan de rekenkant: de zonstand wordt lokaal berekend en de score krijgt
een aftrek naar rato van hoeveel van het venster in het donker valt. Wat overblijft is **hoe je het
ziet**, en waar je het instelt.

Joost, 2026-09-10: *"Ik verwacht ook wel iets te zien in de thema en stijl van de app maar dan dat
je dit kan zijn bij de rides. Ook wil ik dit in de tolerantie slides kunnen instellen hoe het donker
en licht wordt meegenomen in je profiel"* — met een referentiebeeld van een paarse
zonsopgang/-ondergangtegel uit een andere app.

Die referentie gaat over de **inhoud**, niet over de vorm: RideWindow heeft al een eigen taal voor
precies dit soort informatie — de weerbalken met een zone en een markering. De schets sluit daarop
aan in plaats van een vreemde tegel over te nemen.

## How to View

```bash
python3 -m http.server 8765          # vanuit de repo-root, anders laadt het lettertype niet
open http://localhost:8765/.planning/sketches/011-daglicht/index.html
```

## Variants

- **A — vierde balk op het detailscherm.** Naast temperatuur, neerslag en wind, in exact dezelfde
  vorm: een as van 00:00 tot 24:00, het lichte deel in goud, je rit als blauw blok. Zegt vanzelf dat
  daglicht net zo goed meetelt in de score.
- **B — strook op de ritkaart zelf.** Al op Home zichtbaar zonder doorklikken, maar op élke kaart —
  ook op de negen van de tien waar niets aan de hand is.

Onafhankelijk van de keuze: **één regel op de ritkaart**, en alleen als er iets te melden valt
("Zon onder om 20:07 — grotendeels in het donker"). Dezelfde vorm als de rolregel uit schets 008.

En in Profiel een **vierde schuif**. De drie bestaande zeggen *waar ligt jouw grens*; deze zegt *hoe
zwaar telt donker voor jou*, dus een woordschaal in plaats van een getal met een eenheid. De schets
toont wat elke stand met de gewraakte rit doet, van 100 (maakt me niet uit) tot 62 (alleen bij
daglicht).

## What to Look For

- Staat de daglichtbalk naast zijn drie broers alsof hij er altijd al hoorde?
- Is de gouden tint van "licht" te onderscheiden van het groen dat "binnen jouw bereik" betekent, of
  gaan die twee betekenissen door elkaar lopen?
- Ook helemaal rechts op de schuif verdwijnt een donkere rit niet. Ver genoeg, of wil je daar wél
  een harde uitsluiting?

## Wat Joost koos (2026-09-10)

**Variant A**, met de as over het **hele etmaal**. Gebouwd:

- `DaylightBar` staat als vierde balk op Home's beste kaart (waar zijn drie broers ook staan) en
  onderaan de weersectie op het detailscherm.
- `DaylightNote` is de ene regel op de ritkaart, en verschijnt alleen als het donker de rit raakt —
  negen van de tien vensters vallen volledig bij daglicht en daar is de zonsondergang ruis.
- In Profiel staat een vierde schuif met vijf standen, met er onder wat die stand kost in punten.
- `SlotGenerator.applyDaylight` past de aftrek toe, apart van `refine` omdat dit de enige stap is
  die de locatie nodig heeft.

**Migratie 0007 moet worden toegepast** voordat een build hiermee live gaat: `darkness_weight` staat
in `toRow`, en zonder die kolom weigert Postgres de profiel-upsert.
