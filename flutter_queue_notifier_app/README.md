# 📲 Flutter Queue Notifier App

A test prototype of a mobile queue tracking system built 
with **Flutter** and **Firebase Realtime Database**.

This app allows users to:

- Select a public institution (e.g. hospital, tax office)
- Enter their queue number (e.g. A123)
- See the current number being served
- Get **real-time updates**
- Receive **local notifications** when 5 numbers remain (≈10 minutes)

> ⚠️ **Disclaimer:**  
> This is a **test/demo version** currently under development.  
> Logic and functionality are subject to change.

---

## 🚀 Features

- ✅ Firebase Realtime Database integration
- ✅ Anonymous authentication
- ✅ Offline data persistence
- ✅ SharedPreferences to store queue info locally
- ✅ Real-time updates from Firebase
- ✅ Notification when the user is 5 positions away
- ✅ Clean and responsive UI

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^4.0.0
  firebase_database: ^12.0.0
  shared_preferences: ^2.2.2
  dropdown_search: ^5.0.6
  firebase_auth: ^6.0.0
  flutter_local_notifications: ^19.4.0

