// De uitschieterregel (D-15/D-16), één implementatie voor het lokale
// `tool/usage_report.dart` en de dagelijkse GitHub Action.
//
// Per bron is één van twee regels genoeg:
//  1. totaal: rijen(dag) > 5 x mediaan(rijen over de 28 kalenderdagen ervoor)
//     én rijen(dag) > vloer_totaal[bron];
//  2. één afzender: max_rows_one_sender(dag) > vloer_afzender[bron].
// Dagen zonder rijen tellen als 0 in de mediaan.
//
// Meldingen noemen alleen bron en regel, nooit een getal: de Action-log is
// publiek (F-01, D-11). Om dezelfde reden noemen parse- en configuratiefouten
// nooit de invoer.
//
// Alleen `dart:core` en relatieve imports: dit draait met een kale `dart run`
// op een GitHub-runner, zonder pub get.

import 'usage_floors.dart';

/// Eén rij uit `usage_daily_counts`: één bron op één Amsterdamse kalenderdag.
class DayCount {
  const DayCount({
    required this.day,
    required this.source,
    required this.rows,
    required this.distinctSenders,
    required this.maxRowsOneSender,
    required this.p95RowsOneSender,
  });

  /// De rpc-vorm van PostgREST: `day` als 'YYYY-MM-DD', getallen als
  /// int/num/null.
  factory DayCount.fromJson(Map<String, dynamic> json) => DayCount(
        day: _parseDay(json['day'] as String),
        source: json['source'] as String,
        rows: (json['rows'] as num).toInt(),
        distinctSenders: (json['distinct_senders'] as num?)?.toInt(),
        maxRowsOneSender: (json['max_rows_one_sender'] as num?)?.toInt(),
        p95RowsOneSender: (json['p95_rows_one_sender'] as num?)?.toDouble(),
      );

  /// UTC-middernacht van de kalenderdag (de dag zelf is Amsterdams; de UTC is
  /// alleen een tijdzonevrije drager voor de datum).
  final DateTime day;
  final String source;
  final int rows;
  final int? distinctSenders;
  final int? maxRowsOneSender;
  final double? p95RowsOneSender;
}

/// Leest de CSV van `psql -At -F,`: `day,source,rows,distinct_senders,
/// max_rows_one_sender,p95_rows_one_sender`, geen kopregel, null als lege
/// string. Lege regels worden overgeslagen.
///
/// Een kapotte regel geeft een [FormatException] met alleen het regelnummer:
/// wat er stond kan een foutmelding van psql met een verbindingsstring zijn,
/// en die hoort niet in een publieke log.
List<DayCount> parseCountsCsv(String csv) {
  final out = <DayCount>[];
  final lines = csv.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final f = line.split(',');
    final where = 'telregel ${i + 1}';
    if (f.length != 6) {
      throw FormatException('$where heeft niet zes velden');
    }
    try {
      out.add(
        DayCount(
          day: _parseDay(f[0]),
          source: _parseSource(f[1]),
          rows: int.parse(f[2]),
          distinctSenders: f[3].isEmpty ? null : int.parse(f[3]),
          maxRowsOneSender: f[4].isEmpty ? null : int.parse(f[4]),
          p95RowsOneSender: f[5].isEmpty ? null : double.parse(f[5]),
        ),
      );
    } on FormatException {
      throw FormatException('$where heeft een ongeldig veld');
    }
  }
  return out;
}

final _dayPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final _sourcePattern = RegExp(r'^[a-z_]+$');

DateTime _parseDay(String s) {
  final m = _dayPattern.firstMatch(s);
  if (m == null) throw const FormatException('ongeldige dag');
  return DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

String _parseSource(String s) {
  if (!_sourcePattern.hasMatch(s)) {
    throw const FormatException('ongeldige bron');
  }
  return s;
}

/// De mediaan; een lege lijst geeft 0.
double median(List<int> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid].toDouble()
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

enum OutlierRule { totaal, eenAfzender }

/// Een uitschieter: welke bron, welke regel. Bewust zonder getallen.
class Outlier {
  const Outlier(this.source, this.rule);

  final String source;
  final OutlierRule rule;

  String get message => switch (rule) {
        OutlierRule.totaal => 'uitschieter: $source, '
            'totaal boven vijf keer de mediaan en boven de vloer',
        OutlierRule.eenAfzender =>
          'uitschieter: $source, één afzender boven de vloer',
      };

  @override
  String toString() => message;
}

/// De telling en de vloeren passen niet bij elkaar. Geen uitschieter maar een
/// fout die gerepareerd moet worden: een nieuwe bron mag nooit stil
/// overgeslagen worden. De melding noemt geen getallen.
class UsageConfigError implements Exception {
  const UsageConfigError(this.message);

  final String message;

  @override
  String toString() => 'UsageConfigError: $message';
}

/// Toetst [day] tegen de regel. [counts] mag ook de voorgaande dagen bevatten;
/// ontbrekende dagen tellen als 0. Geeft per bron en per regel hoogstens één
/// [Outlier].
List<Outlier> findOutliers(
  List<DayCount> counts,
  DateTime day, {
  Map<String, int> floorTotal = kFloorTotal,
  Map<String, int> floorSender = kFloorSender,
  int baselineDays = 28,
  double factor = 5,
}) {
  final target = DateTime.utc(day.year, day.month, day.day);

  // Elke bron in de invoer moet een vloer hebben, ook als hij gisteren niet
  // voorkwam.
  for (final c in counts) {
    if (!floorTotal.containsKey(c.source)) {
      throw UsageConfigError('geen totaalvloer voor bron ${c.source}');
    }
    if (c.maxRowsOneSender != null && !floorSender.containsKey(c.source)) {
      throw UsageConfigError('geen afzendervloer voor bron ${c.source}');
    }
  }

  // rows per (bron, dag)
  final bySourceDay = <String, Map<DateTime, int>>{};
  final onTarget = <DayCount>[];
  for (final c in counts) {
    final d = DateTime.utc(c.day.year, c.day.month, c.day.day);
    final perDay = bySourceDay.putIfAbsent(c.source, () => {});
    perDay[d] = (perDay[d] ?? 0) + c.rows;
    if (d == target) onTarget.add(c);
  }
  if (onTarget.isEmpty) {
    throw const UsageConfigError('dag ontbreekt in de telling');
  }

  final out = <Outlier>[];
  for (final c in onTarget) {
    final perDay = bySourceDay[c.source]!;
    final baseline = [
      for (var i = 1; i <= baselineDays; i++)
        perDay[DateTime.utc(target.year, target.month, target.day - i)] ?? 0,
    ];
    final m = median(baseline);

    if (c.rows > factor * m && c.rows > floorTotal[c.source]!) {
      out.add(Outlier(c.source, OutlierRule.totaal));
    }
    final max = c.maxRowsOneSender;
    if (max != null && max > floorSender[c.source]!) {
      out.add(Outlier(c.source, OutlierRule.eenAfzender));
    }
  }
  return out;
}
