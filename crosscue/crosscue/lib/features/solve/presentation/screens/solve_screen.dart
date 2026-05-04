import 'package:flutter/material.dart';

class SolveScreen extends StatelessWidget {
  const SolveScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Puzzle $puzzleId')),
      body: const Center(child: Text('Solve Screen — Sprint 4')),
    );
  }
}
