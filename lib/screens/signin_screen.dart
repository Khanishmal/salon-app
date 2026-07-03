// lib/screens/signin_screen.dart - Full corrected file
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer/customer_dashboard.dart';
import 'vendor/vendor_screen.dart';
import 'signup_screen.dart';
import 'salon_owner_screen.dart';
import 'vendor/vendor_dashboard.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError("Please enter a valid email address");
      setState(() => _isLoading = false);
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        if (user.email != 'admin@salon.com') {
          await FirebaseAuth.instance.signOut();
          _showError("Please verify your email before signing in. Check your inbox.");
          setState(() => _isLoading = false);
          return;
        }
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'Customer';
        bool isActive = userData['isActive'] ?? true;
        bool isApproved = userData['approved'] ?? false;
        
        if (!mounted) return;

        if (!isActive) {
          _showError("Your account has been deactivated. Please contact support.");
          await FirebaseAuth.instance.signOut();
          setState(() => _isLoading = false);
          return;
        }

        if (role == 'Salon Owner') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SalonOwnerScreen()));
        } else if (role == 'Vendor') {
          bool hasProducts = await _checkVendorHasProducts(user!.uid);
          bool hasOrders = await _checkVendorHasOrders(user!.uid);
          
          bool isExistingVendor = hasProducts || hasOrders || isApproved;
          
          if (isExistingVendor || isApproved) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VendorDashboardScreen()));
          } else {
            _showError("Your vendor account is pending approval. Please wait for admin confirmation.");
            await FirebaseAuth.instance.signOut();
            setState(() => _isLoading = false);
            return;
          }
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerDashboard()));
        }
      } else {
        _showError("Account record not found in database.");
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email. Please sign up.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password. Please try again.";
          break;
        case 'invalid-email':
          errorMessage = "Please enter a valid email address.";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled. Contact support.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many failed attempts. Try again later.";
          break;
        default:
          errorMessage = e.message ?? "Login failed. Please try again.";
      }
      
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkVendorHasProducts(String uid) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('vendorId', isEqualTo: uid)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkVendorHasOrders(String uid) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: uid)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(email)) {
      _showError("Enter your email address above, then tap Forgot password.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSuccess("Password reset link sent. Check your inbox.");
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email.";
          break;
        case 'invalid-email':
          errorMessage = "Please enter a valid email address.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many requests. Try again later.";
          break;
        default:
          errorMessage = e.message ?? "Could not send reset email. Try again.";
      }
      _showError(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Back',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
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
              children: [
                Image.asset('assets/logo_icon.png', height: 80, 
                  errorBuilder: (c, e, s) => const Icon(Icons.star, size: 80, color: Color(0xFFF2845C))),
                const SizedBox(height: 20),
                const Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
                const Text("Sign in to access your account", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                _buildInputLabel("Email"),
                _buildTextField(_emailController, "Enter your email", Icons.email_outlined),
                const SizedBox(height: 20),
                
                _buildInputLabel("Password"),
                _buildPasswordField(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: Color(0xFFF2845C),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2845C),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 25),
                _buildFooterLinks(),
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
        hintText: "Enter your password",
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
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
  );
  
  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("Don't have an account? "),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
            child: const Text("Sign up", style: TextStyle(color: Color(0xFFF2845C), fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 15),
        const Divider(),
        const SizedBox(height: 10),
        const Text("Are you a business partner?", style: TextStyle(fontSize: 12, color: Colors.grey)),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorScreen()));
          },
          child: const Text("Apply as Vendor", style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        ),
      ],
    );
  }
}