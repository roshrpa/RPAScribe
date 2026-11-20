import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

Future<String> transcribeAudio(String path) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$serverUrl/transcribe'),
  )
    ..headers['x-app-token'] = appToken
    ..files.add(await http.MultipartFile.fromPath('audio', path));

  final streamed = await request.send().timeout(const Duration(minutes: 10));
  final response = await http.Response.fromStream(streamed);
  if (response.statusCode != 200) {
    throw Exception('Server returned ${response.statusCode}');
  }
  final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  return (body['text'] as String?)?.trim() ?? '';
}
