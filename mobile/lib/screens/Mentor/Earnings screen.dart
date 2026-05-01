import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earnings',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E7B)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const EarningsScreen(),
    );
  }
}

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _selectedIndex = 0;

  static const Color primaryDark = Color(0xFF1B5E7B);
  static const Color accentTeal = Color(0xFF2E86AB);
  static const Color barColor = Color(0xFF1B5E7B);
  static const Color barBg = Color(0xFFE0E0E0);
  static const Color completedGreen = Color(0xFF4CAF50);
  static const Color pendingOrange = Color(0xFFFF9800);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF666666);
  static const Color bgLight = Color(0xFFF5F7FA);

  final List<Map<String, dynamic>> weeklyData = const [
    {'label': 'Week 1', 'amount': 320, 'max': 420},
    {'label': 'Week 2', 'amount': 120, 'max': 420},
    {'label': 'Week 3', 'amount': 420, 'max': 420},
    {'label': 'Week 4', 'amount': 80, 'max': 420},
  ];

  final List<Map<String, dynamic>> transactions = const [
    {
      'name': 'Sarah Johnson',
      'date': 'Apr 26, 2026',
      'amount': '+80',
      'status': 'completed',
    },
    {
      'name': 'Michael Chen',
      'date': 'Apr 23, 2026',
      'amount': '+160',
      'status': 'pending',
    },
    {
      'name': 'Emma Wilson',
      'date': 'Apr 22, 2026',
      'amount': '+80',
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // This Month Card
                  _buildThisMonthCard(),
                  const SizedBox(height: 16),
                  // April Overview
                  _buildAprilOverview(),
                  const SizedBox(height: 20),
                  // Recent Transactions
                  _buildRecentTransactions(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // Bottom Nav
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: primaryDark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Track your total earnings and payment history',
            style: TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThisMonthCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border:
                  Border.all(color: textSecondary.withOpacity(0.4), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/Money.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Main info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'This Month',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: completedGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.trending_up,
                              color: completedGreen, size: 12),
                          SizedBox(width: 2),
                          Text(
                            '12%',
                            style: TextStyle(
                              color: completedGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '1240',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'EGP',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildSubStat('Pending', '160 EGP'),
                    const SizedBox(width: 32),
                    _buildSubStat('This Week', '320 EGP'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAprilOverview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'April Overview',
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...weeklyData.map((w) => _buildWeekRow(w)).toList(),
        ],
      ),
    );
  }

  Widget _buildWeekRow(Map<String, dynamic> data) {
    final double ratio = data['amount'] / data['max'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              data['label'],
              style: const TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Background bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: barBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Filled bar
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${data['amount']}',
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: 'EGP',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            color: accentTeal,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...transactions.map((t) => _buildTransactionCard(t)).toList(),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> t) {
    final bool isCompleted = t['status'] == 'completed';
    final Color statusColor = isCompleted ? completedGreen : pendingOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Name + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t['name'],
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                t['date'],
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t['amount'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t['status'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.account_balance_wallet_outlined, 'label': 'Wallet'},
      {'icon': Icons.send_outlined, 'label': 'Chat'},
      {'icon': Icons.notifications_none_outlined, 'label': 'Notification'},
      {'icon': Icons.assignment_outlined, 'label': 'Request'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final bool selected = index == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: selected
                  ? BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[index]['icon'] as IconData,
                    color: selected ? const Color(0xFFFFC107) : Colors.white70,
                    size: selected ? 26 : 24,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[index]['label'] as String,
                    style: TextStyle(
                      color:
                          selected ? const Color(0xFFFFC107) : Colors.white70,
                      fontSize: 9.5,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
