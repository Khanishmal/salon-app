// lib/screens/customer/phases/virtual_makeup_phase_screen.dart
import 'package:flutter/material.dart';
import '../virtual_makeup_screen.dart';

class VirtualMakeupPhaseScreen extends StatelessWidget {
  const VirtualMakeupPhaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VirtualMakeupScreen(initialCategory: 'Lipstick');
  }
}