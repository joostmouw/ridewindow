# Phase 20: Repository refactor (local-only) - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Profiel, beschikbaarheid en geplande ritten verhuizen achter drie gedeelde repositories, met **nul zichtbare gedragsverandering** en **nul cloud-betrokkenheid**. De drie plekken die vandaag hun eigen kopie van dezelfde SharedPreferences-sleutels bijhouden worden er één, en de velden die fase 21 nodig heeft (`updatedAt`) worden alvast geschreven — maar nergens gelezen om iets te beslissen.

Levert: `ProfileRepository`, `AvailabilityRepository`, `PlannedRidesRepository` (plain Dart, geen Riverpod erin), afgeslankte notifiers die er doorheen praten, een `background_task.dart` zonder gespiegelde sleutelconstanten en zonder Supabase, en een async `PlannedRidesNotifier` die op `authStateProvider` reageert.

Expliciet NIET in deze fase: elke cloud-read of -write, de outbox, het Postgres-schema, RLS, de migratie-/conflictresolver, `lastSyncedUid` als volwaardig eigendomsveld, en elke gedragsverandering die een gebruiker kan zien. Als een gebruiker iets merkt van deze fase, is er iets misgegaan.

**De leidraad die alle beslissingen hieronder verbindt: dit is een verhuizing, geen verbouwing.** Alles wat verleidelijk is om "meteen even mee te nemen" hoort in een eigen klus.

</domain>

<decisions>
## Implementation Decisions

### Sleutels en dataformaat (nul migratie)

- **D-01:** **Alle bestaande prefs-sleutels en hun dataformaten blijven letterlijk ongewijzigd.** De sleutelstrings verhuizen naar de repositories als enige bron van waarheid, maar de strings zelf, de typen en de serialisatie veranderen niet. Er is dus **geen migratiestap** en bestaande installaties merken niets.
- **D-02:** Reden om níet te normaliseren tijdens de verhuizing: code verplaatsen en dataformaat wijzigen tegelijk maakt een fout onvindbaar — je weet dan niet welke van de twee hem veroorzaakte. Dit is bovendien exact de pijplijn die op 2026-07-25 al eens gerepareerd moest worden (quick task `260725-knl`, canonieke uur-sleutel + migratie). Opschonen mag later als een eigen, apart afgebakende klus.
- **D-03:** **Let op de telling in het onderzoek.** `ARCHITECTURE.md` §2 zegt "11 distinct keys" voor profiel en somt er vervolgens 12 op. De code heeft er **12** (`profile.tempMinIdealC`, `.tempMaxIdealC`, `.windMaxIdealKmh`, `.rainMaxIdealMm`, `.allowedDurations`, `.theme`, `.locationOverride`, `.userName`, `.locale`, `.notifEveningBefore`, `.notifMorningOf`, `.notifWeeklyDigest`), plus `availability.blockedHours` en `planned_rides` = **14 sleutels in totaal**. Tel ze bij het uitvoeren zelf na in `profile_notifier.dart:77-88`; vertrouw het onderzoeksgetal niet.
- **D-04:** Nieuwe velden zijn strikt additief en nullable, met een default die een bestaande installatie zonder dat veld normaal laat werken. Geen enkele bestaande sleutel wordt gelezen-en-herschreven "om hem gelijk te trekken".

### `updatedAt` — waar en wanneer gestempeld

- **D-05:** **Eén `updatedAt` per domein**, niet per veld: `profile.updatedAt`, `availability.updatedAt`, `planned_rides.updatedAt`. Epoch-ms int, hetzelfde patroon als het bestaande `weather.lastRefreshed` in `background_task.dart:31`. Per-veld tijdstempels zijn pas nodig als fase 21 per-veld zou willen mergen, en dat is niet het plan (MIG-03 laat de gebruiker kiezen bij een echte divergentie).
- **D-06:** Het stempelen gebeurt **in de repository's schrijfpad, niet in de notifiers**. Eén plek die de tijd zet; een notifier kan het niet vergeten. Dat is het hele punt van de seam.
- **D-07:** **De automatische invulling van `profile.userName` bij inloggen stempelt `updatedAt` NIET.** Dit is de vraag die fase 19 expliciet doorschoof (`19-CONTEXT.md` D-04). Reden: die schrijfactie komt van de app, niet van de gebruiker. Zou hij wel meetellen, dan ziet fase 21 elk eerste inloggen op een nieuw toestel als "hier is net iets gewijzigd" en krijgt de gebruiker een conflictdialoog terwijl er niets aan de hand is. Het schrijfpad heeft dus een manier nodig om te schrijven zónder te stempelen — hoe dat eruitziet (named parameter, aparte methode) is aan de planner.
- **D-08:** Een ontbrekende `updatedAt` op een bestaande installatie blijft ontbrekend — hij wordt **niet** retroactief op "nu" gezet. Anders lijkt elke bestaande installatie na de update alsof er zojuist iets gewijzigd is. Wat "ontbrekend" betekent bij een conflict is een beslissing voor fase 21; fase 20 schrijft alleen en leest het veld nergens om iets te beslissen.

### `PlannedRidesNotifier` van synchroon naar async

- **D-09:** De notifier wordt async en gaat `authStateProvider` watchen, maar **de prefs blijven vooraf ingeladen** (zoals nu via `sharedPrefsProvider`), zodat de eerste read in de praktijk binnen hetzelfde frame klaar is. De async-vorm is er voor fase 21; hij mag vandaag geen echte wachttijd introduceren.
- **D-10:** **Tijdens een herlaad blijft de vorige lijst staan.** Geen skeleton, geen lege staat, geen spinner op Home. De bestaande lege staat is alleen voor "er zijn echt geen geplande ritten" — een laadmoment mag daar nooit op lijken. Succescriterium 1 ("geen zichtbare gedragsverandering") sneuvelt op precies zo'n flits.
- **D-11:** Reageren op `authStateProvider` betekent in deze fase **uitsluitend opnieuw lokaal lezen**. Geen cloud-read, ook niet "vast even voorbereidend". De wisselflow van fase 19 (D-08/D-09) blijft leidend voor wat er bij een accountwissel gewist wordt.

### Bewijs dat er niets veranderde

- **D-12:** De volledige suite groen houden (stand bij aanvang: **317/0**) is de **ondergrens, niet het bewijs**. De suite draait op verse, lege prefs — precies de conditie waarin een dataregressie zich niet laat zien.
- **D-13:** Daarbovenop een **handmatige toestelcheck op een installatie met bestaande data**: profielinstellingen (tolerantie-sliders, thema, naam, notificatievoorkeuren), het beschikbaarheidsraster en de geplande ritten — kijken of ze er ná de refactor nog net zo staan als ervoor. Twee minuten werk, en het is de enige check die het faalpatroon van juli zou hebben gevangen.
- **D-14:** REG-05 krijgt een **automatiseerbaar** bewijs naast de gedragscheck: een assertie dat `lib/platform/background_task.dart` en zijn importgraaf nergens `supabase` bevatten. "De isolate heeft geen Supabase-afhankelijkheid" hoort een test te zijn, geen belofte in een commit-bericht.

### Claude's Discretie

- Bestandsindeling en klassenamen onder `lib/data/repositories/`, en of de repositories via `@riverpod`-providers of direct in de notifiers worden geconstrueerd.
- De precieze vorm van "schrijf zonder te stempelen" (D-07).
- Hoe `PlannedRide`-serialisatie en de bestaande backwards-compat-tak (`time` → `start`/`end` in `planned_rides_notifier.dart:36-44`) mee verhuizen — die tak blijft, hij is nog steeds nodig.
- De plan-indeling: hoeveel plannen, in welke volgorde, en of de drie domeinen los of samen gaan.
- Hoe de vorige-waarde-tijdens-herladen uit D-10 technisch wordt gehaald.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope en requirements
- `.planning/ROADMAP.md` §"Phase 20: Repository refactor (local-only)" — doel en de vier succescriteria. Criterium 1 (geen zichtbare verandering voor een uitgelogde gebruiker) en criterium 4 (suite + `flutter build apk --release` groen, nul cloud-aanroepen) zijn de harde gates.
- `.planning/REQUIREMENTS.md` — **REG-05** is het enige requirement van deze fase; lees ook de noot onder "Traceability" waarom REG-05 juist hier landt en niet in fase 19.
- `.planning/milestones/v3.0-ACCOUNTS.md` — milestone-scope.

### Ontwerp (lees §2 volledig — het is de blauwdruk van deze fase)
- `.planning/research/ARCHITECTURE.md` **§2 "Repository seam"** — de geverifieerde huidige call-sites per bestand, en de aanbeveling: één repository per domein met een optionele cloud-sink geïnjecteerd, géén twee parallelle implementaties. **Let op D-03 hierboven: de sleuteltelling in §2 klopt niet.** **§5** — waarom `updatedAt` er moet komen (MIG-04) en dat geen enkele notifier vandaag een wijzigingstijd bijhoudt. **§6** — de expliciete lijst nieuwe/gewijzigde bestanden. **§7 stap 4** — deze fase in de bouwvolgorde, met de nadruk `cloud: null` overal.
- `.planning/research/PITFALLS.md` **#10** — regressierisico van een cloud-SDK op een live app; hier relevant omdat deze fase de isolate aanraakt.
- `.planning/research/archive-firebase/` — **verouderd. Niet uit plannen.**

### Fase 19 (deze fase erft er open eindjes van)
- `.planning/phases/19-auth/19-CONTEXT.md` — **D-04** (de naam-autofill die hier zijn antwoord krijgt, zie D-07), **D-08/D-09** (uid-vergelijking en wat "opnieuw beginnen" wist), **D-12** (uitloggen raakt lokale data niet).
- `.planning/phases/19-auth/REGRESSION-CHECKLIST.md` — het handmatige-verificatiepatroon dat D-13 hergebruikt.

### Code die deze fase raakt
- `lib/providers/profile_notifier.dart:77-88` — de 12 sleutelconstanten; `build()` + 8 losse mutators die elk zelf `SharedPreferences.getInstance()` doen.
- `lib/providers/availability_notifier.dart:23,28,132` — één sleutel (`availability.blockedHours`), formaat `"<ISO8601>|<blocktype>"`, en het enige `_persist()` waar alle 5 mutators al doorheen gaan. Van de drie het dichtst bij de gewenste vorm.
- `lib/providers/planned_rides_notifier.dart` — synchrone `build()`, `_kPrefsKey = 'planned_rides'`, JSON-blob, en de backwards-compat-tak voor het oude `time`-formaat. Gebruikt al `ref.read(sharedPrefsProvider)` in plaats van `getInstance()` — een bestaande inconsistentie die de refactor opheft.
- `lib/platform/background_task.dart:31-41,144` — de derde, onafhankelijke kopie van de sleutelstrings, mét comment die de spiegeling toegeeft. Draait in de WorkManager-isolate: **geen Riverpod**, krijgt een `SharedPreferences`-instantie direct. Schrijft alleen `weather.lastRefreshed`.
- `lib/domain/services/availability_key.dart` — de canonieke uur-sleutel uit de fix van 2026-07-25; het formaat waar D-01 vanaf blijft.

</canonical_refs>

<code_context>
## Existing Code Insights

### Herbruikbare onderdelen
- **`AvailabilityNotifier._persist()`** — alle mutators lopen er al doorheen. Dit domein is bijna al een repository; het is het goedkoopste startpunt en het model voor de andere twee.
- **`sharedPrefsProvider`** (in `lib/app/router.dart`) — de app-brede, vooraf ingeladen prefs-instantie. Dit is wat D-09 mogelijk maakt zonder echte wachttijd.
- **`weather.lastRefreshed`** (`background_task.dart:31`) — het bestaande epoch-ms-tijdstempelpatroon dat `updatedAt` in D-05 volgt.
- **Provider-override in tests** — het bestaande recept uit de fase-19-tests werkt onveranderd voor repository-providers.

### Gevestigde patronen
- **Riverpod codegen** (`@riverpod` + `.g.dart` via `build_runner`) voor elke provider; `keepAlive: true` waar state de hele sessie moet blijven.
- **Plain Dart voor alles wat de isolate moet kunnen gebruiken** — geen Riverpod, geen `BuildContext` in de repositories, anders is REG-05 niet haalbaar.
- **EN/NL l10n** voor gebruikerszichtbare tekst — deze fase hoort er geen enkele toe te voegen.
- **Nederlandse commentaren en commitberichten.**

### Integratiepunten
- `lib/data/repositories/` — nieuw; bestaat nog niet.
- De drie notifiers worden dun: `build()` roept `readLocal()`, elke mutator wordt `await repository.save(next)`.
- `background_task.dart` verliest zijn sleutelconstanten en roept `readLocal()` aan — een strikte vereenvoudiging van dat bestand, geen uitbreiding.
- **Geen enkel build- of deploycommando verandert in deze fase**, net als in fase 19 (`19-CONTEXT.md` D-14).

</code_context>

<specifics>
## Specific Ideas

- **"Verhuizing, geen verbouwing"** is de zin waar de gebruiker op akkoord ging en waar D-01 t/m D-04 uit volgen. Als een downstream-agent tijdens de refactor iets aantreft dat "beter kan": noteer het als deferred idea, verander het niet.
- De gebruiker vroeg om een aanbeveling in plaats van een keuzelijst en volgde die integraal — dezelfde staande voorkeur als in fase 18 en 19: **"zo gratis en makkelijk mogelijk", de optie met de minste bewegende delen**, en het hardop zeggen als de goedkopere optie een echt risico draagt.
- **Volgorde-advies dat bij deze context hoort:** fase 19's plan 19-07 (Play Store-installatie + regressiechecklist) staat op het moment van schrijven nog open. Fase 20 verbouwt precies de code die 19-07 moet bewijzen. Plan en voer fase 20 pas uit als 19-07 groen is — anders wordt een eventuele inlogfout gezocht bovenop een verse refactor.

</specifics>

<deferred>
## Deferred Ideas

- **Sleutels en formaten normaliseren** (bijv. profiel's 12 losse sleutels naar één JSON-blob) — bewust niet in deze fase, zie D-01/D-02. Eigen klus, met eigen migratie en eigen toestelverificatie.
- **Beschikbaarheid naar de bestaande Drift-tabel** in plaats van SharedPreferences — dezelfde redenering; de Drift-tabel `AvailabilityGridEntries` bestaat maar wordt niet gebruikt (`STATE.md`, beslissing 03-03).
- **De outbox, cloud-reads/-writes, Postgres-schema, RLS, conflictresolver** — fase 21. De repositories krijgen in fase 20 wel de vorm (optionele cloud-sink), maar hij blijft overal `null`.
- **`lastSyncedUid` als volwaardig eigendomsveld** — fase 19 slaat een uid op om een wissel te herkennen; de echte MIG-04-semantiek is fase 21.
- **Per-veld tijdstempels of echte veldniveau-merge** — niet gepland, zie D-05.

</deferred>

---

*Phase: 20-repository-refactor-local-only*
*Context gathered: 2026-07-26*
