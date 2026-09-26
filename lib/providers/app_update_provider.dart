import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/services/app_update_service.dart';

part 'app_update_provider.g.dart';

/// Welke bron de update-melding raadpleegt. Eigen provider zodat een test hem
/// kan overriden: de echte vraagt het aan Play of aan de webserver.
@Riverpod(keepAlive: true)
AppUpdateService appUpdateService(Ref ref) => isWebPlatform
    ? WebAppUpdateService()
    : const PlayAppUpdateService();
