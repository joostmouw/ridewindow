// lib/features/shared/top_banners.dart
// Eén plek bovenaan voor de balken die over elke route heen liggen.
//
// Onder elkaar in één kolom, zodat ze elkaar nooit afdekken: een iOS-bezoeker
// kan tegelijk de installatiebalk en de update-melding krijgen. Bovenaan en
// niet onderaan, zodat de vaste NavigationBar in ScaffoldWithNav vrij blijft.
// Staat er geen enkele balk, dan vangt de lege kolom ook geen tikken af.

import 'package:flutter/material.dart';

import 'package:ridewindow/features/shared/add_to_home_screen_overlay.dart';
import 'package:ridewindow/features/shared/app_update_banner.dart';
import 'package:ridewindow/features/shared/store_app_banner.dart';

class TopBanners extends StatelessWidget {
  const TopBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppUpdateBanner(),
            StoreAppBanner(),
            AddToHomeScreenOverlay(),
          ],
        ),
      ),
    );
  }
}
