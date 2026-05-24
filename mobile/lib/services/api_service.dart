import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Override with:
  // flutter run --dart-define=API_BASE_URL=http://YOUR_IP:5000/api
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Physical device on local network: use the host machine's LAN IP.
  static String get _lanIp => '192.168.1.4';

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://localhost:5000/api';

    // For Android, 10.0.2.2 is used for the Emulator.
    // For Physical devices, you MUST use your computer's LAN IP.
    // Ensure your computer and phone are on the SAME Wi-Fi.

    // Toggle this based on your testing device:
    // true = Emulator/Simulator, false = Physical Device
    const bool isEmulator = false;

    if (isEmulator) {
      return Platform.isAndroid
          ? 'http://10.0.2.2:5000/api'
          : 'http://localhost:5000/api';
    }

    // Use machine's LAN IP for physical device
    return 'http://$_lanIp:5000/api';
  }

  static Uri _buildUri(String endpoint, {bool disableCache = false}) {
    final uri = Uri.parse('$baseUrl$endpoint');
    if (!disableCache) return uri;

    final queryParameters = Map<String, String>.from(uri.queryParameters);
    queryParameters['_ts'] = DateTime.now().millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: queryParameters);
  }

  // Sanitize outgoing JSON bodies:
  // - remove client-provided timestamp fields (`createdAt`, `updatedAt`)
  // - convert MongoDB Extended JSON like {$date: '...'} to ISO strings
  // - convert DateTime to ISO strings
  static dynamic _sanitizeValue(dynamic v) {
    if (v == null) return null;

    if (v is DateTime) {
      return v.toUtc().toIso8601String();
    }

    if (v is Map) {
      // treat Map with single $date specially
      if (v.length == 1 && v.containsKey(r'$date')) {
        final dv = v[r'$date'];
        try {
          if (dv is String) return DateTime.parse(dv).toUtc().toIso8601String();
          if (dv is num) return DateTime.fromMillisecondsSinceEpoch(dv.toInt()).toUtc().toIso8601String();
        } catch (_) {
          return dv;
        }
      }

      final out = <String, dynamic>{};
      v.forEach((key, val) {
        if (key == 'createdAt' || key == 'updatedAt') return; // strip timestamps from client
        out['$key'] = _sanitizeValue(val);
      });
      return out;
    }

    if (v is List) return v.map(_sanitizeValue).toList();

    return v;
  }

  static dynamic _sanitizeBody(Object? body) {
    if (body == null) return null;
    return _sanitizeValue(body);
  }

  static Map<String, String> _defaultHeaders(
      {String? token, bool disableCache = false}) {
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      if (disableCache) 'Cache-Control': 'no-cache, no-store, must-revalidate',
      if (disableCache) 'Pragma': 'no-cache',
      if (disableCache) 'Expires': '0',
    };
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Object body,
  ) async {
    try {
      final url = '$baseUrl$endpoint';
      print('DEBUG: Calling API -> $url');
      final sanitized = _sanitizeBody(body);
      try {
        print('DEBUG: POST $url payload -> ${jsonEncode(sanitized)}');
      } catch (_) {}
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(sanitized),
      );

      try {
        print('DEBUG: POST response ${response.statusCode} -> ${response.body}');
      } catch (_) {}

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> postWithAuth(
    String endpoint,
    Object body,
    String token,
  ) async {
    try {
      final sanitized = _sanitizeBody(body);
      try {
        print('DEBUG: POST $baseUrl$endpoint payload -> ${jsonEncode(sanitized)}');
      } catch (_) {}
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(sanitized),
      );

      try {
        print('DEBUG: POST ${endpoint} response ${response.statusCode} -> ${response.body}');
      } catch (_) {}

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> patchWithAuth(
    String endpoint,
    Object body,
    String token,
  ) async {
    try {
      final sanitized = _sanitizeBody(body);
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(sanitized),
      );

      try {
        print('DEBUG: PATCH ${endpoint} response ${response.statusCode} -> ${response.body}');
      } catch (_) {}

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> putWithAuth(
    String endpoint,
    Object body,
    String token,
  ) async {
    try {
      final sanitized = _sanitizeBody(body);
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(sanitized),
      );

      try {
        print('DEBUG: PUT ${endpoint} response ${response.statusCode} -> ${response.body}');
      } catch (_) {}

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint,
    String token,
  ) async {
    try {
      final disableCache = kIsWeb;
      final response = await http.get(
        _buildUri(endpoint, disableCache: disableCache),
        headers: _defaultHeaders(token: token, disableCache: disableCache),
      );

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPublic(String endpoint) async {
    try {
      final disableCache = kIsWeb;
      final response = await http.get(
        _buildUri(endpoint, disableCache: disableCache),
        headers: _defaultHeaders(disableCache: disableCache),
      );

      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: API Error -> $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : {'data': decoded};
    } catch (_) {
      data = {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Server error: ${response.statusCode}',
      };
    }
  }

  static Future<Map<String, dynamic>> getPublicMentors() async {
    return getPublic('/mentors/public');
  }

  static Future<Map<String, dynamic>> getPublicMentorSlots({
    required String mentorId,
    required String date,
    required int durationMinutes,
  }) async {
    final endpoint =
        '/mentors/public/$mentorId/available-slots?date=$date&durationMinutes=$durationMinutes';
    return getPublic(endpoint);
  }

  static Future<Map<String, dynamic>> createSessionBooking({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    return postWithAuth('/mentor-sessions', payload, token);
  }

  static Future<Map<String, dynamic>> createSessionFawryCheckout({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    return postWithAuth('/mentor-sessions/fawry-checkout', payload, token);
  }

  static Future<Map<String, dynamic>> getPaymentStatus({
    required String token,
    required String transactionId,
  }) async {
    return get('/payments/status/$transactionId', token);
  }

  static Future<Map<String, dynamic>> getSessionTimer({
    required String token,
    required String sessionId,
  }) async {
    return get('/mentor-sessions/$sessionId/timer', token);
  }

  static Future<Map<String, dynamic>> joinSession({
    required String token,
    required String sessionId,
  }) async {
    return postWithAuth('/mentor-sessions/$sessionId/join', {}, token);
  }

  static Future<Map<String, dynamic>> submitSessionFeedback({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    return postWithAuth('/session-feedback', payload, token);
  }

  static Future<Map<String, dynamic>> getSessionFeedback({
    required String token,
    required String sessionId,
  }) async {
    return get('/session-feedback/session/$sessionId', token);
  }
}
