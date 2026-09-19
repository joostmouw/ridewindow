/// Past de klok van dit toestel bij de plek waarvan we het weer tonen?
///
/// **Waarom dit bestaat.** De hele tijdas van de app staat in de tijdzone van
/// het *toestel*, terwijl het weer en de zon bij de *locatie* horen. Zolang die
/// twee samenvallen — het gewone geval — merkt niemand er iets van. Reist
/// iemand weg zonder dat de locatie meeverhuist, dan gaat het meteen hard mis:
/// een tester in Aruba (UTC−4) kreeg de Amsterdamse zon te zien en las daardoor
/// "licht van 01:32 tot 13:29".
///
/// **Waarom de lengtegraad en niet de echte tijdzone.** Open-Meteo stuurt
/// `utc_offset_seconds` mee, maar dat veld bewaren betekent een kolom erbij in
/// de uurcache en dus een migratie — voor een waarschuwing die alleen hoeft te
/// weten of iemand op een ánder werelddeel zit. De zonnetijd van een lengtegraad
/// is lon/15 uur; dat is genoeg om continenten te onderscheiden.
///
/// **Waarom drie uur.** Politieke tijdzones lopen tot ~1,5 uur voor op hun
/// zonnetijd, en zomertijd legt daar nog een uur bovenop: Nederland zit in de
/// zomer 1,7 uur van zijn eigen zonnetijd af. Drie uur laat dat allemaal met
/// rust en vangt nog steeds elke oversteek over een oceaan.
library;

const Duration kForeignClockThreshold = Duration(hours: 3);

/// True als [deviceOffset] niet te rijmen valt met de zonnetijd op [lon].
bool clockLooksForeign({
  required double lon,
  required Duration deviceOffset,
  Duration threshold = kForeignClockThreshold,
}) {
  final solarOffsetHours = lon / 15.0;
  final deviceOffsetHours = deviceOffset.inMinutes / 60.0;
  final diff = (deviceOffsetHours - solarOffsetHours).abs();
  return diff > threshold.inMinutes / 60.0;
}
