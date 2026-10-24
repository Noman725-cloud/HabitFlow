# HabitFlow setup notes

Run everything from the inner project folder (the one containing pubspec.yaml).

```powershell
flutter pub get
dart run build_runner build      # (or: flutter pub run build_runner build)
flutter analyze
flutter test
flutter run
```

Environment gotchas we hit on Windows
- Keep the Flutter SDK in a path WITHOUT spaces (e.g. C:\flutter_sdk).
- Make sure `where.exe flutter` / `dart --version` point at that SDK.
- After `flutter upgrade`, the Android template may need newer Gradle / AGP /
  Kotlin versions (android/gradle/wrapper/gradle-wrapper.properties and
  android/settings.gradle.kts), or recreate it: delete android/ and run
  `flutter create --platforms=android .`
- After any change to lib/data/database/tables.dart, re-run build_runner.
