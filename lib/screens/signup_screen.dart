// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController(); // For vendor
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedRole = 'Customer';
  bool _obscurePassword = true;
  bool _showVendorFields = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = 'Customer';
  }

  Future<void> _registerUser() async {
    // Basic validation
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please fill all required fields");
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError("Please enter a valid email address");
      return;
    }

    // Password validation
    if (_passwordController.text.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    // Vendor specific validation
    if (_selectedRole == 'Vendor') {
      if (_businessNameController.text.isEmpty) {
        _showError("Please enter your business name");
        return;
      }
      if (_phoneController.text.isEmpty) {
        _showError("Please enter your phone number");
        return;
      }
    }

    setState(() => _isLoading = true);
    
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Prepare user data
      Map<String, dynamic> userData = {
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': null,
      };

      // Add vendor specific fields
      if (_selectedRole == 'Vendor') {
        userData.addAll({
          'businessName': _businessNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'approved': false, // Needs admin approval
          'vendorStatus': 'pending', // pending, approved, rejected
          'totalProducts': 0,
          'totalSales': 0,
          'rating': 0.0,
          'totalReviews': 0,
          'commission': 0.0,
          'walletBalance': 0.0,
          'subscriptionPlan': 'free',
        });
      } else {
        userData.addAll({
          'loyaltyPoints': 0,
          'memberStatus': 'Bronze',
          'approved': true,
        });
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      if (!mounted) return;

      if (_selectedRole == 'Vendor') {
        _showVendorApplicationDialog(context);
      } else {
        _showVerificationDialog(context);
      }
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "This email is already registered. Please sign in.";
          break;
        case 'invalid-email':
          errorMessage = "Please enter a valid email address.";
          break;
        case 'weak-password':
          errorMessage = "Password should be at least 6 characters.";
          break;
        default:
          errorMessage = "Registration failed: ${e.message}";
      }
      
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Verify Your Email"),
        content: const Text("A verification link has been sent to your email. Please verify it before signing in."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Back to Sign In", style: TextStyle(color: Color(0xFFF2845C))),
          ),
        ],
      ),
    );
  }

  void _showVendorApplicationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Vendor Application Submitted!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your vendor application has been submitted successfully."),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEEE9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📋 Application Details:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("Business: ${_businessNameController.text}"),
                  Text("Email: ${_emailController.text}"),
                  Text("Phone: ${_phoneController.text}"),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Please wait for admin approval. You'll receive a notification once your account is approved.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Back to Sign In", style: TextStyle(color: Color(0xFFF2845C))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Create Account", 
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
                const SizedBox(height: 10),
                const Text("Join GlowSalon beauty network", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                // Name Field
                _buildField(_nameController, "Full Name", Icons.person_outline),
                const SizedBox(height: 15),
                
                // Email Field
                _buildField(_emailController, "Email", Icons.email_outlined),
                const SizedBox(height: 15),
                
                // Password Field
                _buildPasswordField(),
                const SizedBox(height: 20),

                // Role Selection
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Register as:", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("Customer"),
                        value: 'Customer',
                        groupValue: _selectedRole,
                        activeColor: const Color(0xFFF2845C),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _selectedRole = val!;
                            _showVendorFields = false;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("Vendor"),
                        value: 'Vendor',
                        groupValue: _selectedRole,
                        activeColor: const Color(0xFFF2845C),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _selectedRole = val!;
                            _showVendorFields = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                // Vendor Specific Fields
                if (_showVendorFields) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDEEE9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF2845C).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        _buildField(_businessNameController, "Business Name", Icons.store_outlined),
                        const SizedBox(height: 15),
                        _buildField(_phoneController, "Phone Number", Icons.phone_outlined),
                        const SizedBox(height: 15),
                        _buildField(_addressController, "Business Address (Optional)", Icons.location_on_outlined),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 25),
                _isLoading 
                  ? const CircularProgressIndicator(color: Color(0xFFF2845C))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2845C),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Create Account", 
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Already have an account? Sign In", 
                    style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: "Password",
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: const Color(0xFFFBFBFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isPass = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFFBFBFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
    );
  }
}