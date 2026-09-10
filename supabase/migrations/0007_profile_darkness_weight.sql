-- 0007 — daglicht als vijfde tolerantie op het profiel.
--
-- Aanleiding: backlog #68. De app hield geen rekening met daglicht en zette
-- daardoor een venster van 20:00-22:00 op score 100 terwijl de zon om 20:07
-- onderging (gemeld door een tester op 2026-09-09). De score krijgt nu een
-- aftrek naar rato van het donkere deel van het venster, en hoe zwaar die
-- aftrek weegt stelt de gebruiker zelf in.
--
-- Anders dan de vier bestaande tolerantiekolommen is dit geen grens maar een
-- gewicht: 0,0 betekent "donker maakt me niets uit", 1,0 betekent "alleen bij
-- daglicht". Vandaar het bereik 0-1 in plaats van een eenheid.
--
-- Additief en met een default, zodat bestaande rijen geldig blijven en een
-- oudere app-versie die de kolom niet meestuurt gewoon blijft werken.

alter table public.profiles
  add column if not exists darkness_weight double precision
    not null default 0.5;

comment on column public.profiles.darkness_weight is
  'Hoe zwaar donker meetelt in de ritscore: 0 = niet, 1 = maximaal. Zie lib/domain/services/daylight.dart.';
