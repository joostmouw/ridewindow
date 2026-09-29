---
quick_id: 260929-app-links-en-bolletje
date: 2026-09-29
status: planned
bron: photos/Record_2026-09-29-09-15-38_40deb401b9ffe8e1df2f1cc5ba480b12.mp4
---

# Website naar de app, en een bolletje dat verdwijnt als je het gezien hebt

## Wat de video laat zien (PWA in Chrome op de Oppo, app 1.0.50 (61) staat erop)

1. Joost tikt vier keer op "Join" in de store-balk. Er gebeurt niets.
2. Het rode bolletje op de tab Peloton blijft op 1 staan terwijl hij daar kijkt.
   Op de tab Ritten staat "Richard Mouw is asking you along".

## Oorzaken (bewezen, niet vermoed)

1. **"Join" doet niets: geen Navigator boven de balk.** `TopBanners` staat in
   `MaterialApp.router(builder:)`, dus boven de Navigator van go_router.
   `showModalBottomSheet(context: context)` gooit daar
   "Navigator operation requested with a context that does not include a
   Navigator" (bewezen met een probe-test, daarna verwijderd). De test van de
   balk hing hem in `home: Scaffold(...)`, waar wel een Navigator is, dus hij
   zag dit nooit. Zelfde oorzaak: de sluit-tooltip van alle drie de balken
   heeft geen Overlay (lang indrukken gooit).
2. **Het bolletje op Peloton gaat over een rit op Ritten.** De tab Peloton toont
   `pelotonAttentionCount` = ritvragen + groepsaanvragen + nieuwe maatjes. De
   1 is Richards ritvraag (een nieuw maatje zou 2 geven en wordt bij het kijken
   al gewist). Een ritvraag telt tot je antwoordt, niet tot je hem gezien hebt.
3. **De app opent nooit vanaf een link.** Er is geen https-intent-filter en geen
   `assetlinks.json`; uitnodigingslinks zijn `https://…/#/invite/CODE`, en een
   fragment kan Android niet matchen. Dit hangt niet af van closed testing:
   App Links werken nu al. Alleen de Play-link voor niet-testers wacht op de
   publieke lancering (`kStoreAppPublic`).

## Hoe goedlopende apps dit doen

- Instagram, Facebook, LinkedIn: het bolletje telt wat je **nog niet zag**, en
  gaat weg zodra je de plek opent. Wat nog een antwoord vraagt blijft in de
  lijst zelf gemarkeerd ("wacht op jou"), niet in het bolletje.
- Het bolletje staat op de tab waar het over gaat, niet op een buurtab.
- Strava, YouTube, Reddit: een gedeelde link opent de app als die erop staat;
  op de website staat "Openen in app" in plaats van "Installeren".

## Stappen

1. **Balken bovenaan:** de sheet opent via de navigator-context van de router;
   `TopBanners` krijgt een eigen `Overlay` zodat tooltips werken. Test in een
   echte `MaterialApp.router`-opbouw, zoals productie.
2. **Bolletje op "gezien":** ritvragen en groepsaanvragen krijgen een lokale
   gezien-set, net als `SeenFriendsStore`. Ritvragen wissen op de tab Ritten,
   maatjes en groepsaanvragen op de tab Peloton. Elke subtab toont alleen zijn
   eigen getal; de onderbalk de som. Een nieuw maatje krijgt bij dat bezoek een
   "Nieuw"-label, zodat je ziet wie erbij kwam.
3. **App Links:** `web/.well-known/assetlinks.json` met de Play-sleutel
   (`17:A9:37:…`, gelezen uit de Play-APK op de Oppo) en de upload-sleutel
   (`2F:F3:88:…`); `firebase.json` negeert dotfiles, dus `.well-known` moet
   expliciet mee. Intent-filter met `autoVerify` op `/invite/` en `/group/`.
   Nieuwe links worden `https://…/invite/CODE` (padvorm); een kleine regel in
   `index.html` zet die op web om naar `/#/invite/CODE`, en oude `/#/`-links
   blijven werken in de browser.
4. **"Openen in app" op de website:** Android-app declareert de site
   (`asset_statements`), de balk vraagt `getInstalledRelatedApps()` en toont
   dan "Openen" met een `intent://`-link in plaats van "Doe mee".
5. **Werkwijze:** regel in `AGENTS.md` en `CLAUDE.md`: bij elke interactie eerst
   nagaan hoe goedlopende apps het doen, en dat in het plan opschrijven.
6. Suite, analyze, release-APK op de Oppo, `pm get-app-links` moet `verified`
   zeggen, link uit WhatsApp/Gmail opent de app.
