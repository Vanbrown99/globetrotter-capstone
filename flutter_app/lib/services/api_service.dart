import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:globetrotter_flutter/models/destination.dart';
import 'package:globetrotter_flutter/models/itinerary.dart';
import 'package:globetrotter_flutter/services/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ---------------------------------------------------------------------
  // Destinations
  // ---------------------------------------------------------------------

  static Future<List<Destination>> getDestinations({String query = ''}) async {
    final uri = query.isEmpty
        ? Uri.parse('$baseUrl/destinations')
        : Uri.parse('$baseUrl/destinations').replace(
            queryParameters: {'q': query},
          );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load destinations');
    }
    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((json) => Destination.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Recommendations (requires auth)
  // ---------------------------------------------------------------------

  static Future<List<Destination>> getRecommendations(
    String token, {
    int limit = 6,
  }) async {
    final uri = Uri.parse('$baseUrl/recommendations')
        .replace(queryParameters: {'limit': '$limit'});
    final response = await http.get(uri, headers: _authHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Failed to load recommendations');
    }
    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((json) => Destination.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Itineraries (requires auth)
  // ---------------------------------------------------------------------

  static Future<List<Itinerary>> getItineraries(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/itineraries'),
      headers: _authHeaders(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load itineraries');
    }
    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((json) => Itinerary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<Itinerary> createItinerary(
    String token, {
    required String title,
    required List<String> destinations,
    String startDate = '',
    String endDate = '',
    String notes = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/itineraries'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'title': title,
        'destinations': destinations,
        'start_date': startDate,
        'end_date': endDate,
        'notes': notes,
      }),
    );
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] as String? ?? 'Failed to create itinerary');
    }
    return Itinerary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Current user profile (requires auth)
  // ---------------------------------------------------------------------

  static Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: _authHeaders(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load profile');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
