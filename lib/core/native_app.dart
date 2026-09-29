// lib/core/native_app.dart
// Vanaf de website naar de Android-app: staat hij erop, en zo ja, open hem.
// Zelfde conditionele import als pwa_display_mode.dart, zodat package:web
// nooit buiten de webbuild komt.

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'native_app_stub.dart' if (dart.library.js_interop) 'native_app_web.dart'
    as impl;

const kAndroidPackage = 'ridewindow.joost.amsterdam';

/// Test-only: vervangt de vraag aan Chrome. Zet terug op `null` in `tearDown()`.
@visibleForTesting
bool? debugIsNativeAppInstalledOverride;

/// Test-only: vangt de link op in plaats van ernaartoe te navigeren.
@visibleForTesting
void Function(String url)? debugOpenNativeAppOverride;

/// Of de Android-app op dit toestel staat, gevraagd aan Chrome via
/// `navigator.getInstalledRelatedApps()`.
///
/// Chrome antwoordt alleen ja als het verband in beide richtingen verklaard
/// is: `related_applications` in `web/manifest.json` en `asset_statements` in
/// de Android-manifest. Elke andere browser kent de functie niet; dan is het
/// antwoord `false` en blijft de balk "Doe mee" zeggen.
Future<bool> isNativeAppInstalled() async {
  final override = debugIsNativeAppInstalledOverride;
  if (override != null) return override;
  try {
    return await impl.readIsNativeAppInstalled();
  } catch (_) {
    return false;
  }
}

/// De link die Chrome de app laat openen op [route] (een go_router-pad).
///
/// Een `intent:`-link en geen App Link, omdat Chrome een link naar het eigen
/// domein in het tabblad houdt. Het schema `ridewindow` staat al in de
/// manifest (voor de bevestigingsmail) en kent geen padbeperking; de lege host
/// (`///`) maakt van [route] het pad dat de app aan go_router doorgeeft.
String nativeAppIntentUrl(String route) {
  final path = route.startsWith('/') ? route : '/$route';
  return 'intent://$path#Intent;scheme=ridewindow;package=$kAndroidPackage;end';
}

/// Opent de app op het scherm waar de website nu staat.
void openNativeApp() {
  final url = nativeAppIntentUrl(impl.currentRoute());
  final override = debugOpenNativeAppOverride;
  if (override != null) return override(url);
  impl.navigateTo(url);
}
