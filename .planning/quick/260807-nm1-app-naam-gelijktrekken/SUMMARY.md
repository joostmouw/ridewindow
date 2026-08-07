---
id: 260807-nm1
slug: app-naam-gelijktrekken
date: 2026-08-07
type: quick
status: complete
---

# De app heette op drie plekken anders

## Hoe dit bovenkwam

Niet uit een audit maar uit een screenshot: Joost had na de §3-installatie twee RideWindow-iconen
naast elkaar op zijn beginscherm en zag dat ze verschillend heetten. Zonder die twee iconen naast
elkaar was dit onzichtbaar gebleven — je ziet je eigen app-naam nooit náást een tweede variant.

## Wat er fout was

| Bron | Was | Is |
|---|---|---|
| `AndroidManifest.xml` `android:label` | `ridewindow` | `RideWindow` |
| `web/index.html` `<title>` | `ridewindow` | `RideWindow` |
| `web/index.html` `apple-mobile-web-app-title` | `ridewindow` | `RideWindow` |
| `web/manifest.json` `name` / `short_name` | `RideWindow` | ongewijzigd |

De webkant sprak zichzelf dus ook tegen: het geïnstalleerde icoon heette anders dan het tabblad.
`pubspec.yaml`'s `name: ridewindow` is bewust ongemoeid gelaten — dat is de Dart-package-naam, die
moet lowercase snake_case zijn en is nooit zichtbaar.

## De test

`test/web/app_display_name_test.dart` asserteert dat de vijf gebruikerszichtbare bronnen het
**onderling eens zijn**, niet dat ze een letterlijke waarde hebben. Dat is expliciet de les die
quick-260726-ka2 opschreef nadat `pwa_install_meta_test.dart` op `'#2E7D32'` asserteerde en
moest worden herschreven zodra de merkkleur legitiem veranderde. Hernoemen kost nu één edit, geen
testfaling die iemand verleidt de test "te repareren".

Eén extra assertie dekt de degenererende oplossing af (alle vijf op dezelfde fóute waarde zetten).

**Negatief geverifieerd:** met `android:label` tijdelijk terug op `ridewindow` faalt de test, en de
foutmelding noemt de afwijkende bron bij naam. Een test die alleen groen is bewijst niets.

## Gevolg voor de release

De AAB van 12:26 droeg de oude naam en is vervangen door een verse build van 13:03 — zelfde versie
1.0.22+23, nu met `RideWindow` in het manifest (geverifieerd in de AAB zelf). Upload die.

Suite 445/445, `flutter analyze` terug op de baseline van 162 infos (geen enkele nieuwe).

## Bewust niet gedaan

Het **logo**-verschil tussen de twee iconen. `tools/make_icons.py` zet het Android-adaptive-icoon
op schaal 0.58 (regel 159) en het web-maskable op 0.60 (regel 171); doordat Android naar een 72dp-
masker cropt en het web naar een ruimere veilige zone, komt de glyph op de PWA zichtbaar kleiner
uit. Dat is een echt verschil, maar het corrigeren vraagt een ontwerpkeuze over hoe groot het merk
in het masker hoort te staan. Aan Joost gemeld, niet zelf ingevuld.
