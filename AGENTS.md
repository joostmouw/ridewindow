# Ridewindow — instructies voor coding agents

Dit bestand is de ingang voor elke agent die hier werkt: Claude Code, Factory
Droid, of wat er verder langskomt. Het bestaat omdat Droid `AGENTS.md` leest en
`CLAUDE.md` niet, terwijl beide agents op dezelfde codebase werken.

**`CLAUDE.md` is de bron van waarheid** voor productbeslissingen, de tech-stack
en de constraints. Lees dat bestand voordat je iets ontwerpt. Wat hieronder
staat is wat je nodig hebt om niets stuk te maken.

## Wat de app is

Een Android-app (Flutter) voor fietsers die willen weten wanneer deze week het
beste moment is om te rijden. Hij combineert een fietsspecifieke weerscore met
je beschikbaarheid en levert concrete vensters op: "zaterdag 09:00-13:00, 4u,
Toprit".

De kernwaarde is de score en het venster. Als de score fout is, of het venster
in de praktijk onrijdbaar, faalt de app en is de rest decoratie. Behandel de
scoringsmotor en de slot-generatie daarom als het zwaarste onderdeel van de
repo, niet als bijzaak.

## Commando's

```bash
flutter pub get

# Code-gen (freezed, json_serializable, riverpod, drift)
dart run build_runner build --delete-conflicting-outputs

# Vertalingen (lib/l10n/app_nl.arb is de template, en is leidend)
flutter gen-l10n

flutter analyze          # moet schoon zijn, nul waarschuwingen
flutter test             # draai dit na elke inhoudelijke wijziging

# Builds
flutter build apk --release          # voor de Oppo
flutter build appbundle --release    # voor Play
flutter build web --release

# Web live zetten (bouwt zelf, en verifieert de hash van de live bundel)
scripts/deploy_web.sh

# Naar Play (internal track); inrichting staat in tool/README-play-release.md
dart run tool/play_upload.dart --track internal \
  --notes en-US:release-notes/en-US.txt \
  --notes nl-NL:release-notes/nl-NL.txt
```

De hele weg naar de testers (lokale APK, PWA, internal, closed) staat in
`docs/RELEASE-ROUTE.md`. Kort: alles via internal, de PWA op hetzelfde
releasemoment, en pas na toestelgoedkeuring promoveren naar alpha.

`adb` staat niet op `PATH`:

```bash
~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
```

De testtelefoon is een Oppo. Aanraakgedrag en scrollen verifieer je daar, niet
in Chrome. Let op: de **release**-APK werkt met Google-login, de debug-build
niet — testen met een account doe je dus op een release-build. Na
`flutter build web` moet de browser hard verversen (Cmd+Shift+R), anders kijk
je naar de oude bundel.

## Regels die je echt moet kennen

**De versie staat op twee plekken.** `pubspec.yaml` (`version:`) en
`lib/core/app_version.dart` (`kAppVersionName` + `kAppBuildNumber`). Bump ze
samen. `test/core/app_version_test.dart` faalt als ze uit de pas lopen; dat is
opzet, geen bug.

**Geen em-dashes in de app.** `test/structure/no_em_dash_test.dart` bewaakt
zowel de ARB's als de letterlijke teksten in `lib/`. Gebruik een dubbele punt
of een gewoon koppelteken. En-dashes in bereiken (`09:00-13:00`) mogen wel.

**Beide talen, altijd.** Nieuwe tekst gaat in `app_nl.arb` én `app_en.arb`. Een
sleutel die maar in één bestand staat, is een halve feature.

**Nederlands in commits en codecommentaar.** Kijk naar `git log` voor de toon:
`fix(69): "Longest ride here" zei bijna altijd 2 uur, en dat was een artefact`.
Een commit vertelt wat er mis was en waarom de fix klopt, niet welke bestanden
zijn aangeraakt.

**Commentaar legt uit waarom, niet wat.** Deze codebase doet dat consequent.
Een comment die de regel eronder herhaalt, hoort er niet.

## Grenzen die niet mogen schuiven

Deze staan uitgebreid in `CLAUDE.md`; overtreed ze niet zonder dat Joost er
expliciet ja op zegt.

- **EUR 0/maand vanaf v3.0.** Open-Meteo, Firebase Hosting free tier, Supabase
  free tier. Een dienst toevoegen die geld kost is een productbeslissing.
- **Geen server-side code behalve `plpgsql`-functies.** Zes vandaag, elk
  verantwoord in de migratie die hem toevoegt. Geen Edge Functions.
- **Privacy.** Uitgelogd verlaat er niets het toestel. Gebruiksstatistiek gaat
  alleen mee na een expliciete ja, gevraagd bij de tweede start. Een
  gebeurtenis draagt nooit een locatie, nooit vrije tekst, nooit een
  e-mailadres.
- **Lokaal blijft de bron van waarheid** op het toestel (Drift /
  SharedPreferences). Supabase is additief; de app werkt volledig uitgelogd.

## Werkwijze

Het project draait op GSD. De planning staat in `.planning/`:

- `.planning/STATE.md` — waar het project staat; lees dit eerst.
- `.planning/OPEN.md` — wat er open ligt, met per punt wat al onderzocht is en
  wat de volgende stap is. De bovenste sectie is de actuele; alles daaronder is
  historie. Lees dit als tweede: het is geschreven voor een agent die de vorige
  sessie niet heeft meegemaakt.
- `.planning/ROADMAP.md` en `REQUIREMENTS.md` — de actieve milestone.
- `.planning/quick/<id>-<slug>/` — losse taken, met PLAN.md en SUMMARY.md.
- `.planning/debug/<slug>.md` — lopende en afgesloten bugonderzoeken. Staat er
  een op `investigating` of `awaiting_human_verify`, kijk dan eerst of jouw
  taak daarmee te maken heeft voordat je iets nieuws begint.

Wat dat voor jou betekent, ook als je geen GSD-commando's hebt:

1. **Plan voordat je bouwt**, en schrijf dat plan op in de taakmap.
2. **Commit atomair.** Eén samenhangende wijziging per commit, met tests groen.
3. **Raak `.planning/` niet aan** buiten de map van de taak waar je aan werkt.
4. **Werk de SUMMARY bij** als je klaar bent: wat je vond, niet alleen wat je
   deed. De vondsten zijn het waardevolste deel van het archief.

**Loop de hele app na bij een wijziging.** Als je een patroon aanpast, pas je
het overal toe waar het speelt en noem je zelf de plekken die je gevonden hebt.
Een halve sweep levert drift op, en die kost later een hele sessie.

## Wat Joost zelf doet

Niet uit beleefdheid, maar omdat jij er niet bij kunt:

- Inloggen met zijn Google-account (app, Play Console, Cloud Console).
- Bestanden uploaden naar de Play Console.
- Alles wat een betaalstroom of een rechtenwijziging op zijn account raakt.

De rest verifieer je zelf: bouwen, op de Oppo installeren, via `adb` bedienen,
tests draaien, logs lezen. Schuif geen huiswerk door dat je zelf kunt doen.

## Skills

Kennis-skills staan in de repo:

- `.claude/skills/material-3/` — Material 3 voor deze app.
- `.agents/skills/` — Firebase en Xcode.

Draai je Droid, importeer ze dan eenmalig (`/skills` → import uit
`.claude/skills`) of lees het `SKILL.md` rechtstreeks. De GSD-skills onder
`~/.claude/skills` gaan **niet** mee: die orkestreren via Claude Codes eigen
subagents en slash-commands. De werkwijze zelf staat hierboven beschreven, en
dat is het deel dat overdraagbaar is.

## Overdracht tussen agents

Wissel je van agent (Claude-limiet bereikt, of andersom), dan is git de
overdracht, niet de prompt:

```bash
git status && git diff      # kijk wat er openstaat
git add -A && git commit -m "wip: <waar je stond>"
droid    # of: claude
```

Begin in de nieuwe sessie met: lees `AGENTS.md`, lees `.planning/STATE.md` en
`.planning/OPEN.md`, bekijk `git log -5` en de laatste SUMMARY, en ga dan
verder. Draai niets terug wat werkt zonder te zeggen waarom.

**Wat je achterlaat is belangrijker dan wat je afmaakt.** Wissel je midden in
een onderzoek, schrijf dan eerst op wat je al weet en wat je nog niet weet, in
het bestand waar het thuishoort. Een hypothese die je in je hoofd had en niet
opschreef, moet de volgende agent opnieuw bedenken; een uitgesloten hypothese
die je wél opschreef, bespaart hem een ronde. Zet daarom ook op wat níét de
oorzaak bleek, met de reden.
