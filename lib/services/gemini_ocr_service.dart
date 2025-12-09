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
Analyze this receipt/invoice image carefully. Extract ALL menu items with their prices and quantities.

Return response as VALID JSON ONLY. No markdown, no explanation, no other text.

Structure MUST be exactly:
{
  "items": [
    {"name": "item name", "price": 35000, "quantity": 1},
    {"name": "another item", "price": 50000, "quantity": 2}
  ],
  "subtotal": 120000,
  "tax": 0,
  "service_charge": 0,
  "discount": 0,
  "total": 120000,
  "restaurant_name": "restaurant name or empty",
  "date": "date or empty"
}

CRITICAL:
- Prices MUST be numbers (35000, NOT "35.000", NOT "Rp35000")
- Calculate subtotal from all items: item.price * quantity
- Extract tax, service, discount if present
- Total = subtotal + tax + service - discount
- If items empty, use empty array []
- If field missing, use 0 for numbers or empty string for text
- RETURN ONLY JSON, NOTHING ELSE
''';

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), DataPart(mimeType, imageBytes)]),
      ]);

      final text = response.text ?? '';
      return _parseReceiptJson(text);
    } catch (e) {
      print('Gemini OCR Error: $e');
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
    // Model yang menggunakan schema cenderung mengembalikan JSON murni,
    // tetapi kita tetap membersihkan blok kode markdown untuk keamanan.
    String cleaned = jsonString
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    try {
      final jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;

      print('✅ Successfully parsed JSON.');

      // Normalisasi tipe data (misalnya, memastikan harga adalah int/double yang benar)
      return _normalizeData(jsonMap);
    } catch (e) {
      print('❌ JSON Decode Failed: $e');
      print('Raw string: $cleaned');
      throw Exception("Failed to decode final JSON structure.");
    }
  }

  // Mengubah data (seperti harga) ke tipe data yang konsisten (seperti double)
  Map<String, dynamic> _normalizeData(Map<String, dynamic> data) {
    // Menggunakan double untuk mata uang agar lebih fleksibel,
    // meskipun kita meminta integer ke model.
    final items =
        (data['items'] as List<dynamic>?)
            ?.map(
              (item) => {
                'name': item['name']?.toString() ?? 'Item',
                'price': _toDouble(item['price']),
                'quantity': _toInt(item['quantity']),
              },
            )
            .toList() ??
        [];

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
