---
phase: 34-groep-maken-en-beheren
plan: 02
status: complete
requirements: [CLUB-02, CLUB-03, CLUB-27]
completed: 2026-09-23
---

# 34-02 — Deny-tests voor aanvragen, en 0013 live

## Wat er gedaan is
- **Task 1** (`ee8154e`): nieuwe `supabase/tests/clubs_requests_deny_test.sql` (62 checks) en
  `clubs_deny_test.sql` bijgewerkt voor 0013 (81 → 83 checks: 2.5/2.6 omgedraaid, 3.1 → 3 links,
  nieuw 4.2b/4.2c). 0013 bleek bij het uitschrijven geen fout te bevatten.
- **Task 2** (checkpoint, Joost, 2026-09-23), in de SQL Editor op `hcdrydlgqpnmumfupgcx`:
  1. `0013_group_join_requests.sql` toegepast ("Run without RLS"; 0013 zet RLS zelf aan) —
     "Success. No rows returned".
  2. `clubs_requests_deny_test.sql`: **62/62 ok = true**, eerste poging.
  3. `clubs_deny_test.sql`: **83/83 ok = true**, eerste poging.
  Geen herstelrondes. Beide tests eindigen in rollback.

## Bewezen
- Een gewoon lid draagt voor maar maakt niemand lid, accepteert en wijst niet af (2.x).
- De link geeft een aanvraag, geen lidmaatschap; de aanvrager ziet alleen de groepsrij (3.x).
- Een beheerder accepteert, wijst af, en maakt een voorgedragen maatje direct lid (4.x).
- Grenzen bij accepteren: `group_full`, `too_many_groups`, `too_many_requests` (5.x).
- Intrekken en opheffen ruimen aanvragen op (6.x).
- Alles uit fase 33 geldt nog, met de bewuste wijzigingen van 0013 (83/83).
