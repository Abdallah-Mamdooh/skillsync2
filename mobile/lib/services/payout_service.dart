import 'api_service.dart';

class PayoutService {
  /// Fetches the mentor's payout methods
  /// Backend: GET /api/payout/methods
  static Future<Map<String, dynamic>> getMyPayoutMethods(String token) async {
    return ApiService.get('/payouts/methods', token);
  }

  /// Adds a new payout method
  /// Backend: POST /api/payout/methods
  static Future<Map<String, dynamic>> addPayoutMethod(
    String token,
    Map<String, dynamic> data,
  ) async {
    return ApiService.postWithAuth('/payouts/methods', data, token);
  }

  /// Fetches the mentor's withdrawal requests history
  /// Backend: GET /api/payout/withdrawals
  static Future<Map<String, dynamic>> getMyWithdrawals(String token) async {
    return ApiService.get('/payouts/withdrawals/me', token);
  }

  /// Requests a withdrawal
  /// Backend: POST /api/payout/withdrawals
  static Future<Map<String, dynamic>> requestWithdrawal(
    String token,
    Map<String, dynamic> data,
  ) async {
    return ApiService.postWithAuth('/payouts/withdrawals', data, token);
  }

  /// Cancels a withdrawal request
  /// Backend: POST /api/payout/withdrawals/:id/cancel
  static Future<Map<String, dynamic>> cancelWithdrawal(
    String token,
    String withdrawalId,
  ) async {
    return ApiService.postWithAuth(
      '/payouts/withdrawals/$withdrawalId/cancel',
      {},
      token,
    );
  }

  /// Fetches mentor's balance and earnings summary
  /// Backend: GET /api/mentor/me (includes balance in profile)
  /// Note: If a dedicated balance endpoint exists, use it instead
  static Future<Map<String, dynamic>> getBalance(String token) async {
    final earningsResponse = await ApiService.get('/payments/mentor/earnings', token);
    if (earningsResponse['success'] == true) {
      final data = earningsResponse['data'] ?? <String, dynamic>{};
      return {
        'success': true,
        'data': {
          'available': data['availableEarnings'] ?? 0,
          'pending': data['pendingEarnings'] ?? 0,
          'totalEarned': data['totalEarned'] ?? 0,
          'currency': data['currency'] ?? 'EGP',
        },
      };
    }
    return earningsResponse;
  }
}
