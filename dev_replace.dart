import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('MaterialPageRoute')) {
      content = content.replaceAll('MaterialPageRoute', 'AppPageRoute');
      
      // Add import if not exists
      if (!content.contains('app_page_route.dart')) {
        // Find the last import line
        final lines = content.split('\n');
        int lastImportIndex = -1;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('import ')) {
            lastImportIndex = i;
          }
        }
        
        if (lastImportIndex != -1) {
          lines.insert(lastImportIndex + 1, "import 'package:safi/core/router/app_page_route.dart';");
          content = lines.join('\n');
        } else {
          content = "import 'package:safi/core/router/app_page_route.dart';\n" + content;
        }
      }
      
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
