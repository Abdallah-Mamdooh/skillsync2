import 'package:flutter/material.dart';

class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Learning Roadmap'),
        backgroundColor: const Color(0xFF1D5572),
      ),
      body: const Center(
        child: Text('Your personalized roadmap will appear here.'),
      ),
    );
  }
}
