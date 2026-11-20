# Meeting Summary app: step 1 setup

1. Create the project:
   flutter create meeting_summary
2. Replace its `pubspec.yaml` and `lib/main.dart` with the two files here.
3. Run: flutter pub get

## Android
In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`, add:

    <uses-permission android:name="android.permission.RECORD_AUDIO" />

Set `minSdkVersion` to 23 or higher in `android/app/build.gradle`.

## iPhone
In `ios/Runner/Info.plist`, add:

    <key>NSMicrophoneUsageDescription</key>
    <string>Used to record meetings for the summary.</string>

## Run
flutter run

## Logo and app icon
Logo files are in `assets/`. After copying `assets/` into your Flutter project, run:

    flutter pub get
    dart run flutter_launcher_icons

Set the app name shown on the phone: in `android/app/src/main/AndroidManifest.xml`
change `android:label` to `RPAScribe`.
