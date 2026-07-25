import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// De huidige tijd, als provider zodat hij in tests te overriden is.
///
/// De slot-pipeline knipt vensters weg die al begonnen zijn. Zonder deze
/// indirectie zou elke test die door `SlotsNotifier` heen loopt een fixture met
/// een vaste datum in het verleden moeten hebben — en die vallen dan allemaal
/// weg achter de cut-off.
@Riverpod(keepAlive: true)
DateTime now(Ref ref) => DateTime.now();
