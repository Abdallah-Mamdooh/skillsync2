import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_navigation.dart';
import 'student_homescreen.dart';
import 'profile_screen.dart';
import 'payment_confirmation_screen.dart';

class PaymentScreen extends StatelessWidget {
  final String mentorName;
  final String sessionTime;
  final String sessionDuration;
  final String sessionType;
  final double sessionPrice;
  final double walletBalance;

  const PaymentScreen({
    super.key,
    required this.mentorName,
    required this.sessionTime,
    required this.sessionDuration,
    required this.sessionType,
    required this.sessionPrice,
    required this.walletBalance,
  });

  @override
  Widget build(BuildContext context) {
    final double remains = walletBalance - sessionPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PAYMENT', style: GoogleFonts.inter(fontSize: 25, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                          Text('Pay Here', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1F2937))),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // ── Wallet Balance Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Color(0x3F000000), spreadRadius: 0, offset: Offset(0, 2), blurRadius: 2)],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Balance', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF2E2E2E))),
                                const SizedBox(height: 4),
                                Text(
                                  '${walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} EGP',
                                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2E2E2E)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 52, height: 58,
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/wallet.png', width: 26, height: 26),
                                const SizedBox(height: 4),
                                Text('Wallet', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF333333))),
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
                        boxShadow: const [BoxShadow(color: Color(0x1E000000), spreadRadius: 0, offset: Offset(0, 2), blurRadius: 8)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Booking Summary', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                          const SizedBox(height: 16),
                          _summaryRow('Mentor:', mentorName),
                          const SizedBox(height: 8),
                          _summaryRow('Time:', sessionTime),
                          const SizedBox(height: 8),
                          _summaryRow('Duration:', sessionDuration),
                          const SizedBox(height: 8),
                          _summaryRow('Session type:', sessionType),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFD9D9D9), height: 1),
                          const SizedBox(height: 16),
                          _summaryRow('TOTAL BALANCE:', '${walletBalance.toStringAsFixed(0)} EGP', valueColor: const Color(0xFFF5A100)),
                          const SizedBox(height: 8),
                          _summaryRow('', '-${sessionPrice.toStringAsFixed(0)} EGP', valueColor: const Color(0xFFF5A100)),
                          const SizedBox(height: 8),
                          _summaryRow('REMAINS:', '${remains.toStringAsFixed(0)} EGP', valueColor: const Color(0xFFF5A100)),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFD9D9D9), height: 1),
                          const SizedBox(height: 16),
                          _summaryRow('TOTAL:', '${sessionPrice.toStringAsFixed(0)} EGP', labelBold: true),
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
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(color: Color(0xFF1D5572)),
                                ),
                              );

                              // Simulate booking API call (replace with your real logic)
                              await Future.delayed(const Duration(seconds: 2));
                              final bool bookingSuccess = walletBalance >= sessionPrice; // your condition

                              if (context.mounted) Navigator.pop(context); // close loader

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentConfirmationScreen(isSuccess: bookingSuccess),
                                  ),
                                );
                              }
                            },                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D5572), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                            child: Text('Confirm', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
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
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                                                      Navigator.pop(dialogContext);
                                                      Navigator.pop(context);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF1D5572),
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Yes,cancel',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
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
                                                    onPressed: () => Navigator.pop(dialogContext),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFFE0E0E0),
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'NO',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFF555555),
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
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD9D9D9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), elevation: 0),
                            child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1D5572))),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(selectedIndex: BottomNavIndex.chat),
    );
  }

  Widget _summaryRow(String label, String value, {Color valueColor = const Color(0xFF1D5572), bool labelBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (label.isNotEmpty)
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: labelBold ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF2E2E2E)))
        else
          const SizedBox(),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor)),
      ],
    );
  }
}

