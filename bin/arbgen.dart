import 'dart:convert';
import 'dart:io';
import 'package:arbgen/data/config.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

Future<String> getCsvData(String link) async {
  // Fetch the CSV data
  return http
      .get(Uri.parse(link))
      .then((response) => response.bodyBytes)
      .then(utf8.decode);
}

List<String> getLocalesList(String csv) {
  final rows = const CsvToListConverter().convert(csv);
  final keys = rows.first;
  return keys.skip(2).map((it) => it.toString()).toList();
}

Map<String, List<String>> parseCsv(String csv) {
  final rows = const CsvToListConverter().convert(csv);
  final keys = rows.first;

  // Create a map to store the values for each key
  final result = <String, List<String>>{};
  for (String key in keys) {
    result[key] = [];
  }

  // Extract the values for each key from the remaining lines
  for (final line in rows.skip(1)) {
    for (int j = 0; j < keys.length; j++) {
      result[keys[j]]?.add(line[j] == '' ? '' : line[j]);
    }
  }

  return result;
}

void main() async {
  final config = await readConfig();

  if (config == null) return;

  print("Fetching data...");
  final csvText = await getCsvData(config.csvLink);

  print("Parsing data...");
  final response = parseCsv(csvText);

  final locales = getLocalesList(csvText);

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
  String getArbContent(String locale) {
    final lastIndex = rows.length - 1;
    return rows.mapIndexed((index, row) {
      final key = row['key'] as String;
      final description = (row['description'] ?? "").replaceAll("\n", r"\n");
      final text = (row[locale] ?? "").replaceAll("\n", r"\n");

      if (text.isEmpty) return "";

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
}${lastIndex != index ? "," : ""}''';
    }).join('\n');
  }

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
