/// api_service.dart
/// ----------------
/// This file handles communication between Flutter and the Flask backend.
/// It uses the HTTP package to send requests and parse JSON responses.

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/crop_data.dart';
import '../models/chat_message.dart';

class ApiService {
  /// Determines the correct backend address based on where the app is running:
  /// - Web / Windows Desktop: http://127.0.0.1:5000
  /// - Android Emulator: http://10.0.2.2:5000 (special Android alias for PC localhost)
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000';
      }
    } catch (_) {
      // Fallback for desktop or non-Android platforms
    }
    return 'http://127.0.0.1:5000';
  }

  final String baseUrl;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  /// Sends agricultural data to Flask and returns a list of crop recommendations
  Future<Map<String, dynamic>> getRecommendations(CropInputData data) async {
    final url = Uri.parse('$baseUrl/api/recommend');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Successful recommendation
        final List<dynamic> recsJson = responseData['recommendations'] ?? [];
        final items = recsJson.map((item) => RecommendationItem.fromJson(item)).toList();

        return {
          'success': true,
          'message': responseData['message'] ?? 'Recommendations ready!',
          'items': items,
        };
      } else {
        // Backend validation or error response (HTTP 400 or 500)
        return {
          'success': false,
          'message': responseData['message'] ?? 'Server error occurred (Code ${response.statusCode}).',
          'items': <RecommendationItem>[],
        };
      }
    } catch (e) {
      // Network connection error (e.g. Flask is not running)
      return {
        'success': false,
        'message':
            'Could not connect to the backend server at $baseUrl.\n\nPlease ensure your Python Flask server is running (python app.py).',
        'items': <RecommendationItem>[],
      };
    }
  }

  /// Checks if backend server is online
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
