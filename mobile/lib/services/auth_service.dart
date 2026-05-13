import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_service.dart';
import '../utils/role_utils.dart';

class AuthService {
  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
    String? cvUrl,
    String? linkedinUrl,
    String? additionalInfo,
    num? baseRate,
  }) async {
    final includeMentorFields = isMentorRole(role);

    if (!includeMentorFields) {
      return ApiService.post('/auth/signup', {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'role': role,
      });
    }

    final rawCvUrl = cvUrl?.trim() ?? '';
    final cvUri = Uri.tryParse(rawCvUrl);
    if (rawCvUrl.isEmpty || cvUri == null || !cvUri.hasScheme) {
      return {
        'success': false,
        'message': 'Please provide a valid direct CV file link.',
      };
    }

    try {
      final cvResponse = await http.get(cvUri);
      if (cvResponse.statusCode < 200 || cvResponse.statusCode >= 300) {
        return {
          'success': false,
          'message':
              'Could not download the CV from the provided link. Use a direct PDF or DOCX file link.',
        };
      }

      final fileName = _extractFileName(cvUri);
      final mediaType = _detectCvMediaType(
        fileName: fileName,
        contentTypeHeader: cvResponse.headers['content-type'],
      );

      if (mediaType == null) {
        return {
          'success': false,
          'message': 'CV link must point to a PDF or DOCX file.',
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/auth/signup'),
      );

      request.fields.addAll({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'role': role,
        'linkedinUrl': linkedinUrl ?? '',
        'payoutAccountInfo': additionalInfo ?? '',
        'proposedHourlyRate': '${baseRate ?? ''}',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'cv',
          cvResponse.bodyBytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      try {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': error['message'] ?? 'Server error',
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message':
            'Could not fetch the CV file from the provided link. Use a direct PDF or DOCX file link.',
      };
    }
  }

  static String _extractFileName(Uri uri) {
    if (uri.pathSegments.isEmpty || uri.pathSegments.last.trim().isEmpty) {
      return 'cv.pdf';
    }
    return uri.pathSegments.last.trim();
  }

  static MediaType? _detectCvMediaType({
    required String fileName,
    String? contentTypeHeader,
  }) {
    final lowerName = fileName.toLowerCase();
    final header = (contentTypeHeader ?? '').toLowerCase();

    if (lowerName.endsWith('.pdf') || header.contains('application/pdf')) {
      return MediaType('application', 'pdf');
    }

    if (lowerName.endsWith('.docx') ||
        header.contains(
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        )) {
      return MediaType(
        'application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    }

    return null;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> googleLogin({
    required String email,
  }) async {
    return ApiService.post('/auth/google-login', {
      'email': email,
    });
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return ApiService.post('/auth/forgot-password', {
      'email': email,
    });
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return ApiService.post('/auth/reset-password/$token', {
      'newPassword': newPassword,
    });
  }

  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    return ApiService.postWithAuth('/auth/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    }, token);
  }

  static Future<Map<String, dynamic>> getCurrentUser({
    required String token,
  }) async {
    return ApiService.get('/auth/me', token);
  }
}
