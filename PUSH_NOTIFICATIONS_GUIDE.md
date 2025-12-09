# 📱 Push Notifications Implementation Guide

## ✅ Implementasi Selesai

Splitify sekarang mendukung push notifications dengan:

- ✅ Firebase Cloud Messaging (FCM)
- ✅ Local Notifications untuk foreground messages
- ✅ Background message handling
- ✅ Notification tapable dengan deep linking support

---

## 🔧 Setup Checklist

### 1. ✅ Dependencies Installed

```yaml
firebase_messaging: ^15.0.0
flutter_local_notifications: ^18.0.0
```

### 2. ✅ NotificationService Created

- File: `lib/services/notification_service.dart`
- Singleton pattern untuk manage FCM tokens & notifications
- Automatic foreground notification display
- Background message handler

### 3. ✅ Main.dart Updated

- Initialize NotificationService saat app startup
- Setup background message handler
- FCM token retrieved otomatis

### 4. ✅ Android Permissions Added

- `android.permission.POST_NOTIFICATIONS` untuk notifikasi
- Manifest sudah updated

---

## 🚀 Testing Push Notifications

### **Metode 1: Firebase Console (PALING MUDAH)**

1. **Buka Firebase Console:**

   - Go to: https://console.firebase.google.com/
   - Pilih project `splitify-c58bd`

2. **Navigate ke Messaging:**

   - Klik **Cloud Messaging** (atau **Messaging**)
   - Klik tombol **"Create your first campaign"** atau **"Send your first message"**

3. **Buat Test Message:**

   - **Title:** "Test Notification" (atau apapun)
   - **Body:** "Hello from Firebase Cloud Messaging!"
   - Scroll down, klik **"Send test message"**

4. **Input FCM Token:**

   - Jalankan app di device/emulator
   - Lihat console, cari log: `📱 FCM Token: AIzaSy...`
   - Copy-paste token ke field di Firebase Console
   - Klik **"+Add"** button
   - Klik **"Test"**

5. **Hasil Expected:**

   - Jika app **terbuka (foreground):**

     - Notifikasi muncul sebagai banner/toast di atas
     - Console log: `📬 Foreground message received`

   - Jika app **tertutup/background:**

     - Notifikasi muncul di notification tray
     - Console log: `📱 Background message received`

   - Jika klik notifikasi:
     - App terbuka
     - Console log: `🚀 Message opened app from background`

---

### **Metode 2: Via FCM API (Programmatic)**

Jika ingin mengirim dari backend:

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/splitify-c58bd/messages:send \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": {
        "title": "Test From API",
        "body": "This is a test message sent via FCM API"
      },
      "data": {
        "type": "friend_request",
        "userId": "user123"
      }
    }
  }'
```

---

### **Metode 3: Send Topic Message (Broadcast)**

Send message ke semua devices yang subscribe ke topic `all_users`:

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/splitify-c58bd/messages:send \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "topic": "all_users",
      "notification": {
        "title": "Broadcast Message",
        "body": "This message goes to all users"
      }
    }
  }'
```

---

## 📊 Notification Types Supported

App mendukung different notification types:

| Type                  | Description             | Action                       |
| --------------------- | ----------------------- | ---------------------------- |
| `friend_request`      | Ada friend request baru | Navigate ke friend requests  |
| `activity_invitation` | Diundang ke activity    | Navigate ke activity details |
| `payment_reminder`    | Reminder pembayaran     | Navigate ke payment screen   |

**Contoh:**

```json
{
  "notification": {
    "title": "Friend Request",
    "body": "Aryanda wants to be your friend"
  },
  "data": {
    "type": "friend_request",
    "userId": "user123"
  }
}
```

---

## 🔍 Debugging

### Check FCM Token

Lihat console saat app startup:

```
🔔 Initializing Notification Service...
📋 Permission status: AuthorizationStatus.authorized
✅ Local notifications initialized
📱 FCM Token: AIzaSy_xxxxx...
✅ Notification Service initialized
```

### Check Message Received

Saat notifikasi diterima:

```
📬 Foreground message received
   Title: Test Notification
   Body: Hello from Firebase Cloud Messaging!
   Data: {type: test}
```

### Check Message Tap

Saat user tap notifikasi:

```
🔔 Handling notification tap with data: {type: friend_request}
Navigate to friend requests
```

---

## 📝 Implementation Details

### Files Modified:

1. **`lib/services/notification_service.dart`** - NEW

   - Manage FCM, request permissions, show notifications

2. **`lib/main.dart`** - UPDATED

   - Initialize NotificationService
   - Setup background message handler

3. **`android/app/src/main/AndroidManifest.xml`** - UPDATED

   - Add POST_NOTIFICATIONS permission

4. **`pubspec.yaml`** - UPDATED
   - Add firebase_messaging & flutter_local_notifications

### Key Features:

- ✅ Automatic permission request
- ✅ FCM token retrieval & refresh
- ✅ Foreground notification display
- ✅ Background message handling
- ✅ Notification tap detection
- ✅ Topic subscription (`all_users`)
- ✅ Test notification method

---

## 🎯 For Demo

**Recommended Demo Steps:**

1. **Setup:**

   - Run app di Android device/emulator
   - Wait untuk init message: `✅ Notification Service initialized`
   - Copy FCM token dari console

2. **Test Foreground:**

   - Keep app open
   - Send test message dari Firebase Console
   - Notifikasi harus muncul di atas

3. **Test Background:**

   - Minimize/close app
   - Send test message
   - Notifikasi harus muncul di notification tray

4. **Test Tap:**
   - Tap notifikasi
   - App harus terbuka
   - Check console untuk log `🚀 Message opened app`

---

## ❓ FAQ

**Q: Notifikasi tidak muncul?**
A:

- Pastikan permission sudah di-allow
- Check FCM token tergenerate (lihat console)
- Pastikan app sudah dijalankan minimal sekali
- Clear app data & run lagi

**Q: FCM Token kosong?**
A:

- Pastikan Firebase sudah initialized
- Check internet connection
- Pastikan google-services.json valid

**Q: Backgroundhandler error?**
A:

- Pastikan `@pragma('vm:entry-point')` di firebaseMessagingBackgroundHandler
- Function harus top-level, bukan di class

---

## 🔐 Production Checklist

Sebelum production:

- [ ] Test di actual device (bukan emulator)
- [ ] Verify FCM token lifetime
- [ ] Add navigation logic untuk different notification types
- [ ] Setup analytics tracking untuk notification events
- [ ] Test dengan different payload sizes
- [ ] Setup notification icon & colors yang proper
