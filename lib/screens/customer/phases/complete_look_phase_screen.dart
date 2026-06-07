// lib/screens/customer/phases/complete_look_phase_screen.dart
import 'package:flutter/material.dart';
import '../virtual_makeup_screen.dart';

class CompleteLookPhaseScreen extends StatelessWidget {
  const CompleteLookPhaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VirtualMakeupScreen(initialCategory: 'Jewelry');
  }
}