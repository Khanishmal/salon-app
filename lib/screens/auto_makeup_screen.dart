// lib/screens/auto_makeup_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/makeup_api_service.dart';

class AutoMakeupScreen extends StatefulWidget {
  @override
  _AutoMakeupScreenState createState() => _AutoMakeupScreenState();
}

class _AutoMakeupScreenState extends State<AutoMakeupScreen> {
  final MakeupApiService _api = MakeupApiService();
  Uint8List? _imageResult;
  bool _isLoading = false;

  Future<void> _pickAndProcess() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      
      final inputBytes = await pickedFile.readAsBytes();
      final result = await _api.applyAutoMakeup(inputBytes);

      setState(() {
        _imageResult = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Auto-Makeup")),
      body: Center(
        child: _isLoading 
          ? CircularProgressIndicator() 
          : _imageResult == null
              ? Text("Upload a photo to see the magic!")
              : Column(
                  children: [
                    Expanded(child: Image.memory(_imageResult!)),
                    ElevatedButton(
                      onPressed: () => setState(() => _imageResult = null), 
                      child: Text("Try Another")
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndProcess,
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}