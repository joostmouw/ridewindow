import 'dart:io';

import 'package:test/test.dart';

/// Bouwt de importgraaf op vanaf [entryPath], gevolgd via alle
/// `package:ridewindow/`-imports (project-eigen code), recursief.
///
/// Externe package-imports (`package:http`, `package:drift_flutter`, enz.)
/// worden niet naar hun bronbestand gevolgd — alleen de eigen importregel van
/// elk bereikbaar project-bestand telt mee.
Set<String> _buildImportGraph(String entryPath) {
  final importPattern = RegExp("""import\\s+['"]([^'"]+)['"]""");
  final visited = <String>{};
  final toVisit = <String>[entryPath];

  while (toVisit.isNotEmpty) {
    final path = toVisit.removeLast();
    if (visited.contains(path)) continue;
    final file = File(path);
    if (!file.existsSync()) continue;
    visited.add(path);

    final source = file.readAsStringSync();
    for (final match in importPattern.allMatches(source)) {
      final target = match.group(1)!;
      if (!target.startsWith('package:ridewindow/')) continue;
      final relative = target.substring('package:ridewindow/'.length);
      final resolved = 'lib/$relative';
      if (!visited.contains(resolved)) {
        toVisit.add(resolved);
      }
    }
  }

  return visited;
}

void main() {
  test(
    'background_task.dart importgraaf bevat geen supabase (REG-05, D-14)',
    () {
      final reachableFiles = _buildImportGraph('lib/platform/background_task.dart');
      expect(
        reachableFiles,
        isNotEmpty,
        reason: 'lib/platform/background_task.dart moet bestaan en bereikbaar zijn',
      );

      final hits = <String>[];
      for (final path in reachableFiles) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trimLeft();
          if (!trimmed.startsWith('import')) continue;
          if (trimmed.contains('supabase')) {
            hits.add('$path: $trimmed');
          }
        }
      }

      expect(hits, isEmpty, reason: hits.join('\n'));
    },
  );
}
