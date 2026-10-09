# Release 1.0.55 (66): PWA-domein op Android

## Doel

De Android-app, PWA en internal-track brengen op dezelfde releasecommit de
nieuwe `ridewindow.web.app` App Link-host uit. Alpha blijft op de eerder
goedgekeurde build totdat 66 op de Oppo is gecontroleerd.

## Aanpak

1. Bump `pubspec.yaml` en `app_version.dart` samen naar 1.0.55 (66).
2. Beschrijf de domeinmigratie in beide release-notities.
3. Draai de volledige suite, analyse en releasebuilds.
4. Deploy de PWA vanaf deze commit en upload dezelfde AAB naar internal.
5. Meet de live PWA en Play-tracks; leg de open Oppo-controle vast.

## Hoe goedlopende apps dit doen

WhatsApp en Strava behandelen een vernieuwde deep-link-host als een gewone
app-update: oude links blijven werken, terwijl de update de nieuwe host als
rechtstreekse App Link registreert. Dat nemen we over. Anders dan een gewone
tekstuele PWA-wijziging gaat deze release eerst alleen naar internal, omdat
Android de nieuwe associatie pas bij de geïnstalleerde app kan bewijzen.
