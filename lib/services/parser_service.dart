import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lesson.dart';
import '../models/site_data.dart';

// Расписание и звонки парсятся в GitHub Actions (doc + OCR скана PDF)
// и публикуются как JSON; приложение только читает легкие файлы.
class ParserService {
  final http.Client _client;

  ParserService({http.Client? client}) : _client = client ?? http.Client();

  static const _base =
      'https://raw.githubusercontent.com/NeoFarelly/college-schedule/main/data/';

  bool get isMock => false;

  Future<ScheduleManifest> fetchManifest() async =>
      ScheduleManifest.fromJson(await _getJson('index.json'));

  Future<List<Lesson>> fetchDay(String date) async {
    final json = await _getJson('day-$date.json');
    return (json['lessons'] as List<dynamic>)
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SiteBells> fetchBells() async =>
      SiteBells.fromJson(await _getJson('bells.json'));

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client.get(Uri.parse('$_base$path'));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: $path');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}