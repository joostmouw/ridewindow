// lib/core/web_reload.dart
// Herlaadt de pagina op web, zodat de nieuwe bundel binnenkomt. Op Android en
// in `flutter test` doet dit niets; zelfde conditionele import als
// pwa_display_mode.dart, zodat package:web nooit buiten de webbuild komt.

import 'web_reload_stub.dart' if (dart.library.js_interop) 'web_reload_web.dart'
    as impl;

void reloadPage() => impl.reloadPage();
