// lib/screens/vendor/vendor_payment_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorPaymentSetupScreen extends StatefulWidget {
  const VendorPaymentSetupScreen({super.key});

  @override
  State<VendorPaymentSetupScreen> createState() => _VendorPaymentSetupScreenState();
}

class _VendorPaymentSetupScreenState extends State<VendorPaymentSetupScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _accountHolderNameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedPaymentMethod = 'bank';
  Map<String, dynamic>? _paymentInfo;

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  @override
  void dispose() {
    _accountHolderNameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentInfo() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('vendor_payments')
          .doc(user?.uid)
          .get();
      
      if (doc.exists) {
        setState(() {
          _paymentInfo = doc.data() as Map<String, dynamic>;
          _accountHolderNameController.text = _paymentInfo?['accountHolderName'] ?? '';
          _bankNameController.text = _paymentInfo?['bankName'] ?? '';
          _accountNumberController.text = _paymentInfo?['accountNumber'] ?? '';
          _ifscCodeController.text = _paymentInfo?['ifscCode'] ?? '';
          _upiIdController.text = _paymentInfo?['upiId'] ?? '';
          _selectedPaymentMethod = _paymentInfo?['paymentMethod'] ?? 'bank';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePaymentInfo() async {
    if (_selectedPaymentMethod == 'bank') {
      if (_accountHolderNameController.text.isEmpty ||
          _bankNameController.text.isEmpty ||
          _accountNumberController.text.isEmpty ||
          _ifscCodeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all bank details'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else if (_selectedPaymentMethod == 'upi') {
      if (_upiIdController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter UPI ID'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> paymentData = {
        'vendorId': user?.uid,
        'paymentMethod': _selectedPaymentMethod,
        'accountHolderName': _accountHolderNameController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'ifscCode': _ifscCodeController.text.trim().toUpperCase(),
        'upiId': _upiIdController.text.trim(),
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('vendor_payments').doc(user?.uid).set(
        paymentData,
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment information saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Setup',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF2845C), Color(0xFFFFB6A0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Setup Required',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Add your payment details to receive payouts from sales',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Method Selection
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A4B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentMethodCard(
                          'Bank Transfer',
                          Icons.account_balance,
                          'bank',
                          'Direct bank transfer',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPaymentMethodCard(
                          'UPI',
                          Icons.qr_code,
                          'upi',
                          'Instant UPI payments',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bank Details Form
                  if (_selectedPaymentMethod == 'bank') ...[
                    const Text(
                      'Bank Account Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3A4B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _accountHolderNameController,
                      label: 'Account Holder Name *',
                      hint: 'Enter full name as per bank account',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _bankNameController,
                      label: 'Bank Name *',
                      hint: 'Enter bank name',
                      icon: Icons.account_balance,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _accountNumberController,
                      label: 'Account Number *',
                      hint: 'Enter bank account number',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _ifscCodeController,
                      label: 'IFSC Code *',
                      hint: 'Enter IFSC code',
                      icon: Icons.code,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],

                  // UPI Details Form
                  if (_selectedPaymentMethod == 'upi') ...[
                    const Text(
                      'UPI Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3A4B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _upiIdController,
                      label: 'UPI ID *',
                      hint: 'e.g., vendor@upi',
                      icon: Icons.qr_code,
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePaymentInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2845C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Payment Details',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, String method, String description) {
    bool isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDEEE9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFF2845C)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}