import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

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
                                const Icon(Icons.account_balance_wallet, color: Color(0xFFF5A100), size: 26),
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
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Session confirmed!'), backgroundColor: Color(0xFF1D5572)),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D5572), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                            child: Text('Confirm', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
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
      bottomNavigationBar: _buildBottomNav(2, context),
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

// ===== SHARED BOTTOM NAV =====
BottomNavigationBar _buildBottomNav(int currentIndex, [BuildContext? ctx]) {
  return BottomNavigationBar(
    backgroundColor: const Color(0xFF1D5572),
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    type: BottomNavigationBarType.fixed,
    currentIndex: currentIndex,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
    onTap: ctx == null ? null : (index) {
      if (index == 0) {
        Navigator.pushAndRemoveUntil(ctx, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
      } else if (index == 3) {
        Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      }
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'assess'),
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}