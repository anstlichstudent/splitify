# Cara Kerja Scan Struk - Penjelasan Lengkap

## 📱 Flow Scan Struk dalam App

### **1. User membuka Scan Struk**

```
Home → Create Activity → "Scan Struk" button
```

### **2. Ambil Foto**

- App buka camera
- User photo invoice/struk
- User confirm: "Pakai foto ini?"

### **3. OCR Processing (2 langkah)**

#### **Step A: Coba Gemini API (Preferensi)**

Jika API key dikonfigurasi dan valid:

```
Foto struk → Gemini 1.5 Flash → Parse JSON structured data
                                ↓
                        Extract:
                        - Items dengan nama, harga, qty
                        - Subtotal
                        - Tax & Service charge
                        - Discount
                        - Total
                        - Restaurant name
```

**Output Gemini (IDEAL):**

```json
{
  "items": [
    { "name": "Nasi Goreng", "price": 50000, "quantity": 1 },
    { "name": "Teh Manis", "price": 15000, "quantity": 1 }
  ],
  "tax": 6500,
  "service_charge": 3250,
  "subtotal": 65000,
  "total": 74750
}
```

#### **Step B: Fallback ke MLKit (Jika Gemini Error)**

Jika Gemini API error:

```
Foto struk → MLKit Text Recognition → Extract raw text
                                      ↓
                              Tampil hanya text (tidak struktur)
                              User harus manual input items
```

**Output MLKit (FALLBACK):**

```
Nasi Goreng                    50000
Teh Manis                      15000
Pajak 10%                       6500
Service 5%                      3250
─────────────────────────────────
TOTAL                          74750
```

---

## 🔧 Masalah di Scan Anda

**Gejalanya:**

- Hanya text yang terekstrak
- Tidak ada items yang terstruktur
- Tidak ada prices yang automated

**Penyebab:**

1. ❌ API Key tidak dikonfigurasi di `app_config.dart`
2. ❌ API Key salah/tidak valid
3. ❌ Google Generative AI API tidak di-enable

**Solusi:**
Ikuti `GEMINI_API_SETUP.md` untuk configure API key

---

## ✅ Setelah Setup Benar - Data Otomatis Terisi

Ketika scan struk berhasil dengan Gemini:

### **Step 1: User scan struk**

![Foto struk](image)

### **Step 2: App extract structured data**

```
✅ Restaurant: Warung Makan Jaya
✅ Date: 2024-12-07
✅ Items: 3 item ditemukan
```

### **Step 3: Otomatis isi form Create Activity**

```
┌─────────────────────────────────┐
│  Tambah Pesanan                 │
├─────────────────────────────────┤
│  ✅ Item 1: Nasi Goreng (50K)   │
│  ✅ Item 2: Teh Manis (15K)     │
│  ✅ Item 3: Telor Goreng (20K)  │
├─────────────────────────────────┤
│  Pajak & Layanan                │
│  Tax: 8500 (10%)                │
│  Service: 4250 (5%)             │
│  Discount: 0                     │
├─────────────────────────────────┤
│  TOTAL: Rp 92,250               │
└─────────────────────────────────┘
```

**User tinggal assign ke member mana bayar apa, bukan perlu manual input setiap item!**

---

## 📊 Perbandingan Dengan/Tanpa Gemini API

### **TANPA Gemini API (Fallback MLKit):**

```
Photo → Extract raw text → User manual input setiap item
        Hanya: "Nasi Goreng 50000"
        User harus: Click "Add Item", input name, input price, pilih member
        Repeat untuk setiap item ❌ TEDIOUS
```

### **DENGAN Gemini API (Ideal):**

```
Photo → Gemini extract & parse → Items auto-fill dengan structured data
        User tinggal: Assign item ke member & click "Continue"
        Time: 10 detik vs 2 menit ✅ EFFICIENT
```

---

## 🔍 Debug: Cek apakah Setup Benar

**Setelah set API key, saat open app lihat console:**

```
🔑 Gemini API Key Status:
   - Is Configured: true
   - Key Length: 39
   - Key: [SET - AIzaSy...]
```

✅ Jika muncul `[SET - AIzaSy...]` = API key sudah dikonfigurasi

❌ Jika muncul `[EMPTY - Using Fallback]` = API key masih kosong atau wrong format

---

## 📝 Ringkasan Setup

1. **Get API Key** → https://aistudio.google.com/app/apikey
2. **Enable API** → Google Cloud Console → Generative AI API
3. **Set Key** → `lib/config/app_config.dart`
4. **Test** → Scan struk → Lihat items terekstrak ✅

Setelah selesai, scan struk akan menghemat 80% waktu user! ⏱️
