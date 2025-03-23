// lib/services/mpesa_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MpesaService {
  static const String consumerKey = 'BTt17HAqXKWOvpdNdaXL93WMWVMERMiOfk2Cgke987HVe8Ee';
  static const String consumerSecret = 'aP9xGduXczlCt6CYiohiDVQZligAfZqAKP1zTsCG4rTNUZT7WdawSOwYwrSr3ybh';
  static const String shortcode = '174379';
  static const String passkey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  static const String baseUrl = 'https://sandbox.safaricom.co.ke'; // Sandbox for testing
  static const String callbackUrl = 'https://us-central1-upcycle-19f2b.cloudfunctions.net/mpesaCallback'; 

  // Generate OAuth Token
  static Future<String?> getAccessToken() async {
    final String auth = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/oauth/v1/generate?grant_type=client_credentials'),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        print('Failed to get token: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Initiate STK Push
  static Future<Map<String, dynamic>?> initiateStkPush({
    required String phoneNumber,
    required double amount,
  }) async {
    final token = await getAccessToken();
    if (token == null) return null;

    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
    final password = base64Encode(utf8.encode('$shortcode$passkey$timestamp'));

    final payload = {
      'BusinessShortCode': shortcode,
      'Password': password,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': amount.toStringAsFixed(0),
      'PartyA': phoneNumber, // e.g., 254712345678
      'PartyB': shortcode,
      'PhoneNumber': phoneNumber,
      'CallBackURL': callbackUrl,
      'AccountReference': 'Order${DateTime.now().millisecondsSinceEpoch}',
      'TransactionDesc': 'Payment for order',
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('STK Push failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error initiating STK Push: $e');
      return null;
    }
  }
}