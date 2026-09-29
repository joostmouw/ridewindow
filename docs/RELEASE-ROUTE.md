# Release-route: de ene weg naar tester en winkel

Vastgelegd op 2026-09-21 op verzoek van Joost, nadat lokale APK, de PWA,
internal en closed zonder afspraak uit elkaar konden lopen. Het doel is één
versionCode per release, één vaste volgorde, en één tabel die altijd zegt wat
er waar live staat.

## De vier kanalen

| Kanaal | Wanneer gebruik je het | Review van Google | Effect op het toestel |
|---|---|---|---|
| **Lokale APK** (`adb install`) | alleen voor verse-installatie-testen (o.a. de eerste-minuut-flow) | geen | vervangt de Play-installatie: lokale database en Calendar-grant gaan overboord, en Play kan daarna niet meer bijwerken tot je de sideload overal verwijdert (zie "Terug van een sideload naar Play"). Noteer het in STATE.md als je het doet |
| **PWA** (`my-project-joost.web.app`) | op een releasemoment, vanaf dezelfde commit als de internal-build | geen | aparte webbundel, eigen cache: na een deploy hard herladen of `?v=<code>` meegeven |
| **Internal testing** | élke release komt hier eerst; testers zien het onmiddellijk | geen | niets raakt het toestel: de Oppo haalt de build via Play-update op en houdt database en grants intact. Dé manier om op het toestel te testen |
| **Alpha / closed testing** | de track die Google telt voor de productie-eis (12 testers, 14 dagen) | ja, bij élke promotie (duurt soms dagen) | alleen krijgen wat op internal is goedgekeurd; zichtbaar voor testers pas ná review |

## De route per release

1. **Commit en push** (push gebeurt op Joosts sein). Elke build is terug te
   voeren op een commit; de changelog en release-notities gaan mee.
2. **Versiebump** in beide bestanden: `pubspec.yaml` (`version:`) én
   `lib/core/app_version.dart` (`kAppVersionName` + `kAppBuildNumber`). De
   suite is groen (de versietest faalt als de twee uit de pas lopen),
   `flutter analyze` op baseline. Release-notities ≤ 400 tekens, volledige
   zinnen — de tool weigert erboven (les van 2026-09-21).
3. **Bouw de AAB**: `flutter build appbundle --release` (de enige build die
   naar Play gaat). Voor een exclusieve sideload-ronde apart:
   `flutter build apk --release` — dat is dan géén Play-build.
4. **PWA op hetzelfde releasemoment** deployen vanaf dezelfde commit:
   `scripts/deploy_web.sh`, daarna de live versie verifiëren. De PWA leidt
   nooit een eigen leven.
5. **Upload naar internal**: `dart run tool/play_upload.dart --track internal
   --notes en-US:release-notes/en-US.txt --notes nl-NL:release-notes/nl-NL.txt`.
   De Oppo krijgt de build via Play-update (geen sideload). Joost verifieert op
   het toestel: inloggen (beide manieren), agenda, peloton.
6. **Pas na toestelgoedkeuring promoveren naar alpha**:
   `dart run tool/play_upload.dart --promote <code> --track alpha` — dezelfde
   bytes, geen nieuwe upload. Daarna `--list-tracks`: beide tracks op
   dezelfde code.
7. **Productie (sluitstuk)**: pas als de eis is gehaald (12 testers, 14 dagen
   ononderbroken) én de developer-verificatie (deadline 30 september 2026
   volgens Play Console).

## Terug van een sideload naar Play

Vastgelegd op 2026-09-21, nadat de Oppo de update naar 1.0.42 (53) niet kon
ophalen. Play meldt dan alleen dat downloaden niet lukt en zegt niet waarom.

**Waarom het misgaat.** Play werkt alleen bij wat hij zelf heeft geplaatst
(`installerPackageName`), en een lokaal gebouwde release-APK draagt de
**upload**-sleutel terwijl de Play-versie met Google's **app-signing**-sleutel
is ondertekend (`docs/CONSOLE-SETUP-CHECKLIST.md`). Een handtekening hoort bij
het pakket en geldt toestelbreed, dus zolang de sideload ergens op het toestel
staat, kan de Play-versie er niet naast.

**De val: `adb install` raakt ook de kloonruimte.** De Oppo heeft naast de
gewone gebruiker een `system_clone` (ColorOS, user 10). `adb install` zonder
`--user` zet de APK in álle ruimtes. Verwijderen via het startscherm haalt
alleen de eigen ruimte leeg; in de kloonruimte blijft hij staan en blokkeert
Play, terwijl het toestel er schoon uitziet.

**Zo controleer je het, in plaats van te gokken:**

```bash
ADB=~/Library/Android/sdk/platform-tools/adb
$ADB shell dumpsys package ridewindow.joost.amsterdam | grep -E "User [0-9]+:|installerPackageName"
```

`installed=true` in welke ruimte dan ook betekent: nog niet weg.
`installerPackageName=null` betekent: dit is een sideload, geen Play-installatie.

**Opruimen per ruimte, niet via het startscherm:**

```bash
$ADB shell pm list users                                  # welke ruimtes bestaan er
$ADB shell pm uninstall --user 10 ridewindow.joost.amsterdam
$ADB shell pm list packages | grep ridewindow             # leeg = schoon
```

**Voorkomen is korter dan opruimen:** sideload met `adb install --user 0 -r
<apk>`, dan blijft de kloonruimte erbuiten.

## Regels zodat versies niet afdrijven

- **Nooit een release zonder versiebump.** Eén versionCode per release.
- **Nooit sideloaden over een Play-installatie** als je echte data
  beoordeelt. Sideload is alleen voor verse-installatie-testen, en dan
  genoteerd in STATE.md. Een sideload is daarna geen Play-installatie meer:
  hij moet eerst wég voordat Play weer werkt.
- **De PWA deployt alleen op een releasemoment**, vanaf dezelfde commit als
  de internal-build — nooit tussendoor.
- **Notities ≤ 400 tekens** met complete zinnen; de tool weigert erboven.
- **Na elke upload of promotie `--list-tracks` draaien** en allebei
  controleren.
- **De "Waar | Stand"-tabel in `.planning/STATE.md` is de enige plek die
  zegt wat er waar live staat**; bijwerkt bij elke release, nooit achteraf.

## Waar de route hoort

- Dit bestand is de bron. `tool/README-play-release.md` beschrijft het
  script; `docs/CONSOLE-SETUP-CHECKLIST.md` de eenmalige inrichting. Bij een
  wijziging aan de route werk je dit bestand bij, niet de andere twee los.

## Stand 29 september 2026, na de internal-release van 1.0.51 (62)

| Waar | Stand |
|---|---|
| Oppo | laatst gezien op 1.0.50 (61); bij de release niet aangesloten |
| PWA | 1.0.51 (62), uitgerold door GitHub Actions na de push (niet met `scripts/deploy_web.sh`, dat zou met de CI-deploy racen); live `version.json` zegt 62 |
| Internal | 1.0.51 (62) |
| Alpha / closed | 1.0.44 (55) |

## Stand 26 september 2026 (avond), na de internal-release van 1.0.50 (61)

| Waar | Stand |
|---|---|
| Oppo | 1.0.50 (61) via Play, op de achtergrond geïnstalleerd 2026-09-27 12:32 |
| PWA | 1.0.50 (61), live bundelhash `f4597a85f0efb73409b65d40f34a708d` |
| Internal | 1.0.50 (61) |
| Alpha / closed | 1.0.44 (55) |
| main | 1.0.50+61 (`115d245`) |

**Wat 61 brengt:** bolletjes voor groepsaanvragen en nieuwe maatjes, een
update-balk bovenaan, en een store-balk op de website voor Android-bezoekers.
Vanaf 61 meldt de app zelf dat er een nieuwere build klaarstaat; de eerste
keer dat dat te zien is, is bij 62.

## Stand 26 september 2026, na de internal-release van 1.0.49 (60)

| Waar | Stand |
|---|---|
| Oppo | 1.0.49 (60) via Play, automatisch bijgewerkt om 16:33:59 |
| PWA | 1.0.49 (60), live bundelhash `877c4ff9e0340efca07190c7d15245d6` |
| Internal | 1.0.49 (60) |
| Alpha / closed | 1.0.44 (55) |
| main | 1.0.49+60 (`8c2a09f`) |

**Wat 60 brengt:** nettere ritkaarten (scorepil rechtsboven, inklapbaar
keuzeblok, meerkeuze achter een vinkje, plankaartjes in één kleur). De
details staan in `.planning/STATE.md`.

## Stand 25 september 2026, na de internal-release van 1.0.47 (58)

| Waar | Stand |
|---|---|
| Oppo | 1.0.47 (58) via Play; #84 met een tijdelijke rit in een eenpersoonsgroep op Home geverifieerd, niet de oorspronkelijke rit verwijderd |
| PWA | 1.0.47 (58), gedeployed met `scripts/deploy_web.sh`, live bundelhash `457908fe9d66949c15c4c13c95935521` |
| Internal | 1.0.47 (58) |
| Alpha / closed | 1.0.44 (55); 58 niet gepromoveerd, verdere toestel-/groepsritgoedkeuring staat open |
| main | 1.0.47+58 (`b39f8d5`), plus lokale toestel- en feedbackdocumentatie |

**Wat 58 brengt:** #84 maakt afzeggen van een georganiseerde rit consequent
vanaf Home, Ritten en ritdetail. Op de Oppo is Home bewezen met een nieuwe
rit zonder andere deelnemers; detail en Ritten zijn in tests afgedekt maar
niet afzonderlijk op het toestel doorlopen. De eerdere release 55 bracht
groepsritten (fase 35); 57 bevatte #80 en #83.

## Stand 21 september 2026, na de release van 1.0.42 (53)

| Waar | Stand |
|---|---|
| Oppo | leeg; sideload verwijderd uit beide ruimtes, installeren gaat weer via Play |
| PWA | 1.0.42 (53), gedeployed vanaf dezelfde commit, live hash geverifieerd |
| Internal | 1.0.42 (53) |
| Alpha / closed | 1.0.42 (53), gepromoveerd op verzoek, vooruitlopend op de toestelgoedkeuring |
| main | 1.0.42+53 |

**Wat 53 brengt:** het geluid en de trillingen onder de welkomstintro. Die
clip lag klaar sinds 2026-09-21 maar mocht de route niet in zolang zijn
licentie niet vaststond; dat is nu geregeld (Pixabay Content License,
vastgelegd naast de asset). Elk asset in de app heeft sindsdien een
herkomst die naast het bestand staat.

**Volgende stap:** Joost bedient 53 op de Oppo (inloggen op beide manieren,
agenda opnieuw koppelen, peloton). De promotie naar alpha is op zijn verzoek
al gedaan, dus die controle loopt nu achter de uitrol aan in plaats van
ervoor: valt er iets op, dan is de correctie een nieuwe build en geen
terugdraaiing.

## Stand 21 september 2026 (vastgelegd bij het opstellen)

| Waar | Stand |
|---|---|
| Oppo | internal-build 1.0.38 (49), via Play-update; database en grants intact |
| PWA | 1.0.38 (49), gedeployed 2026-09-21 |
| Internal | 1.0.38 (49) |
| Alpha / closed | 1.0.38 (49), gepromoveerd; bij Google ter review |
| main | 1.0.38+49, plus lokale commit `82f75f6` (e-mail-login, OPEN.md 11) — nog niet gepusht, gebouwd of geüpload |

**Openstaande release:** de e-mail-login gaat volgens deze route als
1.0.39+50, te beginnen met Joosts goedkeuring (stap 1), dan internal
(stap 5), pas daarna alpha (stap 6).
