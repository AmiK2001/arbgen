import 'dart:convert';
import 'dart:io';

class Config {
  final String csvLink;
  final String outputFolder;
  final List<String> locales;

  Config({
    required this.csvLink,
    required this.locales,
    required this.outputFolder,
  });
}

Future<Config?> tryParseConfig(String content) async {
  try {
    final json = jsonDecode(content);
    final config = Config(
        csvLink: json["csvLink"] as String,
        outputFolder: json["outputFolder"] as String,
        locales: (json["locales"] as List).map((it) => it.toString()).toList());
    return config;
  } catch (e) {
    print("Can't parse config!");
    print(e);
    return null;
  }
}

Future<Config?> readConfig() async {
  var directory = Directory.current;
  final filename = "config.json";
  var file = File("${directory.path}/$filename");
  return file.readAsString().then(tryParseConfig);
}
