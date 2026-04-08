import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'payment.dart';

class MentorshipScreen extends StatefulWidget {
  const MentorshipScreen({super.key});

  @override
  State<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends State<MentorshipScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _mentors = [];
  List<Map<String, dynamic>> _filteredMentors = [];
  bool _isLoading = true;
  String _method = 'chat';
  int _durationMinutes = 60;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterMentors);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMentors());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMentors() async {
    final response = await ApiService.getPublic('/mentors/public');
    final data = response['data'];
    final list = data is List ? data : <dynamic>[];
    final mentors = list.map((e) => Map<String, dynamic>.from(e)).toList();
    if (!mounted) return;
    setState(() {
      _mentors = mentors;
      _filteredMentors = mentors;
      _isLoading = false;
    });
  }

  void _filterMentors() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredMentors = _mentors.where((mentor) {
        final name = mentor['fullName']?.toString().toLowerCase() ?? '';
        final headline = mentor['headline']?.toString().toLowerCase() ?? '';
        final specialization = mentor['specialization'] is List
            ? (mentor['specialization'] as List).join(' ').toLowerCase()
            : '';
        return name.contains(query) ||
            headline.contains(query) ||
            specialization.contains(query);
      }).toList();
    });
  }

  Future<void> _bookMentor(Map<String, dynamic> mentor) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    final mentorId = mentor['id']?.toString() ?? '';
    if (mentorId.isEmpty) return;

    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final slotsResponse = await ApiService.get(
      '/mentors/public/$mentorId/available-slots?date=$date&durationMinutes=$_durationMinutes',
      token,
    );

    final slotData = slotsResponse['data'];
    final slots = slotData is Map<String, dynamic> && slotData['slots'] is List
        ? List<dynamic>.from(slotData['slots'])
        : <dynamic>[];

    if (slots.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available slots found for today.')),
      );
      return;
    }

    final firstSlot = Map<String, dynamic>.from(slots.first);
    final startTime = firstSlot['startTime']?.toString() ?? '10:00';
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          mentorProfileId: mentorId,
          mentorName: mentor['fullName']?.toString() ?? 'Mentor',
          method: _method,
          durationMinutes: _durationMinutes,
          scheduledDate: date,
          scheduledStartTime: startTime,
          estimatedPrice: (mentor['baseRate'] is num)
              ? (mentor['baseRate'] as num).toDouble()
              : 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentorship')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search mentors',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: _method,
                        items: const [
                          DropdownMenuItem(value: 'chat', child: Text('Chat')),
                          DropdownMenuItem(value: 'call', child: Text('Call')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _method = value);
                        },
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<int>(
                        value: _durationMinutes,
                        items: const [
                          DropdownMenuItem(value: 30, child: Text('30 min')),
                          DropdownMenuItem(value: 45, child: Text('45 min')),
                          DropdownMenuItem(value: 60, child: Text('60 min')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _durationMinutes = value);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredMentors.length,
                    itemBuilder: (context, index) {
                      final mentor = _filteredMentors[index];
                      final specs =
                          mentor['specialization'] is List ? mentor['specialization'] as List : [];
                      final rating = mentor['ratingAverage']?.toString() ?? '0';
                      final baseRate = mentor['baseRate']?.toString() ?? '0';
                      final currency = mentor['currency']?.toString() ?? 'EGP';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(mentor['fullName']?.toString() ?? 'Mentor'),
                          subtitle: Text(
                            '${mentor['headline'] ?? ''}\n'
                            'Rating: $rating  Rate: $baseRate $currency\n'
                            '${specs.join(', ')}',
                          ),
                          isThreeLine: true,
                          trailing: ElevatedButton(
                            onPressed: () => _bookMentor(mentor),
                            child: const Text('Book'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
