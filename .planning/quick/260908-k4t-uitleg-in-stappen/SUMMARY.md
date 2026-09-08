---
quick_id: 260908-k4t
slug: uitleg-in-stappen
date: 2026-09-08
status: complete
---

# De uitleg is een Material 3 rich tooltip geworden

## De aanleiding

Joost: *"die pop-ups met uitleg vind ik niet mooi en niet helder"* — met als
gevraagde richting driver.js: een teller en `‹ ›` zodat je uitleg kunt
terughalen. En erbij: *"of is er nog een betere Material Design-optie die
aansluit op mijn app?"*

Die tweede vraag bleek de moeite waard.

## Het antwoord op de Material 3-vraag

**MD3 kent geen rondleiding-component.** Er staat geen coach mark in de spec;
driver.js is een webbibliotheek, geen Material-patroon. Maar er is wél een
component met precies de goede anatomie: de **rich tooltip** — meerdere regels,
een titel, knoppen eronder.

Dat legt andere maten op dan ik eerst had geschetst: `surfaceContainer` in
plaats van papier, hoek 12 (`AppShapes.radiusMd`) in plaats van 20, en
schaduwniveau 2.

De streepjes die Joost eerst koos zijn óók geen MD3 — er is geen stappenteller
in de spec. De dichtstbijzijnde echte component is de determinate
`LinearProgressIndicator`, en Flutter 3.44 tekent die in de huidige M3-vorm met
een gat vóór de stopindicator. Beide varianten zijn live naast elkaar gezet in
schets 007; Joost koos E.

## Wat er lag

Twee systemen die geen van beide deden wat gevraagd werd:

| | Wat het was | Wat eraan mankeerde |
|---|---|---|
| `screen_hint_overlay.dart` | Spotlight per scherm | `1/3` maar geen terug. Elke tik op het scherm sprong vooruit. Kaart was `Colors.white.withAlpha(30)` — glas, in een app die papier is |
| `app_tour_overlay.dart` | Vier volle schermen bij eerste start | Bolletjes, geen teller, geen terug. **Teksten hardgecodeerd in het Nederlands**, dus een Engelse gebruiker kreeg bij zijn allereerste start vier schermen Nederlands |

Dit waren de laatste twee bestanden met hardgecodeerde kleuren, en de enige
schermen die nooit door de papier-en-inkt-ronde van fase 23 zijn gegaan.

## Wat er nu staat

`lib/features/shared/step_controls.dart` — één voet, gedeeld door beide:
voortgangsbalk, Vorige, Volgende/Klaar, Overslaan. Wat je op het ene scherm
leert werkt dus op het andere ook.

Vorige is **uitgeschakeld** op stap één, niet verborgen. Een knop die pas bij
stap twee verschijnt laat de rij verspringen, en dan zit "Volgende" niet meer
waar je duim hem net had.

Alle acht rondleidingsteksten plus de vier knoplabels staan nu in `app_en.arb`
én `app_nl.arb`.

## De vondst: een regressie die ik zelf introduceerde

Weghalen dat een tik vooruitspringt was het hele punt — maar die tik was ook
de enige uitweg als het doelelement niet te meten viel. De kaart hing achter
`if (targetRect != null)`; zonder gemeten doel zag je alleen de scrim. Met
tik-om-verder was dat te overleven. Zonder zou je **opgesloten zitten in een
donker scherm zonder knoppen**.

Dat kwam boven omdat de eerste testopzet niets vond: in een test wordt de
overlay in dezelfde frame gebouwd als zijn doel, en dan is er nog niets
gelegd. De verleiding was om de test aan te passen. In plaats daarvan zijn er
twee dingen in de app veranderd:

- een `addPostFrameCallback` die één keer opnieuw meet na de eerste frame;
- de kaart verschijnt nu **altijd**, gecentreerd, ook zonder doel — alleen het
  pijltje blijft dan weg.

Een test met een `GlobalKey` die aan niets hangt houdt dat vast.

## En terloops

De ARB-metadata voor een placeholder hoort in het **sjabloon**, en dat is hier
`app_nl.arb` (zie `l10n.yaml`), niet de Engelse. In de Engelse gezet levert het
`gen-l10n` de melding op dat het type `Object` moet zijn — de generator lijkt
dan stil te falen terwijl hij dat niet doet.

## Verificatie

`test/features/screen_hint_overlay_test.dart`, acht tests, groen. Deze
overlays hadden hiervóór **geen enkele test**. Wat ze bewaken is wat aan een
screenshot niet te zien is:

- een tik naast de knoppen springt niet vooruit — de aanleiding voor de hele
  wijziging, en één weggelaten `onTap` van terugkomen;
- Volgende en Vorige lopen heen en weer; Vorige staat uit op stap één;
- Overslaan en Klaar sluiten allebei af;
- de knoppen zijn vertaald (in `en` staat er "Next", niet "Volgende");
- de voortgangsbalk staat op 0 bij de eerste en op 1 bij de laatste stap;
- een doel dat nergens hangt sluit je niet op.

Volledige suite: 520 tests groen.
