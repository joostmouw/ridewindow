// lib/core/native_app_web.dart
// Alleen in de webbuild; zie native_app.dart.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// `getInstalledRelatedApps` is geen webstandaard en staat niet in
/// package:web; alleen Chrome op Android kent hem.
extension type _RelatedAppsNavigator(JSObject _) implements JSObject {
  external JSPromise<JSArray<JSObject>> getInstalledRelatedApps();
}

Future<bool> readIsNativeAppInstalled() async {
  final navigator = web.window.navigator as JSObject;
  if (!navigator.has('getInstalledRelatedApps')) return false;
  final apps =
      await _RelatedAppsNavigator(navigator).getInstalledRelatedApps().toDart;
  return apps.toDart.isNotEmpty;
}

/// De app draait op hash-routering: `#/rides` is route `/rides`.
String currentRoute() {
  final hash = web.window.location.hash;
  final route = hash.startsWith('#') ? hash.substring(1) : hash;
  return route.isEmpty ? '/home' : route;
}

void navigateTo(String url) => web.window.location.href = url;
