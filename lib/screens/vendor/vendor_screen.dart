//vendor_screen.dart
import 'package:flutter/material.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Back to Home", style: TextStyle(color: Colors.grey, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Image.asset('assets/logo_icon.png', height: 70),
                const SizedBox(height: 20),
                const Text("Become a Vendor", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
                const Text("Apply to offer your services on GlowSalon", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                _buildLabelField("Full Name", _nameController, "Enter your full name", Icons.person_outline),
                _buildLabelField("Business Name", _businessController, "Your salon/business name", Icons.store_outlined),
                _buildLabelField("Email", _emailController, "Enter your email", Icons.email_outlined),
                _buildLabelField("Password", _passwordController, "Enter your password", Icons.lock_outline, isPass: true),
                
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Logic: Save to 'vendor_applications' collection in Firestore
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Submitted!")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2845C),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Submit Application", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Already have an account? Sign in", style: TextStyle(color: Color(0xFFF2845C))),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelField(String label, TextEditingController ctrl, String hint, IconData icon, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: isPass,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}