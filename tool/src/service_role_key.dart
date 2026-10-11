// De service-role sleutel lezen, gedeeld door de lokale rapportscripts
// (`tool/analytics_report.dart`, `tool/usage_report.dart`).
//
// Eén plek, met opzet: deze code is ontstaan na een lek (zie
// [readServiceRoleKey]), en twee kopieën die uit elkaar drijven zouden precies
// dat lek kunnen terugbrengen in het script dat de fix niet kreeg (D-08).
//
// Alleen `dart:io`: de scripts draaien met `dart run`, zonder Flutter.

import 'dart:io';

/// Waar de sleutel standaard staat. Buiten de repo, met opzet.
String get defaultServiceRoleKeyPath {
  final home = Platform.environment['HOME'] ?? '.';
  return '$home/.config/ridewindow/supabase-service-role.key';
}

/// Hoe een sleutel eruitziet. Twee vormen, want Supabase kent er twee:
///  * de klassieke JWT -- drie met punten gescheiden base64url-delen;
///  * het nieuwe formaat `sb_secret_...`, dat geen JWT is.
///
/// Alleen op de JWT controleren leek veiliger, maar zou een geldige sleutel van
/// het nieuwe soort botweg weigeren met "geen regel die op een JWT lijkt" -- een
/// foutmelding die naar de verkeerde kant wijst.
final serviceRoleKeyPattern = RegExp(
  r'^(?:[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'
  r'|sb_secret_[A-Za-z0-9_-]+)$',
);

/// Leest de sleutel uit -- eerst `--key`, dan de omgeving, dan het
/// standaardbestand. Geeft null als hij nergens staat of nergens op lijkt.
///
/// **Waarom hier een vormcontrole staat.** De eerste versie gaf de ruwe
/// bestandsinhoud rechtstreeks door aan een HTTP-header. Stond er iets anders
/// in dan een sleutel -- op 2026-09-19 was dat de commandoregel die per ongeluk
/// was meegeplakt -- dan gooide Dart een `FormatException` met *de volledige
/// waarde erin*. Daarmee lekte een service-role sleutel naar de uitvoer, en
/// die moest ingetrokken worden. Een sleutel hoort nooit in een foutmelding te
/// kunnen belanden.
///
/// Vandaar twee dingen: er wordt gezocht naar de eerste regel die op een JWT
/// lijkt (zodat een meegeplakte regel ervoor of erna niets breekt), en wat er
/// niet op lijkt wordt geweigerd zónder de inhoud te tonen.
String? readServiceRoleKey(List<String> args) {
  final fromArg = stringArg(args, '--key');

  if (fromArg == null) {
    final fromEnv = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return firstKey(fromEnv);
    }
  }

  final file = File(fromArg ?? defaultServiceRoleKeyPath);
  if (!file.existsSync()) return null;
  return firstKey(file.readAsStringSync());
}

/// De eerste regel die de vorm van een sleutel heeft, of null.
String? firstKey(String raw) {
  for (final line in raw.split('\n')) {
    final candidate = line.trim();
    if (serviceRoleKeyPattern.hasMatch(candidate)) return candidate;
  }
  return null;
}

/// De hulptekst als er geen bruikbare sleutel is. Noemt waar gezocht is en hoe
/// je hem neerzet, maar nooit wat er wél in het bestand stond.
void printMissingKeyHelp() {
  stderr.writeln('Geen bruikbare service-role sleutel gevonden.');
  stderr.writeln('');
  stderr.writeln('Als het bestand wél bestaat: er staat geen regel in die de');
  stderr.writeln(
    'vorm van een sleutel heeft (JWT of sb_secret_...). De inhoud',
  );
  stderr.writeln('wordt met opzet niet getoond.');
  stderr.writeln('');
  stderr.writeln('Gezocht in:');
  stderr.writeln('  SUPABASE_SERVICE_ROLE_KEY (omgevingsvariabele)');
  stderr.writeln('  $defaultServiceRoleKeyPath');
  stderr.writeln('');
  stderr.writeln('De sleutel staat in Supabase > Project Settings > API >');
  stderr.writeln('service_role. Zo zet je hem neer zonder dat hij in je');
  stderr.writeln('shell-history belandt:');
  stderr.writeln('');
  stderr.writeln('  mkdir -p ~/.config/ridewindow');
  stderr.writeln(
    '  (umask 077; cat > ~/.config/ridewindow/supabase-service-role.key)',
  );
  stderr.writeln('  <plak de sleutel, Enter, Ctrl-D>');
}

/// De waarde na [flag] als geheel getal, of null.
int? intArg(List<String> args, String flag) {
  final v = stringArg(args, flag);
  return v == null ? null : int.tryParse(v);
}

/// De waarde na [flag], of null als de vlag (of zijn waarde) ontbreekt.
String? stringArg(List<String> args, String flag) {
  final i = args.indexOf(flag);
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}
