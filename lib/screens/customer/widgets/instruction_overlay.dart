import 'package:flutter/material.dart';

class MakeoverControlPanel extends StatelessWidget {
  const MakeoverControlPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Fixed property reference lookup definition
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: const Center(
        child: Text("Control Options Bar Panel", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}