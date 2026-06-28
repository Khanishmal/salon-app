// lib/screens/vendor/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic> _vendorData = {};
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _vendorData = data;
          _nameController.text = data['name'] ?? '';
          _businessNameController.text = data['businessName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _firestore.collection('users').doc(user!.uid).update({
        'name': _nameController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vendor Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isEditing) {
                // Cancel editing
                setState(() {
                  _isEditing = false;
                  _nameController.text = _vendorData['name'] ?? '';
                  _businessNameController.text = _vendorData['businessName'] ?? '';
                  _phoneController.text = _vendorData['phone'] ?? '';
                  _addressController.text = _vendorData['address'] ?? '';
                  _descriptionController.text = _vendorData['description'] ?? '';
                });
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildProfileCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF2845C), Color(0xFFFFB6A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              (_vendorData['name'] ?? 'V')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF2845C),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _vendorData['name'] ?? 'Vendor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _vendorData['businessName'] ?? 'No Business Name',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _vendorData['vendorStatus'] ?? 'Pending Approval',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileField(
              label: 'Full Name',
              value: _vendorData['name'] ?? '',
              controller: _nameController,
              icon: Icons.person_outline,
            ),
            const Divider(),
            _buildProfileField(
              label: 'Business Name',
              value: _vendorData['businessName'] ?? '',
              controller: _businessNameController,
              icon: Icons.store_outlined,
            ),
            const Divider(),
            _buildProfileField(
              label: 'Phone',
              value: _vendorData['phone'] ?? '',
              controller: _phoneController,
              icon: Icons.phone_outlined,
            ),
            const Divider(),
            _buildProfileField(
              label: 'Address',
              value: _vendorData['address'] ?? '',
              controller: _addressController,
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const Divider(),
            _buildProfileField(
              label: 'Description',
              value: _vendorData['description'] ?? '',
              controller: _descriptionController,
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2845C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _isEditing
            ? TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              )
            : Text(
                value.isNotEmpty ? value : 'Not provided',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D3A4B),
                ),
              ),
      ],
    );
  }
}