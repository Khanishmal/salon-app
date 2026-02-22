import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_dashboard.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/vendor_dashboard_screen.dart';
import 'screens/vendor_apply_screen.dart';
import 'screens/working_hours_screen.dart';
import 'screens/unavailable_dates_screen.dart';
import 'screens/vendor_statistics_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/announcements_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlowSalon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        primaryColor: const Color(0xFFF2845C),

        fontFamily: 'Serif',

        // ✅ SOFT PINK BACKGROUND
        scaffoldBackgroundColor: const Color(0xFFFFF0F0),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFF2845C)),
          titleTextStyle: TextStyle(
            color: Color(0xFFF2845C),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2845C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFF2845C),
          ),
        ),

        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFFAFAFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFF2845C), width: 2),
          ),
        ),

        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GlowSalonDashboard(),
        'signin': (context) => const SignInScreen(),
        'signup': (context) => const SignUpScreen(),
        'vendor-dashboard': (context) => const VendorDashboardScreen(),
        'vendor-apply': (context) => const VendorApplyScreen(),
        'working-hours': (context) => const WorkingHoursScreen(),
        'unavailable-dates': (context) => const UnavailableDatesScreen(),
        'statistics': (context) => const VendorStatisticsScreen(),
        'add-product': (context) => const AddProductScreen(),
        'announcements': (context) => const AnnouncementsScreen(),
      },
    );
  }
}
