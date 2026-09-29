---
quick_id: 260929-app-links-en-bolletje
date: 2026-09-29
status: code-complete, wacht op release en toestelcontrole
---

# Website naar de app, en een bolletje dat verdwijnt als je het gezien hebt

## Wat er gebouwd is (vier commits)

1. **a4651f6: "Doe mee" in de store-balk werkt.** De sheet opent via de
   `navigatorKey` van de router, omdat `TopBanners` boven de Navigator staat.
   De kruisjes van alle drie de balken hebben geen tooltip meer maar een
   `semanticLabel` (`BannerCloseButton`). Staat de app erop, dan toont de
   balk "Openen in app" (`getInstalledRelatedApps` + `intent:`-link op het
   `ridewindow`-schema).
2. **6617e6c: het bolletje telt wat je nog niet zag.** Ritvragen,
   groepsaanvragen en nieuwe maatjes hebben elk een lokale gezien-set
   (`SeenIdsStore`). Ritvragen wissen op Ritten, de rest op Peloton; elke tab
   en subtab toont zijn eigen getal. Een nieuw maatje staat bovenaan met
   "Nieuw maatje".
3. **35b1142: App Links.** Links zijn padlinks (`/invite/CODE`,
   `/group/CODE`); `autoVerify`-filter op die twee paden;
   `web/.well-known/assetlinks.json` met Play- en uploadsleutel;
   `firebase.json` rolt `.well-known` mee uit; `index.html` zet een padlink om
   naar de hash-route; `asset_statements` voor "Openen in app". Een
   structuurtest (`test/structure/app_links_test.dart`) houdt de vijf
   bestanden in de pas.
4. **152ecf6: werkregel** in `AGENTS.md` en `CLAUDE.md`: eerst kijken hoe
   goedlopende apps een interactie doen, als vast kopje in het PLAN.md.

## Vondsten

1. **Alles wat in `MaterialApp.router(builder:)` staat, heeft geen Navigator
   en geen Overlay.** `showModalBottomSheet(context)` en `Tooltip` gooien
   daar. Bewezen met een probe-test. De oude test zag het niet, omdat die de
   balk onder `home: Scaffold` hing. Nieuwe balktests bouwen de balk zoals
   `main.dart` dat doet.
2. **De standaard-ignore `**/.*` van `firebase init` gooit `.well-known`
   weg.** Nu staat er een expliciete lijst (`.last_build_id`, `.DS_Store`);
   `.last_build_id` was de enige andere dotfile in `build/web`.
3. **Een fragment kan Android niet matchen.** De oude `/#/invite/`-links
   openen daarom nooit de app, ook niet na deze wijziging. In de browser
   blijven ze werken.
4. **De Play-sleutel is een andere dan de uploadsleutel.** SHA-256
   `17:A9:37:…:1B:6F` gelezen met apksigner uit de Play-APK op de Oppo; de
   SHA-1 klopt met "Play App Signing" in `docs/CONSOLE-SETUP-CHECKLIST.md`.
   Een lokaal gebouwde APK draagt `2F:F3:88:…:A8:92`. Beide staan in
   assetlinks.
5. **Riverpod 3 pauzeert providers die alleen gelezen worden door widgets in
   een uitgeschakelde TickerMode.** Een test die zo'n provider na het wisselen
   van tab uitleest, ziet de oude waarde. De tests lezen daarom `.value` of de
   prefs-store.
6. **Getest in een echte browser tegen de lokale hosting-emulator:**
   `/invite/ABCD2345` wordt `/#/welcome` voor een nieuwe gebruiker, en
   `flutter.peloton.pendingInviteCode` staat op `ABCD2345`. De omzetting en de
   redirect werken dus samen. `/.well-known/assetlinks.json` komt als
   `application/json`.
7. **Analyze-baseline is 204, niet 201.** Een schone worktree op HEAD geeft
   exact dezelfde 204 meldingen, dus deze ronde voegt er geen toe.

## Wat níét de oorzaak bleek

- De store-balk werd niet verborgen of overlapt: de tik kwam aan, de sheet
  gooide.
- Het bolletje op Peloton was geen nieuw maatje (dat zou 2 geven en werd bij
  het kijken al gewist), maar Richards ritvraag, die telde tot je antwoordde.

## Nog open

- Release: versiebump, AAB naar internal, web-deploy op hetzelfde moment
  (`docs/RELEASE-ROUTE.md`). Pas na de web-deploy staat assetlinks live.
- Op de Oppo: `pm get-app-links ridewindow.joost.amsterdam` moet `verified`
  zeggen voor `my-project-joost.web.app`; een link uit WhatsApp of Gmail moet
  de app openen; de store-balk in Chrome moet "Openen in app" tonen.
