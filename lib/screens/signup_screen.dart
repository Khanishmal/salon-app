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
  // ===========================================================================
  // TEXT CONTROLLERS
  // ===========================================================================
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================
  
  bool _isLoading = false;
  String _selectedRole = 'Customer';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showVendorFields = false;
  bool _acceptedTerms = false;
  
  // ===========================================================================
  // FOCUS NODES
  // ===========================================================================
  
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _businessNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _selectedRole = 'Customer';
    
    // Add listeners for real-time validation
    _passwordController.addListener(_validatePasswords);
    _confirmPasswordController.addListener(_validatePasswords);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _nameFocus.dispose();
    _businessNameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  void _validatePasswords() {
    // Real-time validation for password match
    setState(() {});
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateBusinessName(String? value) {
    if (_selectedRole == 'Vendor') {
      if (value == null || value.isEmpty) {
        return 'Business name is required';
      }
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (_selectedRole == 'Vendor') {
      if (value == null || value.isEmpty) {
        return 'Phone number is required';
      }
      final phoneRegex = RegExp(r'^[0-9+\- ]{7,15}$');
      if (!phoneRegex.hasMatch(value.trim())) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  bool get _isPasswordValid {
    return _passwordController.text.length >= 6;
  }

  bool get _doPasswordsMatch {
    return _confirmPasswordController.text.isNotEmpty &&
           _passwordController.text == _confirmPasswordController.text;
  }

  bool get _isFormValid {
    return _validateEmail(_emailController.text) == null &&
           _validatePassword(_passwordController.text) == null &&
           _validateConfirmPassword(_confirmPasswordController.text) == null &&
           _validateName(_nameController.text) == null &&
           _validateBusinessName(_businessNameController.text) == null &&
           _validatePhone(_phoneController.text) == null &&
           _acceptedTerms;
  }

  // ===========================================================================
  // REGISTER USER
  // ===========================================================================

  Future<void> _registerUser() async {
    // Final validation
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please fill all required fields");
      return;
    }

    if (!_acceptedTerms) {
      _showError("Please accept the Terms & Conditions");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }

    if (_selectedRole == 'Vendor' && _businessNameController.text.isEmpty) {
      _showError("Please enter your business name");
      return;
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
          'approved': false,
          'vendorStatus': 'pending',
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
        case 'network-request-failed':
          errorMessage = "Network error. Please check your internet connection.";
          break;
        default:
          errorMessage = "Registration failed: ${e.message}";
      }
      
      _showError(errorMessage);
    } catch (e) {
      _showError("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // DIALOGS & HELPERS
  // ===========================================================================

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.email_outlined, size: 48, color: Color(0xFFF2845C)),
            const SizedBox(height: 16),
            const Text("A verification link has been sent to your email."),
            const SizedBox(height: 8),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Please verify your email before signing in.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
            const Icon(Icons.store_outlined, size: 48, color: Color(0xFFF2845C)),
            const SizedBox(height: 16),
            const Text("Your vendor application has been submitted successfully."),
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
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

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Join GlowSalon beauty network",
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),

                // Full Name
                _buildField(
                  controller: _nameController,
                  hint: "Full Name",
                  icon: Icons.person_outline,
                  focusNode: _nameFocus,
                  validator: _validateName,
                  nextFocus: _emailFocus,
                ),
                const SizedBox(height: 16),

                // Email
                _buildField(
                  controller: _emailController,
                  hint: "Email Address",
                  icon: Icons.email_outlined,
                  focusNode: _emailFocus,
                  validator: _validateEmail,
                  nextFocus: _passwordFocus,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password
                _buildPasswordField(),
                const SizedBox(height: 16),

                // Confirm Password
                _buildConfirmPasswordField(),
                
                // Password strength indicator
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildPasswordStrengthIndicator(),
                ],
                
                const SizedBox(height: 20),

                // Role Selection
                const Text(
                  "Register as:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDEEE9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF2845C).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildField(
                          controller: _businessNameController,
                          hint: "Business Name *",
                          icon: Icons.store_outlined,
                          focusNode: _businessNameFocus,
                          validator: _validateBusinessName,
                          nextFocus: _phoneFocus,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _phoneController,
                          hint: "Phone Number *",
                          icon: Icons.phone_outlined,
                          focusNode: _phoneFocus,
                          validator: _validatePhone,
                          nextFocus: _addressFocus,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _addressController,
                          hint: "Business Address (Optional)",
                          icon: Icons.location_on_outlined,
                          focusNode: _addressFocus,
                          validator: null,
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),

                // Terms & Conditions
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        onChanged: (val) {
                          setState(() {
                            _acceptedTerms = val ?? false;
                          });
                        },
                        activeColor: const Color(0xFFF2845C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "I agree to the ",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: "Terms & Conditions",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFF2845C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: " and ",
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            TextSpan(
                              text: "Privacy Policy",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFF2845C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 25),

                // Sign Up Button
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF2845C),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isFormValid ? _registerUser : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2845C),
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Create Account",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                
                const SizedBox(height: 16),
                
                // Sign In link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF2845C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET BUILDERS
  // ===========================================================================

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    String? Function(String?)? validator,
    FocusNode? nextFocus,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF2845C), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      validator: _validatePassword,
      onFieldSubmitted: (_) {
        FocusScope.of(context).requestFocus(_confirmPasswordFocus);
      },
      decoration: InputDecoration(
        hintText: "Password",
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF2845C), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocus,
      obscureText: _obscureConfirmPassword,
      validator: _validateConfirmPassword,
      onFieldSubmitted: (_) {
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        hintText: "Confirm Password",
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF2845C), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.lightGreen,
      Colors.green,
    ];
    final labels = [
      'Very Weak',
      'Weak',
      'Fair',
      'Good',
      'Strong',
    ];
    final index = (strength - 1).clamp(0, 4);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: List.generate(5, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= strength - 1 ? colors[index] : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          labels[index],
          style: GoogleFonts.poppins(
            color: colors[index],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}