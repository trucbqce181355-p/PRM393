# Flow 09 · Shipper Delivery

This is a standalone Flutter project for the Dev 5 shipper flow. Its app opens directly to the MongoDB delivery-order list.

## Run

```powershell
flutter pub get
flutter run -d windows
```

To run on Android, connect an emulator/device and use `flutter run`. Start MongoDB first. The default connection is `127.0.0.1:27017` on Windows and `10.0.2.2:27017` on the Android emulator. Set a different host with:

```powershell
flutter run --dart-define=MONGODB_HOST=<computer-LAN-IP>
```

The sample order setup tool is available at `tool/setup_dev5_database.dart`:

```powershell
dart run tool/setup_dev5_database.dart
```
