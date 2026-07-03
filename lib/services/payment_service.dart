// lib/services/payment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For JazzCash/EasyPaisa - Generate payment instructions
  static Future<Map<String, dynamic>> generatePaymentInstructions(
    String orderId,
    double amount,
    String paymentMethod,
  ) async {
    // Generate a unique transaction ID
    String transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    
    // Store payment reference
    await _firestore.collection('payments').add({
      'orderId': orderId,
      'transactionId': transactionId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Return payment instructions based on method
    if (paymentMethod == 'jazzcash') {
      return {
        'accountNumber': '03XX-XXXXXXX',
        'accountTitle': 'Your Business Name',
        'transactionId': transactionId,
        'instructions': 'Send payment to the above JazzCash account and enter the transaction ID',
      };
    } else if (paymentMethod == 'easypaisa') {
      return {
        'accountNumber': '03XX-XXXXXXX',
        'accountTitle': 'Your Business Name',
        'transactionId': transactionId,
        'instructions': 'Send payment to the above EasyPaisa account and enter the transaction ID',
      };
    } else {
      return {
        'bankName': 'Your Bank Name',
        'accountNumber': '1234-5678-90',
        'accountTitle': 'Your Business Name',
        'transactionId': transactionId,
        'instructions': 'Transfer to the above bank account and enter the transaction reference',
      };
    }
  }

  // Verify payment (manual verification by admin)
  static Future<void> verifyPayment(String paymentId, String transactionId) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'transactionId': transactionId,
      'status': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }
}