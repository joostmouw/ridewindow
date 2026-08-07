---
id: 260807-gpz
slug: fase-21-doc-afronding
date: 2026-08-07
type: quick
status: complete
commits:
  - 0feee48
  - fe9f13a
  - ca91cb8
---

# Fase 21 — documentatie bijgewerkt na de drie antwoorden van 2026-08-07

## Wat er is gebeurd

Joost heeft de twee waarnemingen gedaan die ik op geen enkele omgeving kon forceren, en het
openstaande §3-besluit genomen. Alle drie de uitkomsten zijn gunstig; de documentatie is
bijgetrokken.

| Vraag | Uitkomst | Gevolg |
|---|---|---|
| Desktop-tabblad: twee ritten? | Ja, beide zichtbaar | SYNC-11 **PASS** |
| Telefoon na echte tabwissel? | Augustusrit verschijnt | SYNC-04 webkant **PASS** |
| §3 zonder iPhone? | iOS naar v2 | §3 herschreven naar Android-WebAPK |

## Commits

1. **`0feee48`** — `MANUAL-VERIFICATION-21.md`: nieuwe sessiesectie met beide PASSes, plus de
   expliciete intrekking van mijn eerdere bugvermoeden.
2. **`fe9f13a`** — `REGRESSION-CHECKLIST-21.md`: §3 herschreven, §5 afgevinkt, iPhone-verwijzingen
   in §4 en §6 vervangen.
3. **`ca91cb8`** — `MORGEN.md`: teruggebracht tot de zes stappen die nog een toestel nodig hebben.

## De inhoudelijke correctie

De web-diagnose van 2026-08-06/07 sloot correct zeven kandidaten uit en vond correct het verschil
(een oude offsetloze rit in `flutter.planned_rides` op de telefoon). Maar waar ze naartoe neigde —
een mogelijke bug in de voorgrond-reconcile — was fout. De telefoon had in die hele sessie nooit
een voorgrond-overgang gemaakt: de CDP-screenshot activeerde het tabblad niet, `visibilityState`
bleef `hidden`. De stale julirit was dus geen kapotte reconcile maar een reconcile die nog niet
gelopen had.

Dat is binnen deze fase de derde bevinding die door de meetopstelling werd geproduceerd in plaats
van door de code. De les staat in het log: op web is een voorgrond-overgang niet van buitenaf af te
dwingen, en een conclusie over lifecycle-gedrag die niet op een echte vingerbeweging rust is een
vermoeden, geen waarneming.

## Wat dit níet afsluit

- Fase 21 blijft open. Vijf toestelstappen resteren (§2-uitlog, §3-installatie, §4-koudestart,
  §6-accountverwijdering, Play-installatie) — zie `MORGEN.md`.
- De iOS-PWA-installatie is **uitgesteld, niet afgetekend**. Hij hoort bij de iOS-scope van v2.
- SYNC-11's overschrijfrichting is niet los getoetst; dat beide ritten naast elkaar stonden in
  plaats van elkaar te vervangen, is het sterkste dat de waarneming daarover zegt.
