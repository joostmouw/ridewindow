# 1.0.55 (66) op internal en web

Datum: 2026-10-09. Releasebron: `c869a40`, gepusht naar origin/main.

## Uitrol

- AAB 1.0.55+66 gebouwd, Play-dry-run groen en via de Play Developer API naar
  internal geüpload.
- `--list-tracks` bevestigt internal én alpha op **1.0.55 (66)** completed.
- GitHub Actions-run `37936646253` bouwde en deployde de PWA vanaf
  `c869a40`; live `version.json` zegt 1.0.55 / 66.
- `ridewindow.web.app` serveert de PWA en `assetlinks.json`; de oude host
  stuurt `/`, `/invite/<code>` en `/group/<code>` met een 301 naar hetzelfde
  pad op de nieuwe host.

## Wat 66 brengt

Android registreert `ridewindow.web.app` nu als App Link-host. Gedeelde
maatjes- en groepslinks gebruiken de nieuwe host. Oude gedeelde links blijven
werken via de legacy-redirect.

## Validatie

- `flutter test`: **1087 tests groen**.
- `flutter analyze`: 0 errors, 0 warnings, 214 bestaande infos.
- `flutter build appbundle --release`: geslaagd.
- `flutter build web --release`: geslaagd.
- Release-notities: en-US 172, nl-NL 182 tekens.
- AAB SHA-256:
  `3abc6b83df9a183bab250bc172de1a9463c64a2d9b09291473b29f4173915aea`.

## Vondst

De eerste CI-run voor de domeincommit faalde, omdat een comment-aanpassing
`kGroupLinkBase` uit `group_link.dart` had verwijderd. De lokale releasecheck
vond dezelfde compilerfout vóór de Play-upload. De constante is hersteld in
`c869a40`; daarna waren de volledige suite, de releasebuild en de PWA-CI groen.

## Open

De Oppo-controle is groen: 66 werkt op het toestel. Dezelfde bytes zijn
daarna naar alpha gepromoveerd. Geen sideload.
