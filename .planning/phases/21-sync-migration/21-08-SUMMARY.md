---
phase: 21-sync-migration
plan: 08
subsystem: accounts
tags: [supabase, rpc, account-section, l10n, auth-09, manual-verification]

# Dependency graph
requires:
  - phase: 21-sync-migration
    provides: "21-02: de `delete_own_account()` plpgsql-functie en het `on delete cascade`-schema op profiles/availability/planned_rides, plus `on delete set null` op feedback"
  - phase: 21-sync-migration
    provides: "21-07: `_buildSignedInRow()` en het bestaande `_confirmAndSignOut()`-dialoogpatroon waar deze actie zich naast voegt"
provides:
  - "AccountSection._confirmAndDeleteAccount() — één AlertDialog met expliciete onomkeerbaarheidstekst (D-01), daarna rpc(kDeleteOwnAccountRpc) -> signOut() -> snackbar (D-02)"
  - "Destructief gestileerde 'Delete account'-TextButton onder de sign-out-rij"
  - "Zes ARB-sleutels in EN/NL: accountDeleteAction, accountDeleteConfirmTitle/Body/Action, accountDeletedSnackbar, accountDeleteError"
affects: [21-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "RPC vóór signOut, beide binnen dezelfde try: een mislukte serverkant mag zich nooit voordoen als een geslaagde verwijdering. signOut() staat ná de await en wordt dus niet bereikt als de RPC gooit."
    - "D-03 als negatieve invariant getest: `resetToDefaults()`/`clearAll()` blijven exclusief in de account-switch-tak ('start fresh') en komen niet voor in het verwijderpad. Die twee takken lijken op elkaar en hergebruik zou hier een D-03-schending zijn, geen gemak."

key-files:
  created: []
  modified:
    - lib/features/profile/account_section.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_nl.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_nl.dart
    - test/features/profile_account_section_test.dart
    - .planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md
    - .planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md

key-decisions:
  - "De succesvolle verwijderweg is niet in een widgettest gedekt maar op het toestel: `profile_account_section_test.dart` had geen seam om `Supabase.instance.client.rpc()` te vervangen, en daar zwaar SupabaseClient-mockwerk voor optuigen stond niet in verhouding. De widgettests dekken wat door de widgetboom waarneembaar is (dialoogtekst, Annuleren doet niets, foutpad toont de foutsnackbar en géén succes-snackbar); het succespad is end-to-end bewezen in device session 9."
  - "Verificatie van de cloud-kant getoetst als **nul weesrijen** in plaats van 'nul rijen in de tabel'. De tabellen bevatten rijen van andere accounts (3/3/2), dus een telling per tabel had niets bewezen. Weesrijen dekken twee claims tegelijk: de cascade heeft niets laten liggen, én er is niets teruggeduwd door een nog-ingelogde client."

requirements-completed: [AUTH-09]

# Metrics
duration: "code 2026-08-04 (~1u); verificatie 2026-09-01 (~15 min)"
completed: 2026-09-01
---

# Phase 21 Plan 08: Delete account (AUTH-09) Summary

**De destructieve accountverwijdering is gebouwd (`139a4f8`, 2026-08-04) en op 2026-09-01 end-to-end geverifieerd tegen het echte Supabase-project — de stap waar dit plan sinds augustus op openstond.**

## Wat er gebouwd is

Een "Delete account"-actie in de ingelogde accountrij, destructief gestileerd en visueel te onderscheiden van de sign-out ernaast. Bij bevestiging: `delete_own_account()` via RPC, dan `signOut()`, dan een snackbar. De volgorde is het hele punt — `signOut()` staat binnen dezelfde `try` ná de geawaite RPC, dus een mislukte serververwijdering logt de gebruiker niet uit en meldt geen succes.

## Verificatie — device session 9, 2026-09-01

Uitgevoerd op de **PWA 1.0.23+24** via `adb`, bewust niet op de native app: die stond op dit toestel nog op 1.0.21+22, terwijl de PWA de code draait die ook in de AAB zit.

| Eis | Uitkomst |
|---|---|
| D-01 — één dialoog, expliciet onomkeerbaar, Cancel/Delete | **PASS** |
| D-02 — automatische uitlog, snackbar, normale signed-out weergave | **PASS** — "Account deleted" |
| D-03 — lokale data onaangeroerd | **PASS**, op drie schermen gecontroleerd tegen een "voor"-opname |
| Cloud-rijen weg | **PASS** — nul weesrijen in `profiles`/`availability`/`planned_rides` |
| `auth.users` | **PASS** — nul rijen voor het verwijderde account |

D-03 is bewust op drie schermen getoetst en niet op één, want dat is de garantie die nooit mag breken: notificatie-instellingen ongewijzigd, beschikbaarheidsrooster identiek tot en met de blauwe planmarkeringen, en beide geplande ritten nog in "My Rides".

## Wat níét bewezen is

**`on delete set null` op `feedback.user_id`.** Die tabel bevat nul rijen — er is nooit testfeedback onder dit account ingestuurd, dus er viel niets te observeren. De invariant is alleen door het schema gedekt. Wie dit wil sluiten: stuur feedback in onder een account en verwijder dat account. Dit is als vervallen genoteerd in `REGRESSION-CHECKLIST-21.md`, niet als vinkje.

## Nevenwaarneming

De native app hield tijdens de meting nog een geldige sessie voor het net verwijderde account. Hij is `force-stop`'t gehouden zodat een outbox-push de meting niet kon vervuilen. Dat nul weesrijen daarna nog steeds gold, is meteen het bewijs dat er niets is teruggeduwd.
