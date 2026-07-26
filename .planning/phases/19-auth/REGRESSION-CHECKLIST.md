# Regressiechecklist — Fase 19 (Auth)

Dit bestand is bedoeld om **letterlijk herbruikt te worden in fase 21** (D-18): het beschrijft precies wat een mens moet doen om te bevestigen dat inloggen, "Voeg toe aan agenda" en de app zelf werken op een echte Android-release-installatie en een echte iPhone-PWA. Elk vinkje wordt afgevinkt op basis van een **geobserveerd resultaat**, niet aangenomen — als een stap niet is uitgevoerd, blijft het vinkje leeg en wordt de reden erbij genoteerd.

Plan 19-07 voert deze checklist uit en vult de resultaten hieronder in (of in een los verslag dat hiernaar verwijst). Niets in dit bestand is door Claude zelf afgevinkt — dat kan niet zonder een echte Play Store-installatie en een echte iPhone.

---

## 1. Android release (Play Store internal testing track)

**Bron:** installatie via de Play Store-link van het internal testing track, **niet** een lokaal gebouwde APK/AAB. Dit is bewust (D-16/AUTH-10): Google hertekent de app met de Play App Signing-sleutel bij een Store-installatie, en die sleutel heeft een ander SHA-1-fingerprint dan de lokale upload-keystore. Alleen een Store-installatie bewijst dat het juiste OAuth-Android-client (met het Play App Signing-fingerprint, zie `docs/CONSOLE-SETUP-CHECKLIST.md` §2) daadwerkelijk werkt.

- [ ] **Opstarten** — installeer de app via de Play Store internal testing-link (niet een lokale APK) en open hem. Noteer: laadt het scherm binnen een paar seconden, geen crash of witte pagina.
- [ ] **Inloggen** — tik op "Inloggen met Google" in de Account-sectie van Profiel, rond de Google-flow af. Noteer: verschijnt de ingelogde weergave (avatar/naam/e-mail) zonder foutmelding.
- [ ] **"Voeg toe aan agenda"** — open een Ride Detail-scherm en tik "Voeg toe aan agenda". Open daarna de echte Google Agenda-app (of agenda.google.com) en bevestig dat het event er staat met de juiste start/eind-tijd en het weerbericht in de omschrijving.
- [ ] **Uitloggen** — tik "Uitloggen" in de Account-sectie, bevestig de dialoog. Noteer: keert het scherm terug naar de uitgelogde weergave, en blijft de agenda-koppeling (indien apart verbonden) intact zoals D-12 voorschrijft.
- [ ] **Herstart → nog ingelogd** — log opnieuw in, sluit de app volledig af (uit recent-apps vegen, niet alleen naar de achtergrond), start hem opnieuw op. Noteer: toont de Account-sectie direct de ingelogde staat, geen kort geflikker naar "uitgelogd" (AUTH-04).

## 2. iPhone PWA

**Bron:** de live PWA op `https://my-project-joost.web.app`, geïnstalleerd op een echte iPhone via Safari — niet de desktop-browser en niet een simulator.

- [ ] **Installeren** — open de PWA-URL in Safari op de iPhone, gebruik "Zet op beginscherm". Noteer: verschijnt het juiste app-icoon op het beginscherm.
- [ ] **Standalone openen** — open de app vanaf het beginscherm-icoon. Noteer: geen Safari-adresbalk/-chrome zichtbaar (standalone-modus), de app opent op het Home-scherm.
- [ ] **Navigeren** — navigeer tussen Home, een Ride Detail-scherm en Profiel. Noteer: geen dode navigatie-eindes, terugknoppen werken, geen witte pagina bij een routewissel.
- [ ] **Inloggen** — tik op de gerenderde Google-knop (`renderButton()`, D-05/D-06 — dit is bewust een ander uiterlijk dan Android's eigen ListTile) in de Account-sectie en rond de flow af. Noteer: ingelogde weergave verschijnt zonder foutmelding.
- [ ] **"Voeg toe aan agenda"** — open een Ride Detail-scherm en tik "Voeg toe aan agenda". Bevestig in de echte Google Agenda dat het event verschijnt.

## 3. Web-koudestartmeting / cold-start measurement (D-19 — voedt REG-03 in fase 21)

Dit is een **meetmethode**, geen losse target-getal. Fase 21 herhaalt precies deze methode om REG-03 (2-secondenbudget) te beoordelen — een andere methode maakt die vergelijking betekenisloos. Vul alle velden hieronder in op het moment van meten; laat niets impliciet.

- [ ] **Toestel:** _(bv. "iPhone 13, iOS 18.x, Safari")_ — noteer het exacte model en de browser.
- [ ] **Verbindingstype:** _(bv. "4G, niet gethrottled" of "Chrome DevTools Fast 3G-throttling, gemeten op desktop" — kies er één en noteer welke)_.
- [ ] **Meetmethode:** tijd tussen het tikken op het PWA-icoon (of het laden van de URL in een koude tab/na volledig sluiten van de app) en het eerste zichtbare ritvenster (ride slot) op het Home-scherm. Gestopt met een stopwatch of de systeemklok van het toestel zelf — geen aanname, een daadwerkelijke timing.
- [ ] **Gemeten waarde:** _(bv. "1.4s")_ — noteer het getal en de datum/tijd van meting.
- [ ] **Meetomstandigheden:** noteer bijzonderheden die de meting kunnen beïnvloeden (koude cache vs. warme cache, eerste keer openen na installatie vs. herhaalde start, netwerkcondities op dat moment) zodat fase 21 exact dezelfde omstandigheden kan reproduceren.

---

*Geschreven door plan 19-06 (auto), uit te voeren door plan 19-07 (handmatig). Herbruikbaar as-is in fase 21 per D-18.*
