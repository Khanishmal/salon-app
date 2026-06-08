import 'package:flutter/material.dart';

class VirtualMakeupScreen extends StatelessWidget {
  const VirtualMakeupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Virtual Live Makeover")),
      body: Center(
        child: Text(
          "Aligning Face Nodes Matrix...",
          textAlign: TextAlign.center, // Fixed parameter from type object logic to structural value
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}