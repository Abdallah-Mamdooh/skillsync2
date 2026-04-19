import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'payment_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String mentorProfileId;
  final String mentorName;
  final String method;
  final int durationMinutes;
  final String scheduledDate;
  final String scheduledStartTime;
  final double estimatedPrice;

  const PaymentScreen({
    super.key,
    required this.mentorProfileId,
    required this.mentorName,
    required this.method,
    required this.durationMinutes,
    required this.scheduledDate,
    required this.scheduledStartTime,
    required this.estimatedPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  double _walletBalance = 0;
  String _currency = 'EGP';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWallet());
  }

  Future<void> _loadWallet() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    final response = await ApiService.get('/payments/wallet', token);
    if (!mounted) return;
    final wallet = response['data']?['wallet'];
    setState(() {
      _walletBalance = wallet is Map && wallet['availableBalance'] is num
          ? (wallet['availableBalance'] as num).toDouble()
          : 0;
      _currency = wallet is Map ? wallet['currency']?.toString() ?? 'EGP' : 'EGP';
      _isLoading = false;
    });
  }

  Future<void> _depositSmallAmount() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    await ApiService.postWithAuth(
      '/payments/wallet/deposit',
      {'amount': 100, 'notes': 'Top-up from mobile app'},
      token,
    );
    await _loadWallet();
  }

  Future<void> _confirmBooking() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final checkoutResponse = await ApiService.postWithAuth(
      '/mentor-sessions/fawry-checkout',
      {
        'mentorProfileId': widget.mentorProfileId,
        'method': widget.method,
        'durationMinutes': widget.durationMinutes,
        'scheduledDate': widget.scheduledDate,
        'scheduledStartTime': widget.scheduledStartTime,
      },
      token,
    );

    bool success = checkoutResponse['success'] == true;
    String message = checkoutResponse['message']?.toString() ?? '';

    if (success) {
      final checkoutData = checkoutResponse['data']?['checkout'];
      String transactionId = '';
      if (checkoutData is Map<String, dynamic>) {
        transactionId = checkoutData['transactionId']?.toString() ??
            checkoutData['id']?.toString() ??
            '';
      }
      if (transactionId.isNotEmpty) {
        final verifyResponse =
            await ApiService.get('/payments/fawry/status/$transactionId', token);
        success = verifyResponse['success'] == true;
        if (message.isEmpty) {
          message =
              verifyResponse['message']?.toString() ?? 'Payment status checked.';
        }
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen(
          isSuccess: success,
          message: message,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mentor: ${widget.mentorName}'),
                  Text('Session: ${widget.method} • ${widget.durationMinutes} min'),
                  Text('Date: ${widget.scheduledDate} ${widget.scheduledStartTime}'),
                  const SizedBox(height: 16),
                  Text('Wallet Balance: $_walletBalance $_currency'),
                  Text('Estimated Price: ${widget.estimatedPrice} $_currency'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _depositSmallAmount,
                    child: const Text('Deposit 100 EGP'),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _confirmBooking,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Confirm and Pay'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
