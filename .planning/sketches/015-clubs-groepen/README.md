---
sketch: 015
name: clubs-groepen
question: "Waar staan je groepen in Peloton, en hoe beheer je een groep?"
winner: "Vraag 1: A + C (C alleen als je groepen hebt) · Vraag 2: A"
tags: [peloton, clubs, groepen, beheer, fase-34]
---

# Schets 015: Groepen in Peloton

Milestone v4.2 Clubs, fase 34 (CLUB-01..09, 11). Gepubliceerd als
https://claude.ai/artifact/CWVC3CZLXGNWLtxSzuwo4x

## Vraag 1 — waar staan je groepen?
- **A: Bovenaan de Peloton-tab** *(advies)* — sectie Groepen boven Maatjes; zonder groep een uitnodigende kaart.
- **B: Eigen tab** — Ritten / Groepen / Maatjes.
- **C: Filter op Ritten** — groepen als chips boven de rittenlijst.

## Vraag 2 — hoe beheer je een groep?
- **A: Menu per lid** *(advies)* — ⋮ per lid voor beheerders, groepsbrede acties in het appbar-menu.
- **B: Knop "Beheren"** — aparte beheerstand met alle knoppen zichtbaar.
- **C: Tik op een lid** — bottom sheet met acties per lid.

## Vast in elke variant
Groep maken (sheet, max 40 tekens), `/group/:code`-landing (eerst inloggen), grensmeldingen
(`group_full`, `too_many_groups`) in gewone taal, opheffen met bevestiging, `last_admin`-uitleg.
Verlaten en eruit halen krijgen een snackbar met ongedaan maken.

## How to View
Open het artifact, of `python3 -m http.server 8765` vanuit de repo-root en ga naar
`/.planning/sketches/015-clubs-groepen/index.html`.

## Gekozen (Joost, 2026-09-23)
- **Vraag 1: A én C.** Groepen staan bovenaan de Peloton-tab (A). Daarnaast krijgt de Ritten-tab
  de rij groepschips als filter (C) — **alleen als je in minstens één groep zit**; zonder groepen
  staat daar niets, ook geen "+ Groep"-chip. Het filter hoort bij groepsritten en landt dus in
  fase 35 (CLUB-26); lang indrukken op een chip opent de groep.
- **Vraag 2: A.** ⋮ per lid voor beheerders; naam wijzigen, link vervangen, verlaten en opheffen in
  het appbar-menu. Een gewoon lid ziet geen ⋮ en alleen "Groep verlaten".
