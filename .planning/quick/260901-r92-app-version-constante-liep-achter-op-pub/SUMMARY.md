---
id: 260901-r92
slug: app-version-constante-liep-achter-op-pub
date: 2026-09-01
status: complete
---

# `app_version.dart` liep achter op `pubspec.yaml` — en de rode test die dat zei, was verkeerd geduid

## Wat er mis was

`ee1a081 chore(release): 1.0.23+24` bumpte `pubspec.yaml` maar liet
`lib/core/app_version.dart` op `1.0.22` / `23` staan.

Gevolg: de AAB van 17:32 draagt in zijn manifest `versionCode=24` / `versionName=1.0.23`, maar
toont in de app zelf **"1.0.22 (23)"**. Hetzelfde geldt voor de live PWA, die van dezelfde commit
is gedeployd: `version.json` zegt 1.0.23/24, het profielscherm zegt 1.0.22.

## Hoe het gevonden is, en waarom dat het echte punt is

`test/core/app_version_test.dart` bewaakt precies deze invariant en stond dus rood. Maar in
`MORGEN.md` en `STATE.md` stond de suite genoteerd als **"441/1 — die ene is de bekende
notificatietest die na 19:00 UTC faalt"**. Dat was hij niet: de notificatietest slaagde, en de
enige rode was deze versietest.

Eén bekende flaky test in de suite maakt elke nieuwe rode test onzichtbaar zodra je "1 gefaald"
leest in plaats van *welke*. Dat is hier gebeurd, en het is dezelfde klasse fout die de test zelf
in zijn commentaar beschrijft: fase 21 verloor al twee toestelsessies aan "welke build draait
hier eigenlijk?".

Na de fix: **451/451 groen**, dus de suite heeft nu geen enkele bekende rode meer — ook de
notificatietest niet (die faalt alleen ná 19:00 UTC).

## Wat er gewijzigd is

- `lib/core/app_version.dart` → `1.0.23` / `24`.
- AAB opnieuw gebouwd. De oude was gebouwd mét de foute constante en mocht dus niet omhoog.

`flutter analyze`: 162 issues, allemaal `info` — de gedocumenteerde baseline, onveranderd.

## Consequentie die openstaat

De **live PWA** draait nog de oude constante. Die corrigeert zichzelf zodra deze commit gepusht
wordt: `deploy-web.yml` triggert op `lib/`. Dat is Joost's beslissing, niet de mijne — pushen naar
main deployt live.
