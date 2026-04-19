import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/resume_analysis.dart';
import '../config/api_config.dart';

/// Service to communicate with the Flask resume analyzer backend
class ResumeAnalyzerService {
  /// Analyze a resume file
  ///
  /// [filePath] - Absolute path to the resume file (PDF or DOCX)
  /// [jobDescription] - Optional job description text for matching
  /// [careerField] - Optional career field override
  static Future<ResumeAnalysis> analyzeResume({
    required String filePath,
    String? jobDescription,
    String? careerField,
  }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final request =
          http.MultipartRequest('POST', Uri.parse(ApiConfig.analyzeEndpoint));

      // Add file
      final fileBytes = await file.readAsBytes();
      final fileName = _extractFileName(filePath);
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType(
            'application',
            _getFileExtension(fileName) == 'pdf'
                ? 'pdf'
                : 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
      );
      request.files.add(multipartFile);

      // Add optional fields
      if (jobDescription != null && jobDescription.isNotEmpty) {
        request.fields['job_description'] = jobDescription;
      }
      if (careerField != null && careerField.isNotEmpty) {
        request.fields['field'] = careerField;
      }

      // Attach auth token if available (stored by AuthProvider)
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorBody = _parseErrorResponse(response.body);
        throw Exception('Analysis failed: $errorBody');
      }

      final jsonData = _parseJsonResponse(response.body);
      
      // The backend wraps the response in a { "success": true, "data": { ... } } structure
      if (jsonData.containsKey('data') && jsonData['data'] is Map<String, dynamic>) {
        return ResumeAnalysis.fromJson(jsonData['data'] as Map<String, dynamic>);
      }
      
      return ResumeAnalysis.fromJson(jsonData);
    } on SocketException {
      throw Exception(
          'Cannot connect to server. Make sure the Flask backend is running on ${ApiConfig.baseUrl}');
    } on http.ClientException {
      throw Exception('Network error. Please check your connection.');
    } on TimeoutException {
      throw Exception('Request timed out. The server may be busy.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  /// Health check endpoint
  static Future<bool> isServerHealthy() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.healthEndpoint),
          )
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  static String _getFileExtension(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'pdf';
    } else if (fileName.toLowerCase().endsWith('.docx')) {
      return 'docx';
    } else if (fileName.toLowerCase().endsWith('.doc')) {
      return 'doc';
    }
    return 'pdf';
  }

  static String _extractFileName(String filePath) {
    // Handle both Unix and Windows paths
    if (filePath.contains('\\')) {
      return filePath.split('\\').last;
    }
    return filePath.split('/').last;
  }

  static Map<String, dynamic> _parseJsonResponse(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid response from server');
    }
  }

  static String _parseErrorResponse(String body) {
    try {
      final jsonData = jsonDecode(body) as Map<String, dynamic>;
      return jsonData['error'] ?? body;
    } catch (e) {
      return body;
    }
  }
}
