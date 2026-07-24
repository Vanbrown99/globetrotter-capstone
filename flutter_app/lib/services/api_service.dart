import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:globetrotter_flutter/models/destination.dart';
import 'package:globetrotter_flutter/services/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<List<Destination>> getDestinations() async {
    final response = await http.get(Uri.parse('$baseUrl/destinations'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load destinations');
    }
    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((json) => Destination.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
