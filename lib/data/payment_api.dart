import 'dart:convert';

import 'package:http/http.dart' as http;

/// PayOS proxy server on Render (see /server). Override with --dart-define=PAYMENT_API=https://...
const paymentApiBase = String.fromEnvironment('PAYMENT_API', defaultValue: 'https://prm-shop-payos.onrender.com');

/// Render's free plan sleeps when idle, so the first request can take ~30-50s.
const _timeout = Duration(seconds: 70);

class PaymentApi {
  static Future<Map<String, dynamic>> _json(Future<http.Response> req) async {
    final res = await req.timeout(_timeout);
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'Lỗi máy chủ (${res.statusCode})');
    return body;
  }

  static Future<({int orderCode, String checkoutUrl})> create(int amount) async {
    final b = await _json(
      http.post(
        Uri.parse('$paymentApiBase/payments'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      ),
    );
    return (orderCode: b['orderCode'] as int, checkoutUrl: b['checkoutUrl'] as String);
  }

  /// status: PENDING, PAID, CANCELLED, EXPIRED, ...
  static Future<({String status, int amountPaid})> status(int orderCode) async {
    final b = await _json(http.get(Uri.parse('$paymentApiBase/payments/$orderCode')));
    return (status: b['status'] as String, amountPaid: (b['amountPaid'] as num?)?.toInt() ?? 0);
  }

  static Future<void> cancel(int orderCode) =>
      _json(http.post(Uri.parse('$paymentApiBase/payments/$orderCode/cancel')));
}
