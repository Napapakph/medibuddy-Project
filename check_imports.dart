import 'dart:io';

void main() async {
  final servicesDir =
      Directory('c:/Users/alice/medibuddy-Project/lib/services');
  final libDir = Directory('c:/Users/alice/medibuddy-Project/lib');

  final serviceFiles = servicesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.uri.pathSegments.last)
      .toList();

  final allDartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final usage = <String, List<String>>{};
  for (final sf in serviceFiles) {
    usage[sf] = [];
  }

  for (final file in allDartFiles) {
    try {
      final content = file.readAsStringSync();
      final currentFile = file.uri.pathSegments.last;

      for (final sf in serviceFiles) {
        if (currentFile != sf) {
          if (content.contains(sf)) {
            usage[sf]!.add(file.path);
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  print('--- Usage Report Custom ---');
  for (final sf in serviceFiles) {
    print('\$sf: \${usage[sf]!.length} references');
    if (usage[sf]!.isEmpty) {
      print('  -> NOT USED');
    }
    for (final ref in usage[sf]!) {
      print('  - \$ref');
    }
  }
}
