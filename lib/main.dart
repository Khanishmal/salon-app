//main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_dashboard.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase Initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const GlowSalonApp());
}

class GlowSalonApp extends StatelessWidget {
  const GlowSalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GlowSalon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF2845C)),
        useMaterial3: true,
      ),
      home: const GlowSalonDashboard(),
    );
  }
}