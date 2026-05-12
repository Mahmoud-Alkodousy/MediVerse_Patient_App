# 🏥 MediVerse Patient App

تطبيق Flutter احترافي لمتابعة الدور في العيادات

## ⚡ خطوات التشغيل السريع

### 1. تثبيت المكتبات
```bash
flutter pub get
```

### 2. تشغيل التطبيق
```bash
flutter run
```

---

## 🔗 إعداد الـ API

افتح `lib/core/constants/api_config.dart` وغيّر الـ URL:

```dart
static const String baseUrl = 'https://YOUR-NGROK-URL.ngrok-free.dev';
```

> ⚠️ لازم تضيف header خاص بـ ngrok موجود بالفعل في الكود

---

## 📁 هيكل الملفات

```
lib/
├── main.dart
├── core/constants/         # الألوان، النصوص، الـ API
├── models/                 # Patient, QueueStatus
├── services/               # ApiService, NotificationService
└── screens/                # LoginScreen, HomeScreen
```

---

## 🎨 التصميم

- **Theme**: Dark Luxury Medical
- **Colors**: نيون سماوي + بنفسجي عميق
- **Effects**: Glassmorphism + Glow animations
- **Animations**: Entry, pulse, orbit, counter

---

## ✅ Checklist قبل التسليم

- [ ] غيّر الـ ngrok URL في `api_config.dart`
- [ ] جرّب على جهاز حقيقي
- [ ] تأكد إن الـ WiFi نفسه

