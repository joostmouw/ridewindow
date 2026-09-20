---
phase: 27-wervingsonderzoek
plan: 02
subsystem: docs
tags: [recruitment, wervingsonderzoek, testers, reddit, copywriting]

# Dependency graph
requires:
  - phase: 27-wervingsonderzoek (plan 01)
    provides: De gekozen kanaalmix (D-12) en de rekensom 2 + 8 + 5 = 15 uit 27-KANALEN.md
provides:
  - Drie verzendklare teksten (WERV-02) in 27-TEKSTEN.md: eigen-kring opt-in-instructie (NL), fiets-Facebookgroep (NL), r/AndroidClosedTesting (EN, achtervang)
  - Verse regelcontrole r/AndroidClosedTesting (D-08): geen zelfpromotieregel gevonden, Regel 1-risico opgelost, zeven uit de feed afgelezen gebruiken
  - HTML-preview getoond vóór de goedkeuringsvraag (D-05); Joost's goedkeuring vastgelegd
  - Actuele promotie-screenshot docs/promo/home-1.0.35.jpg (1.0.35+46)
affects: [30-werving]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/27-wervingsonderzoek/27-TEKSTEN.md
    - .planning/phases/27-wervingsonderzoek/27-preview.html
    - docs/promo/home-1.0.35.jpg
  modified:
    - .planning/TESTERS.md

key-decisions:
  - "Geen zelfpromotieregel gevonden bij r/AndroidClosedTesting, vastgelegd als 'niet gevonden bij handmatige controle op 2026-09-20', niet als 'toegestaan'; bij verzending in fase 30 opnieuw verifiëren (D-08)"
  - "Regel 2 van de subreddit bindt de tekst direct: geen enkele andere subreddit noemen of hinten, in geen enkele vorm"
  - "De Reddit-tekst leidt met wat de app is, niet met het ruilaanbod: pure-T4T-openers krijgen in dezelfde feed zichtbaar veel downvotes (20+)"
  - "Elke post draagt een afbeelding (deviatie op verzoek van Joost): docs/promo/home-1.0.35.jpg, vastgelegd op de huidige build, zodat de 'ververs vlak voor verzending'-kanttekening vervalt"

requirements-completed: [WERV-02]

# Metrics
duration: ~2,5u over twee sessies (inclusief drie checkpoint-wachtrondes)
completed: 2026-09-20
---

# Phase 27 Plan 2: Verzendklare teksten Summary

**Drie verzendklare wervingsteksten in D-12's prioriteitsvolgorde (eigen kring, fiets-Facebookgroep, r/AndroidClosedTesting-achtervang), met een vers geverifieerde Reddit-regelcontrole, als HTML getoond vóór de goedkeuringsvraag, en door Joost goedgekeurd na drie correctierondes.**

## Performance

- **Duration:** ~2,5 uur over twee sessies (de eerste sessie viel weg vóór de afronding; deze SUMMARY en de tracking komen uit de vervolgsessie)
- **Started:** 2026-09-20T11:20:00Z
- **Completed:** 2026-09-20T13:38:40Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Regelcontrole r/AndroidClosedTesting vers uitgevoerd (D-08), niet overgenomen uit 27-RESEARCH.md. WebFetch en de browser-extensie werden geweigerd, dus Joost plakte zelf de regels: geen zelfpromotieregel gevonden (vastgelegd als "niet gevonden", niet als "toegestaan"). Een tweede controleronde met ~20 feedposts loste het Regel 1-risico op ("Lid geworden" + actieve "Post maken"-knop) en leverde zeven gebruiken: wederkerigheid is de norm, links horen als genummerde 3-stappenlijst in de posttekst, de 14 dagen worden altijd expliciet genoemd, nooit om een publiek e-mailadres vragen, geen review-ruil, en niet openen met het ruilaanbod
- `27-TEKSTEN.md` met drie teksten in D-12's volgorde, elk met alle vijf de ingrediënten (veertien dagen, regelmatig openen, het waarom, terugkoppel-belofte, eerste-minuut-waarschuwing); de eigen-kring-tekst noemt de drie opt-in-stappen letterlijk (D-10) en stelt dat installeren een aparte, latere stap is
- Alle drie de links echt ingevuld (groep, opt-in, installeren); de Google Group bleek al te bestaan
- Preview gebouwd uit het tekstenbestand en drie keer heropend na correctierondes van Joost (echte groepslink, em-dashes uit de verzendcopy, verse screenshot); daarna goedgekeurd
- Verse promotie-screenshot `docs/promo/home-1.0.35.jpg` (1.0.35+46, 2026-09-20 14:32) met Vensters/Blok-schakelaar, Beste eerst/Op tijd (#69/#70), dagstrip, geplande rit en "100 Toprit"-kaart; de "ververs vlak voor verzending"-kanttekening is vervallen
- De rekensom in `TESTERS.md` rechtgezet naar de Console-stand van 2026-09-20 (2 aangemeld van 10 bereikbaar; 2 + 8 + 5 = 15) — zie deviatie 3

## Task Commits

Each task was committed atomically:

1. **Task 1: Verse regelcontrole r/AndroidClosedTesting (D-08)** - vastgelegd in 27-TEKSTEN.md via `23b7ec2` (eerste ronde) en `2e8b4de` (tweede ronde: feed-bewijs, Regel 1 opgelost)
2. **Task 2: Drie verzendklare teksten (WERV-02, D-06/D-07/D-10)** - `23b7ec2` (drie teksten), `6c40c15` (echte Play-links), `fc34968` (groep bleek te bestaan, echte link), `477d549` (em-dashes uit de verzendcopy)
3. **Task 3: HTML-preview en goedkeuring (D-05)** - `cd3beab` (preview gebouwd en geopend), `6d8db84` en `e7b05db` (heropend na correctierondes), `9e2cc2b` + `e460a08` (verse screenshot), `8a5341a` (preview gelijkgetrokken met de teksten, heropend)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified
- `.planning/phases/27-wervingsonderzoek/27-TEKSTEN.md` - de drie verzendklare teksten, de herkomst van de regelcontrole, de afbeelding-instructies en het controlepunt vóór verzending
- `.planning/phases/27-wervingsonderzoek/27-preview.html` - HTML-preview gegenereerd uit het tekstenbestand; laatste regeneratie wijst naar de verse screenshot
- `docs/promo/home-1.0.35.jpg` - promotie-screenshot van de huidige build (aangemaakt in `9e2cc2b`)
- `.planning/TESTERS.md` - stand-kop en rekensom gecorrigeerd (buiten `files_modified`, zie deviatie 3)

## Decisions Made

Geen nieuwe productbeslissingen; het plan voerde D-05 t/m D-13 uit. Wel vastgelegd tijdens de uitvoering:

- "Geen zelfpromotieregel gevonden" is vastgelegd als een negatief resultaat van een handmatige controle, niet als toestemming. Wie de tekst in fase 30 verstuurt, verifieert op dat moment opnieuw (D-08).
- De Reddit-tekst opent met wat de app is en niet met het ruilaanbod; de feed liet zien dat pure-T4T-openers 20+ downvotes krijgen.
- Elke post krijgt een afbeelding (verzoek van Joost tijdens de uitvoering): `docs/promo/home-1.0.35.jpg`.

## Deviations from Plan

1. **Afbeelding bij elke post.** Stond niet in het plan; op verzoek van Joost tijdens het Task 1-checkpoint aan alle drie de secties toegevoegd, en vastgelegd als deviatie in 27-TEKSTEN.md zelf.
2. **De Google Group bleek al te bestaan.** Het plan ging er impliciet van uit dat die nog gemaakt moest worden (fase 26 plan 03). De echte link is direct ingevuld, met een controlepunt vóór verzending: groep gekoppeld in Play Console én de negen bestaande adressen geïmporteerd.
3. **`TESTERS.md` aangepast hoewel het niet in `files_modified` staat.** De rekensom daar (7 extern, ~12-16 van buiten, pool ~20-25) was de enige plek waar de verouderde stand nog als maatgevend werd gepresenteerd, terwijl 27-CONTEXT.md (D-13) het bestand op dit punt expliciet verouderd noemt. Gecorrigeerd naar de Console-stand van 2026-09-20; de oude tabel blijft staan als gedateerde tussenstand.
4. **De afronding gebeurde in een vervolgsessie.** De executorsessie viel weg na de laatste inhoudelijke commit; deze SUMMARY, de tracking en de laatste preview-regeneratie komen uit de sessie waarin Joost zijn goedkeuring ook formeel gaf.

## Issues Encountered

- **Reddit onbereikbaar vanuit de omgeving** ("unable to fetch" via WebFetch, "not allowed" via de browser-extensie). Uitgevallen op de human_action-route die het plan hiervoor had; Joost plakte de regels en later ~20 feedposts zelf.
- **Regel 1 las aanvankelijk als een mogelijke ban** ("You are no longer able to participate in this community"). De tweede controleronde toonde dat het een regeltitel is, geen banbanner. Risico vervallen.
- **Em-dashes in de verzendcopy.** De projectregel (structuurtest op de ARB's en `lib/`) gold nog niet voor teksten die de deur uitgaan; na een correctieronde van Joost zijn alle em-dashes verwijderd.

## User Setup Required

Geen voor dit plan. Voor fase 30 staat in 27-TEKSTEN.md een controlepunt vóór verzending (groep gekoppeld in Play Console onder Closed testing > Alpha > Testers; de negen bestaande adressen als lid toegevoegd) en geldt de D-08-afspraak om de Reddit-regels bij verzending opnieuw te verifiëren. De groepsinstellingen (wie mag zien/lid worden) heeft Joost op 2026-09-20 nagelopen bij het openen van de groep.

## Next Phase Readiness

Fase 27 is hiermee af (WERV-01 en WERV-02 compleet; alle drie de fase-success-criteria behaald). Fase 30 (WERV-03/04/05) heeft alles liggen: drie teksten, echte links, een actueel plaatje en een controlepunt. De eigen-kring-tekst gaat als eerste uit (D-12's prioriteit 1); de Reddit-tekst is geschreven en wordt vastgehouden tot de drempel (eigen kring + Facebookgroep na een week samen onder de vijftien aangemelde testers) hem activeert.

**Goedkeuring (success criterion 3):** Joost heeft de preview in zijn uiteindelijke vorm gezien (heropend op 2026-09-20 na de regeneratie met de verse screenshot) en antwoordde "Goedgekeurd, rond 27-02 af".

---
*Phase: 27-wervingsonderzoek*
*Completed: 2026-09-20*

## Self-Check: PASSED

- FOUND: `.planning/phases/27-wervingsonderzoek/27-TEKSTEN.md` met drie `## `-secties in D-12's volgorde
- FOUND: `.planning/phases/27-wervingsonderzoek/27-preview.html`, verwijst naar `docs/promo/home-1.0.35.jpg`
- FOUND: `docs/promo/home-1.0.35.jpg`
- FOUND: goedkeuring vastgelegd (hierboven, Next Phase Readiness)
- FOUND: commit `23b7ec2` t/m `8a5341a`
