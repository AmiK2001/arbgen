import 'dart:convert';
import 'dart:io';
import 'package:arbgen/data/config.dart';
import 'package:http/http.dart' as http;

Future<String> getCsvData(String link) async {
  // Fetch the CSV data
  return http
      .get(Uri.parse(link))
      .then((response) => response.bodyBytes)
      .then(utf8.decode);
}

Map<String, List<String>> parseCsv(String csv) {
  // Split the input string into lines
  List<String> lines = csv.split('\n');

  // Extract the keys from the first line
  List<String> keys = lines[0].split(',');

  // Create a map to store the values for each key
  Map<String, List<String>> result = {};
  for (String key in keys) {
    result[key] = [];
  }

  // Extract the values for each key from the remaining lines
  for (int i = 1; i < lines.length; i++) {
    List<String> values = lines[i].split(',');
    for (int j = 0; j < keys.length; j++) {
      result[keys[j]]?.add(values[j] == '' ? '' : values[j]);
    }
  }

  return result;
}

void main() async {
  final config = await readConfig();

  if (config == null) return;

  final locales = config.locales;

  print("Fetching data...");
  final csvText = await getCsvData(config.csvLink);

  print("Parsing data...");
  final response = parseCsv(csvText);

  final keysLength = response["key"]?.length ?? 0;

  // Parse the data from the response
  final rows = Iterable.generate(keysLength).map((index) {
    final map = {
      'key': response["key"]?[index],
      'description': response["description"]?[index] ?? "",
    };

    for (var locale in locales) {
      final translation = response[locale]?[index] ?? "";
      map.addAll({
        locale: translation,
      });
    }

    return map;
  }).toList();

  // Generate the .arb file content
  String getArbContent(String locale) => rows.map((row) {
        final key = row['key'] as String;
        final description = row['description'] ?? "";
        final text = row[locale] ?? "";

        //TODO Check if the key represents a plural
//     if (key.startsWith('@')) {
//       final pluralKey = key.substring(1);
//       return '''
// "$pluralKey": {
//   "description": "$description",
//   "zero": "$en",
//   "one": "$ru"
// }''';
//     }

        // Check if the value contains placeholders
        final placeholders = <String, Object>{};
        final pattern = RegExp(r'\{(.+?)\}');
        final matches = pattern.allMatches(text);
        for (final match in matches) {
          final placeholder = match.group(1);

          if (placeholder == null) continue;
          placeholders[placeholder] = {};
        }

        // Generate the .arb entry

        final encodedPlaceholders = jsonEncode(placeholders);

        return '''
"$key": "$text",
"@$key": {
  "placeholders": $encodedPlaceholders,
  "description": "$description"
},''';
      }).join('\n');

  // Make final .arb context for single file
  String arb(String locale) {
    return "{ ${getArbContent(locale)} }";
  }

  // Write .arb files to the folder
  var directory = await Directory(config.outputFolder).create(recursive: true);

  for (var locale in locales) {
    final content = arb(locale);
    final filename = "$locale.arb";
    var file = File("${directory.path}/$filename");
    print("Writing $filename...");
    await file.writeAsString(content);
  }

  print("Localizations generation completed");
}
