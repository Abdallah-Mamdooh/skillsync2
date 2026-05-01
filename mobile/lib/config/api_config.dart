/// API Configuration for SkillSync
///
/// Update the baseUrl to match your backend server address.
///
/// For development:
/// - iOS Simulator: Use 'http://localhost:5001'
/// - Physical Device: Use your computer's IP address, e.g., 'http://192.168.1.X:5000'
///
/// The Flask backend must be running before making API calls.
/// To start the backend:
///   cd resume_analyzer
///   python app.py
///
/// Note: Port 5000 is used by Node.js app, so Flask runs on 5001.
class ApiConfig {
  /// Base URL for the Flask backend
  static const String baseUrl = 'http://192.168.1.4:5000';

  /// API endpoints
  /// Mobile should call the Node API which mounts CV analysis under `/api/cv-analysis`.
  static const String analyzeEndpoint = '$baseUrl/api/cv-analysis/analyze';
  static const String healthEndpoint = '$baseUrl/health';

  /// Connection timeout in seconds
  static const int connectionTimeout = 30;

  /// Read timeout in seconds
  static const int readTimeout = 60;
}
