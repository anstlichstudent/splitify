import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiOCRService {
  late final GenerativeModel _model;
  final String apiKey;

  GeminiOCRService({required this.apiKey}) {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  /// Extract text & items dari receipt image menggunakan Gemini Vision
  Future<Map<String, dynamic>> extractReceiptData(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      // Determine MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      const prompt = '''
Analyze this receipt/invoice image carefully. Extract menu items with their prices and quantities.
Return ONLY valid JSON with no markdown, no explanations.

{
  "items": [
    {"name": "item name", "price": 45000, "quantity": 1},
    {"name": "another item", "price": 50000, "quantity": 2}
  ],
  "subtotal": 120000,
  "tax": 0,
  "service_charge": 0,
  "discount": 0,
  "total": 120000,
  "restaurant_name": "restaurant name",
  "date": "date if visible"
}

Rules:
- Extract ALL items with prices as whole numbers (35000, not "35.000")
- Quantity defaults to 1 if not shown
- Find subtotal, tax, service, discount, total
- Return valid JSON ONLY, no other text
''';

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), DataPart(mimeType, imageBytes)]),
      ]);

      final text = response.text ?? '';
      print('📸 Gemini Response: $text');

      final parsed = _parseReceiptJson(text);
      print('✅ Parsed items: ${parsed['items']} | Total: ${parsed['total']}');
      return parsed;
    } catch (e) {
      print('❌ Gemini OCR Error: $e');
      rethrow;
    }
  }

  // Helper untuk mendapatkan MIME type
  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  /// Membersihkan dan mem-parse string JSON dari Gemini
  Map<String, dynamic> _parseReceiptJson(String jsonString) {
    String cleaned = jsonString
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    try {
      final jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;
      print('✅ JSON parsed successfully');
      return _normalizeData(jsonMap);
    } catch (e) {
      print('❌ JSON Parse Error: $e');
      print('Raw response was: $cleaned');

      // Return minimal valid structure to prevent crash
      return {
        'items': [],
        'subtotal': 0.0,
        'tax': 0.0,
        'service_charge': 0.0,
        'discount': 0.0,
        'total': 0.0,
        'restaurant_name': '',
        'date': '',
      };
    }
  }

  // Mengubah data (seperti harga) ke tipe data yang konsisten (seperti double)
  Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    try {
      final itemsList = data['items'] as List<dynamic>? ?? [];
      final items = itemsList.where((item) => item is Map<String, dynamic>).map(
        (item) {
          final itemMap = item as Map<String, dynamic>;
          return {
            'name': itemMap['name']?.toString() ?? 'Item',
            'price': _toDouble(itemMap['price']),
            'quantity': _toInt(itemMap['quantity']),
          };
        },
      ).toList();

      print('📊 Normalized: ${items.length} items');

      return {
        'items': items,
        'subtotal': _toDouble(data['subtotal']),
        'tax': _toDouble(data['tax']),
        'service_charge': _toDouble(data['service_charge']),
        'discount': _toDouble(data['discount']),
        'total': _toDouble(data['total']),
        'restaurant_name': data['restaurant_name']?.toString() ?? '',
        'date': data['date']?.toString() ?? '',
      };
    } catch (e) {
      print('⚠️ Normalization error: $e');
      // Return safe defaults
      return {
        'items': [],
        'subtotal': 0.0,
        'tax': 0.0,
        'service_charge': 0.0,
        'discount': 0.0,
        'total': 0.0,
        'restaurant_name': '',
        'date': '',
      };
    }
  }

  // Helper untuk konversi ke double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper untuk konversi ke int
  int _toInt(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }
}
