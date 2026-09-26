// lib/services/app_update_service.dart
// Weet of er een nieuwere build klaarstaat, en start hem.
//
// Twee bronnen, omdat de twee kanalen elk hun eigen waarheid hebben:
// - Android vraagt het aan Play zelf (Play Core via `in_app_update`). Geen
//   eigen "laatste versie" ergens bijhouden: die zou bij een release vergeten
//   worden, en Play weet het al, ook voor internal en closed.
// - Web leest `version.json`, dat Flutter naast elke bundel zet en dat
//   `firebase.json` al met no-cache serveert. Dezelfde server die de app al
//   levert; er gaat geen gebruikersgegeven mee.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ridewindow/core/app_version.dart';
import 'package:ridewindow/core/store_links.dart';
import 'package:ridewindow/core/web_reload.dart';

abstract class AppUpdateService {
  /// Het buildnummer dat klaarstaat, of `null` als er niets nieuwers is of de
  /// vraag niet te beantwoorden valt. Gooit nooit: een update-melding mag
  /// nooit de reden zijn dat de app hapert.
  Future<int?> availableBuild();

  /// Zet de update in gang. Op Android de flow van Play, op web herladen.
  Future<void> apply();
}

/// Of [remote] nieuwer is dan wat hier draait.
bool isNewerBuild(int? remote, {String current = kAppBuildNumber}) {
  final here = int.tryParse(current);
  return remote != null && here != null && remote > here;
}

class PlayAppUpdateService implements AppUpdateService {
  const PlayAppUpdateService();

  @override
  Future<int?> availableBuild() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return null;
      }
      final code = info.availableVersionCode;
      return isNewerBuild(code) ? code : null;
    } catch (_) {
      // Een sideload of een toestel zonder Play geeft hier een fout. Dan valt
      // er niets te melden, want Play kan deze installatie niet bijwerken.
      return null;
    }
  }

  @override
  Future<void> apply() async {
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.success ||
          result == AppUpdateResult.userDeniedUpdate) {
        return;
      }
    } catch (_) {
      // Mag of lukt de updateflow van Play niet: dan de Play-vermelding.
    }
    await launchUrl(
      Uri.parse(kPlayStoreListingUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}

class WebAppUpdateService implements AppUpdateService {
  WebAppUpdateService({http.Client? client, Uri? base})
      : _client = client ?? http.Client(),
        _base = base;

  final http.Client _client;
  final Uri? _base;

  @override
  Future<int?> availableBuild() async {
    try {
      // Een eigen query per keer, voor het geval een proxy onderweg de
      // no-cache van Firebase Hosting negeert.
      final uri = (_base ?? Uri.base).resolve('version.json').replace(
        queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json is! Map) return null;
      final build = int.tryParse('${json['build_number']}');
      return isNewerBuild(build) ? build : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> apply() async => reloadPage();
}
