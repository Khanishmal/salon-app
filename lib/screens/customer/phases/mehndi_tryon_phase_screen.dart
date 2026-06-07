// lib/screens/customer/phases/mehndi_tryon_phase_screen.dart
import 'package:flutter/material.dart';
import '../virtual_makeup_screen.dart';

class MehndiTryOnPhaseScreen extends StatelessWidget {
  const MehndiTryOnPhaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VirtualMakeupScreen(initialCategory: 'Mehndi');
  }
}