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
