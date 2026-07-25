# Milestone-context: v3.0 Accounts & Sociaal

**Vastgelegd:** 2026-07-25
**Status:** klaar voor requirements + roadmap
**Achtergrond:** `.planning/milestones/v3.0-ACCOUNTS.md` (scope, risico's, volledige fasering)

Dit bestand bestaat zodat `/gsd-new-milestone` na een `/clear` verder kan zonder
dat de genomen beslissingen opnieuw besproken hoeven te worden.

---

## Vastgelegde beslissingen

### 1. Scope — fase 1 en 2

**In scope:**
- Accounts en cloud-sync van profiel en beschikbaarheid
- Feedback geven via het eigen account (vervangt de `mailto:`-route uit backlog #33)

**Bewust uitgesteld:** vrienden toevoegen, beschikbaarheid delen, ritten
uitnodigen/accepteren, server-side notificaties (fase 3 t/m 5).

**Waarom:** fase 1 is nuttig ongeacht wat erna komt — het lost de bestaande pijn
op (geen back-up, en web en Android als twee losse datasilo's). De sociale fasen
hebben een netwerkeffect nodig dat er nu niet is; die worden pas beoordeeld nadat
fase 1 en 2 draaien en er testerfeedback is.

### 2. Auth — alleen Google Sign-In

`google_sign_in` 7.2.0 zit al in de app voor de Calendar-koppeling, dus dit is de
kortste weg en er komt geen wachtwoordbeheer, e-mailverificatie of
wachtwoordherstel bij kijken.

**Bekende beperking:** wie geen Google-account wil gebruiken, kan niet meedoen.
Geaccepteerd voor deze milestone.

**Let op:** de bestaande Google-OAuth-configuratie heeft een gebruikerscap van
100 unieke gebruikers zolang de `calendar.events`-scope niet formeel door Google
geverifieerd is (zie backlog #31). Voor auth op zichzelf geldt die cap niet, maar
het is één en hetzelfde Cloud-project — bij het inrichten controleren.

### 3. Datamigratie bij eerste login — lokaal wint

De beschikbaarheid en instellingen op het toestel worden de bron en gaan naar de
cloud. Bij een leeg account is dat het enige juiste gedrag, en testers verliezen
niets van wat ze hebben ingevuld.

**Nog te ontwerpen:** wat er gebeurt bij een tweede login op een ander toestel dat
zelf ook lokale data heeft. "Lokaal wint" mag daar niet blind de cloud
overschrijven — dat is een apart ontwerppunt in de planfase, geen impliciete
consequentie.

---

## Harde poorten — geen scope, maar voorwaarden

### CLAUDE.md-constraints moeten herzien worden

Deze milestone doorbreekt drie constraints die expliciet in `CLAUDE.md` staan.
Ze moeten bewust aangepast worden vóór de eerste regel code, niet stilzwijgend
overtreden:

| Constraint | Wat er verandert |
|---|---|
| "No backend: pure client-side" | Vervalt. Firebase Auth + Firestore komen erbij. |
| "Budget: ~€25 eenmalig, geen doorlopende infrakosten" | Firebase Auth is gratis en Firestore heeft een royale gratis laag, maar de kosten zijn niet langer structureel nul. Herformuleren naar een expliciet plafond. |
| "Privacy: data verlaat het toestel niet, tenzij de gebruiker Calendar koppelt" | Vervalt. Locatiegegevens en agenda-afgeleide beschikbaarheid landen op een server. |

### Privacy policy moet herschreven vóór de eerste release met accounts

Zodra er persoonsgegevens op een server landen wordt Joost
verwerkingsverantwoordelijke voor locatiegegevens en agenda-afgeleide
beschikbaarheid. De policy op
https://joostmouw.github.io/ridewindow/privacy-policy.html moet dan juridisch
herschreven — dat is geen tekstuele aanpassing en het is een release-blocker,
geen nice-to-have.

---

## Technische uitgangssituatie

- Er is een Firebase-project voor hosting (https://my-project-joost.web.app,
  `firebase.json` in de repo)
- Auth en Firestore zijn **niet** geïntegreerd: geen `google-services.json`, geen
  `lib/firebase_options.dart`, geen firebase-packages in `pubspec.yaml`
- `google_sign_in` 7.2.0 is aanwezig
- Te syncen data staat nu in SharedPreferences (`availability.blockedHours`,
  `profile.*`, `planned_rides`) plus Drift voor de forecast-cache. Alleen het
  eerste hoort naar de cloud; de forecast-cache is afgeleide data.

## Opgaande backlog-items

- #41 Sociaal / groepsritten → fase 3 en 4, buiten deze milestone
- #43 Backend + user accounts → fase 1, in deze milestone
- #33 Feedback-formulier (`mailto:`) → wordt vervangen door fase 2

## Stand bij aanvang

v1.0 en v2.0 shipped. Versie 1.0.11+12 op het toestel, nog niet naar testers.
Testsuite 306/0.
