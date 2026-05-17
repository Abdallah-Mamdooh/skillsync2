import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/group_event_service.dart';
import '../../widgets/bottom_navigation.dart';
import 'payment_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String mentorId;
  final String mentorName;
  final String sessionTime;
  final String sessionDuration;
  final String sessionType;
  final double sessionPrice;
  final String paymentMethod;
  final String scheduledDate;
  final String scheduledStartTime;
  final String timezone;

  // ── Event registration fields ──────────────────────────────────────────
  /// When true, this payment is for an event registration instead of a
  /// mentor session. The [_confirmBooking] method will call the event
  /// registration endpoints instead of session booking.
  final bool isEventRegistration;

  /// The backend eventId, required when [isEventRegistration] is true.
  final String? eventId;

  const PaymentScreen({
    super.key,
    required this.mentorId,
    required this.mentorName,
    required this.sessionTime,
    required this.sessionDuration,
    required this.sessionType,
    required this.sessionPrice,
    required this.paymentMethod,
    required this.scheduledDate,
    required this.scheduledStartTime,
    required this.timezone,
    this.isEventRegistration = false,
    this.eventId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  double _walletBalance = 0;
  String _walletCurrency = 'EGP';
  bool _loadingWallet = true;
  bool _submitting = false;
  bool? _mentorVerified;

  int get _durationMinutes =>
      int.tryParse(widget.sessionDuration.split(' ').first) ?? 30;

  @override
  void initState() {
    super.initState();
    _loadWallet();
    // Only check mentor verification for session bookings (not events)
    if (!widget.isEventRegistration) {
      _loadMentorVerification();
    }
  }

  Future<void> _loadWallet() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final response = await ApiService.get('/payments/wallet', token);
    final wallet = response['data']?['wallet'];
    if (wallet is Map) {
      _walletBalance = ((wallet['availableBalance'] ?? 0) as num).toDouble();
      _walletCurrency = (wallet['currency'] ?? 'EGP').toString();
    }
    if (mounted) setState(() => _loadingWallet = false);
  }

  Future<void> _loadMentorVerification() async {
    final response =
        await ApiService.getPublic('/mentors/public/${widget.mentorId}');
    final data = response['data'];
    if (mounted) {
      setState(() {
        _mentorVerified = data?['isVerified'] == true;
      });
    }
  }

  Future<void> _confirmBooking() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _submitting = true);

    // ── Event registration path ────────────────────────────────────────────
    if (widget.isEventRegistration) {
      await _confirmEventRegistration(token);
      return;
    }

    // ── Mentor session booking path (existing logic) ───────────────────────
    if (_mentorVerified == false) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'This mentor is not yet verified. Please choose a different mentor.'),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (widget.sessionPrice <= 0) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'This mentor has not set a valid session rate. Please choose a different mentor.'),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_walletBalance < widget.sessionPrice) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient wallet balance. '
            'Required: ${widget.sessionPrice.toStringAsFixed(0)} $_walletCurrency, '
            'Available: ${_walletBalance.toStringAsFixed(0)} $_walletCurrency.',
          ),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final payload = {
      'mentorProfileId': widget.mentorId,
      'method': widget.sessionType,
      'durationMinutes': _durationMinutes,
      'scheduledDate': widget.scheduledDate,
      'scheduledStartTime': widget.scheduledStartTime,
      'timezone': widget.timezone,
    };

    if (widget.paymentMethod != 'wallet') {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Fawry payment is not available. Please select SkillSync Wallet.'),
          backgroundColor: Color(0xFFF5A100),
        ),
      );
      return;
    }

    final bookingResponse = await ApiService.createSessionBooking(
      token: token,
      payload: payload,
    );
    final sessionId = bookingResponse['data']?['sessionId']?.toString();

    if (!mounted) return;
    setState(() => _submitting = false);
    final ok = bookingResponse['success'] == true && sessionId != null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmationScreen(
          isSuccess: ok,
          sessionId: sessionId,
          message: ok
              ? 'Session booked successfully.'
              : (bookingResponse['message']?.toString() ?? 'Booking failed.'),
        ),
      ),
    );
  }

  // ── Event registration confirmation ────────────────────────────────────────
  Future<void> _confirmEventRegistration(String token) async {
    final eventId = widget.eventId;
    if (eventId == null || eventId.isEmpty) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event ID is missing. Cannot register.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    if (widget.sessionPrice > 0 && _walletBalance < widget.sessionPrice) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient wallet balance. '
            'Required: ${widget.sessionPrice.toStringAsFixed(0)} $_walletCurrency, '
            'Available: ${_walletBalance.toStringAsFixed(0)} $_walletCurrency.',
          ),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> response;

      if (widget.paymentMethod == 'wallet') {
        response = await GroupEventService.registerForEvent(token, eventId);
      } else {
        response = await GroupEventService.registerForEventWithFawry(
          token,
          eventId,
          {'paymentMethod': widget.paymentMethod},
        );
      }

      if (!mounted) return;
      setState(() => _submitting = false);

      final ok = response['success'] == true;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentConfirmationScreen(
            isSuccess: ok,
            sessionId: response['data']?['registrationId']?.toString(),
            message: ok
                ? 'Event registration successful!'
                : (response['message']?.toString() ?? 'Registration failed.'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration error: $e'),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 20, top: 40, bottom: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF1D5572),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'PAYMENT',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Pay Here',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double remains = _walletBalance - widget.sessionPrice;

    return Scaffold(
      backgroundColor: const Color(0xFF1D5572),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                color: const Color(0xFFF2F4F6),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.isEventRegistration &&
                          _mentorVerified == false) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD32F2F)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFD32F2F), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This mentor is not yet verified by SkillSync. Booking is not available.',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFD32F2F)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!widget.isEventRegistration &&
                          widget.sessionPrice <= 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD32F2F)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFD32F2F), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This mentor has not set a valid session rate.',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFD32F2F)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 16),
                      // ── Wallet Balance Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x3F000000),
                              spreadRadius: 0,
                              offset: Offset(0, 2),
                              blurRadius: 2)
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Balance',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF2E2E2E))),
                                const SizedBox(height: 4),
                                Text(
                                  _loadingWallet
                                      ? 'Loading...'
                                      : '${_walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} $_walletCurrency',
                                  style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E2E2E)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 52,
                            height: 58,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/wallet.png',
                                    width: 26, height: 26),
                                const SizedBox(height: 4),
                                Text('Wallet',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF333333))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Booking Summary Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x1E000000),
                              spreadRadius: 0,
                              offset: Offset(0, 2),
                              blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.isEventRegistration
                              ? 'Event Registration'
                              : 'Booking Summary',
                              style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937))),
                          const SizedBox(height: 16),
                          _summaryRow(
                              widget.isEventRegistration
                                  ? 'Event:'
                                  : 'Mentor:',
                              widget.mentorName),
                          const SizedBox(height: 8),
                          _summaryRow('Time:', widget.sessionTime),
                          const SizedBox(height: 8),
                          _summaryRow('Duration:', widget.sessionDuration),
                          const SizedBox(height: 8),
                          _summaryRow(
                              widget.isEventRegistration
                                  ? 'Type:'
                                  : 'Session type:',
                              widget.sessionType.toUpperCase()),
                          const SizedBox(height: 8),
                          _summaryRow(
                              'Payment:', widget.paymentMethod.toUpperCase()),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFD9D9D9), height: 1),
                          const SizedBox(height: 16),
                          _summaryRow('TOTAL BALANCE:',
                              '${_walletBalance.toStringAsFixed(0)} $_walletCurrency',
                              valueColor: const Color(0xFFF5A100)),
                          const SizedBox(height: 8),
                          _summaryRow('',
                              '-${widget.sessionPrice.toStringAsFixed(0)} $_walletCurrency',
                              valueColor: const Color(0xFFF5A100)),
                          const SizedBox(height: 8),
                          _summaryRow('REMAINS:',
                              '${remains.toStringAsFixed(0)} $_walletCurrency',
                              valueColor: const Color(0xFFF5A100)),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFD9D9D9), height: 1),
                          const SizedBox(height: 16),
                          _summaryRow('TOTAL:',
                              '${widget.sessionPrice.toStringAsFixed(0)} $_walletCurrency',
                              labelBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Confirm / Cancel ──
                    Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_submitting) return;
                              _confirmBooking();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D5572),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6))),
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Confirm',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext dialogContext) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    backgroundColor: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 28),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Red circle with ! icon
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFFEBEB),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.priority_high_rounded,
                                              color: Color(0xFFD32F2F),
                                              size: 36,
                                            ),
                                          ),
                                          const SizedBox(height: 14),

                                          // "Warning!" title
                                          Text(
                                            'Warning!',
                                            style: GoogleFonts.inter(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFD32F2F),
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Subtitle message
                                          Text(
                                            'If you cancel the payment process,\nthe information you entered will be deleted',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: const Color(0xFFD32F2F),
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Yes,cancel + NO buttons
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 44,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                          dialogContext);
                                                      Navigator.pop(context);
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF1D5572),
                                                      elevation: 0,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Yes,cancel',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: SizedBox(
                                                  height: 46,
                                                  child: ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            dialogContext),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFFE0E0E0),
                                                      elevation: 0,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'NO',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                            0xFF555555),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD9D9D9),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                elevation: 0),
                            child: Text('Cancel',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1D5572))),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          const BottomNavigation(selectedIndex: BottomNavIndex.none),
    );
  }

  Widget _summaryRow(String label, String value,
      {Color valueColor = const Color(0xFF1D5572), bool labelBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (label.isNotEmpty)
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: labelBold ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFF2E2E2E)))
        else
          const SizedBox(),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500, color: valueColor)),
      ],
    );
  }
}
