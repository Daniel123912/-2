@echo off
REM Сборка release APK. Нужны: Flutter в PATH, Android Studio (SDK), JDK 17.
set PATH=C:\flutter\bin;%PATH%
flutter pub get
flutter test
flutter build apk --release
echo.
echo APK: build\app\outputs\flutter-apk\app-release.apk
