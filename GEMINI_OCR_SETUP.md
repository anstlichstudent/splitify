# Gemini API OCR Setup Guide

## Overview

Splitify menggunakan **Google Gemini 1.5 Flash** untuk OCR (Optical Character Recognition) pada receipt/struk. Sistem ini dilengkapi dengan fallback ke MLKit untuk reliability yang lebih baik.

## Setup Langkah-Langkah

### 1. Dapatkan Gemini API Key

- Kunjungi [Google AI Studio](https://aistudio.google.com/app/apikey)
- Login dengan Google account Anda
- Klik **"Create API Key"**
- Copy API key yang dihasilkan

### 2. Setup Environment Variable

**Opsi A: File `.env` (Development)**

```
# .env
GEMINI_API_KEY=your_actual_key_here
```

**Opsi B: Firebase Remote Config (Production)**
Gunakan Firebase Console untuk menyimpan key secara aman:

1. Go to Firebase Console → Project Settings → Remote Config
2. Add parameter: `gemini_api_key`
3. Update `AppConfig.geminiApiKey` di `lib/config/app_config.dart` untuk read dari Remote Config

**Opsi C: Hardcode (Testing Only)**
Edit `lib/config/app_config.dart`:

```dart
static String get geminiApiKey {
  return 'paste_your_actual_key_here';
}
```

### 3. Update `.env` File

Buka `.env` di root project dan replace:

```
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

### 4. Run Flutter dengan Environment Variable (Jika menggunakan .env)

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

## Fitur OCR

### Input Format

- **Supported Formats**: JPG, PNG, GIF, WebP
- **Max Size**: Tergantung Gemini API limits (biasanya 4MB per image)

### Output Format

Gemini akan extract data dalam format JSON:

```json
{
  "items": [
    { "name": "Nasi Goreng", "price": 50000, "quantity": 2 },
    { "name": "Mie Rebus", "price": 30000, "quantity": 1 }
  ],
  "subtotal": 130000,
  "tax": 13000,
  "service_charge": 13000,
  "discount": 0,
  "total": 156000,
  "restaurant_name": "Warung Makan",
  "date": "2025-12-05"
}
```

### Fallback Mechanism

Jika Gemini API gagal (network error, quota exceeded, dll):

1. Sistem otomatis fallback ke **MLKit Text Recognition**
2. Text di-extract tapi tidak di-parse menjadi structured data
3. User bisa manual input items atau re-scan

## Integration dalam App

### ScanStrukPage

1. User bisa capture image dari camera atau import dari gallery
2. Klik "Proses" untuk OCR
3. Hasil ditampilkan dalam format readable
4. Klik "Gunakan Data Ini" untuk pass ke CreateActivityScreen

### CreateActivityScreen

1. Tombol "Scan Struk" di section "Tambah Pesanan"
2. Auto-populate items, tax, service, discount dari hasil OCR
3. User bisa manual edit atau adjust values

## Troubleshooting

### Error: "API key not found"

- Check .env file sudah di root project
- Run dengan: `flutter run --dart-define=GEMINI_API_KEY=your_key`

### Error: "Invalid API key"

- Pastikan key valid di Google AI Studio
- Key tidak bisa share / publish ke public repo
- Regenerate key jika dicurigai compromised

### Error: "Quota exceeded"

- Gemini API punya daily quota
- Check Google Cloud Console untuk usage limits
- Upgrade plan jika perlu

### Image tidak ter-recognize

- Quality receipt/struk bagus dan readable
- Coba rotate/adjust angle
- MLKit fallback akan handle raw text

## Security Best Practices

⚠️ **PENTING**: Jangan commit API key ke git!

1. **Add ke `.gitignore`**:

   ```
   .env
   .env.local
   *.key
   ```

2. **Gunakan Secrets Manager** (Production):

   - Firebase Remote Config
   - Google Cloud Secret Manager
   - Environment variables di CI/CD

3. **Key Rotation**:
   - Regenerate key secara berkala
   - Monitor usage di Google Cloud Console

## Cost Estimation

Google Gemini 1.5 Flash pricing (as of Dec 2024):

- **Input**: $0.075 per 1M tokens (~600K images)
- **Output**: $0.30 per 1M tokens

Example: 1000 receipt scans/month ≈ $0.05-0.10

## Next Steps

1. ✅ Setup API key di `.env`
2. ✅ Test OCR dengan sample receipt
3. ✅ Integrate ke transaction history
4. ✅ Save receipt image & OCR result ke Firestore
5. ✅ Add option untuk re-scan jika data tidak akurat

## References

- [Google Gemini API Docs](https://ai.google.dev/docs)
- [MLKit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition)
