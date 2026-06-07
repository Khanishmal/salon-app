// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/signin_screen.dart';
import 'providers/makeup_provider.dart';
import 'screens/main_dashboard.dart';

void main() async {
  // Ensure framework bindings are fully ready
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MakeupProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GlowSalon',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF2845C),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
          // Explicit global configuration for uniform premium text sets
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
        home: const GlowSalonDashboard(),
      ),
    );
  }
}