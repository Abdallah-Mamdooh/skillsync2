import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  bool _isLoading = true;
  bool _isToggling = false;
  int _progress = 0;
  String? _error;
  List<dynamic> _phases = [];
  List<dynamic> _recentCompletions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoadmap());
  }

  Future<void> _loadRoadmap() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Please login first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final roadmapResponse = await ApiService.get('/roadmap/my-roadmap', token);
    final progressResponse = await ApiService.get('/roadmap/progress', token);
    final recentResponse = await ApiService.get('/roadmap/recent-completions', token);

    if (roadmapResponse['success'] == true) {
      final data = roadmapResponse['data'];
      final roadmap = data is Map<String, dynamic> ? data['roadmap'] : null;
      final phases = roadmap is Map<String, dynamic> ? roadmap['phases'] : null;
      final progress =
          progressResponse['success'] == true ? progressResponse['progress'] : 0;
      setState(() {
        _phases = phases is List ? phases : [];
        _recentCompletions =
            recentResponse['success'] == true && recentResponse['data'] is List
                ? List<dynamic>.from(recentResponse['data'])
                : [];
        _progress = (progress is num) ? progress.round() : 0;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _error = roadmapResponse['message']?.toString() ?? 'Failed to load roadmap';
    });
  }

  Future<void> _toggleStep(String stepId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty || _isToggling) return;

    setState(() => _isToggling = true);
    final response =
        await ApiService.postWithAuth('/roadmap/toggle-step', {'stepId': stepId}, token);
    if (response['success'] != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']?.toString() ?? 'Failed to update step')),
      );
    }
    await _loadRoadmap();
    if (mounted) {
      setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Learning Roadmap'),
        backgroundColor: const Color(0xFF1D5572),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadRoadmap,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      LinearProgressIndicator(
                        value: _progress.clamp(0, 100) / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF1D5572),
                      ),
                      const SizedBox(height: 8),
                      Text('Progress: $_progress%'),
                      const SizedBox(height: 16),
                      ..._phases.map((phase) => _buildPhaseCard(phase)).toList(),
                      if (_recentCompletions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Recent completions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ..._recentCompletions.map((item) {
                          final title = item is Map<String, dynamic>
                              ? item['stepTitle']?.toString() ?? 'Completed step'
                              : 'Completed step';
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(title),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildPhaseCard(dynamic phase) {
    final phaseMap =
        phase is Map<String, dynamic> ? phase : <String, dynamic>{'title': 'Phase'};
    final title = phaseMap['title']?.toString() ?? 'Phase';
    final steps = phaseMap['steps'] is List ? phaseMap['steps'] as List<dynamic> : [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...steps.map((step) {
              final stepMap =
                  step is Map<String, dynamic> ? step : <String, dynamic>{};
              final id = stepMap['_id']?.toString() ?? '';
              final stepTitle = stepMap['title']?.toString() ?? 'Step';
              final done = stepMap['isCompleted'] == true;
              return CheckboxListTile(
                value: done,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(stepTitle),
                onChanged: _isToggling || id.isEmpty ? null : (_) => _toggleStep(id),
              );
            }),
          ],
        ),
      ),
    );
  }
}
