# MediRemind - Setup Instructions

## 📋 Prerequisites

Before you begin, ensure you have installed:
- Flutter SDK (3.10.8 or higher)
- Android Studio with Android SDK
- A physical Android device or emulator (Android 5.0+)
- Git (for version control)

## 🚀 Quick Start

### 1. Install Dependencies

Open a terminal in the project directory and run:

```bash
flutter pub get
```

This will download all required packages specified in `pubspec.yaml`.

### 2. Generate Hive Adapters (Optional)

The generated files (`medicine.g.dart` and `alarm_log.g.dart`) are already included. If you need to regenerate them:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Add Asset Files

#### Required: Alarm Sound
1. Download an alarm sound in MP3 format (see `assets/sounds/README.md`)
2. Save it as `assets/sounds/alarm.mp3`
3. Recommended sources:
   - https://freesound.org/
   - https://pixabay.com/sound-effects/

#### Optional: Empty State Image
1. Download or create an empty state illustration in PNG format
2. Save it as `assets/images/empty_state.png`
3. See `assets/images/README.md` for recommendations

**Note**: The app will work without these assets, but you should add them for the best experience.

### 4. Connect Android Device

#### Physical Device:
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB cable
4. Run: `flutter devices` to verify connection

#### Emulator:
1. Open Android Studio
2. Open AVD Manager
3. Create/Start an Android emulator
4. Run: `flutter devices` to verify

### 5. Run the App

```bash
flutter run
```

Or use your IDE's run button (VS Code, Android Studio, IntelliJ).

## 📱 Building Release APK

To build a release APK for distribution:

```bash
flutter build apk --release
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

The bundle will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

## ⚙️ Configuration

### Change App Name

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="YourAppName"
    ...
```

### Change App Icon

Replace icons in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`

Or use flutter_launcher_icons package.

### Change Package Name

1. Edit `android/app/build.gradle.kts`:
   ```kotlin
   namespace = "com.yourcompany.yourapp"
   ```

2. Rename directory structure in `android/app/src/main/kotlin/`

## 🔧 Troubleshooting

### Permissions Issues

If alarms don't work:
1. Go to device Settings → Apps → MediRemind
2. Enable all permissions (Notifications, Alarms & Reminders)
3. Disable battery optimization for the app

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Hive Database Issues

If you encounter data issues:
```bash
# Clear app data on device
# Or uninstall and reinstall
```

### Alarm Package Issues

Ensure AndroidManifest.xml has all required permissions (already configured).

## 📖 Usage Guide

### Adding a Medicine

1. Tap the blue `+` button on home screen
2. Enter medicine name (2-50 characters)
3. Select time for reminder
4. Choose repeat schedule:
   - **Daily**: Reminder every day
   - **Custom**: Select specific days
5. Set start date and optional end date
6. Enable/disable alarm
7. Tap "Save Medicine"

### Managing Alarms

- **Pause**: Tap "Pause" button on medicine card
- **Resume**: Tap "Resume" on paused medicine
- **Delete**: Tap "Delete" and confirm
- **View Details**: Tap on medicine card

### When Alarm Rings

You'll see a full-screen alarm with three options:
- **TAKEN** (Green): Mark medicine as taken
- **SNOOZE 5 MIN** (Orange): Delay alarm for 5 minutes
- **DISMISS** (Red): Stop alarm and mark as missed

Auto-dismisses after 2 minutes and marks as missed.

### Viewing History

1. Tap "History" in bottom navigation
2. View last 7/14/30 days (use filter menu)
3. See adherence statistics
4. Review taken/missed medicines by date

## 🧪 Testing

### Manual Testing Checklist

- [ ] Add a medicine with daily schedule
- [ ] Add a medicine with custom days
- [ ] Edit existing medicine
- [ ] Delete a medicine
- [ ] Pause and resume a medicine
- [ ] Test alarm trigger (set for 1 minute ahead)
- [ ] Test snooze functionality
- [ ] Test "taken" action
- [ ] Test "dismiss" action
- [ ] Check history screen
- [ ] Test app restart (alarms should reschedule)

### Testing Alarms

For quick testing, set an alarm for 1-2 minutes in the future:
1. Add medicine with time = current time + 2 minutes
2. Wait for alarm to trigger
3. Verify full-screen alarm appears
4. Test all three buttons

## 📱 Supported Android Versions

- Minimum: Android 5.0 (API 21)
- Target: Android 14 (API 34)
- Tested on: Android 8.0 - 14

## 🔐 Permissions Explained

- **RECEIVE_BOOT_COMPLETED**: Reschedule alarms after device restart
- **VIBRATE**: Vibrate when alarm rings
- **WAKE_LOCK**: Keep device awake for alarm
- **SCHEDULE_EXACT_ALARM**: Schedule alarms at exact time (Android 12+)
- **USE_EXACT_ALARM**: Alternative exact alarm permission
- **FOREGROUND_SERVICE**: Run alarm service
- **REQUEST_IGNORE_BATTERY_OPTIMIZATIONS**: Prevent system from killing app
- **USE_FULL_SCREEN_INTENT**: Show full-screen alarm over lock screen
- **POST_NOTIFICATIONS**: Show alarm notifications
- **SYSTEM_ALERT_WINDOW**: Display alarm over other apps

## 🐛 Known Issues & Limitations

1. **Alarm Sound**: Sound file must be manually added to assets
2. **Android 12+**: User must manually enable "Alarms & Reminders" permission
3. **Battery Optimization**: Some manufacturers aggressively kill background apps
4. **Single User**: App designed for single-user offline use only

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the master_prompt.md for specifications
3. Check console logs for error messages

## 🎉 You're All Set!

The app is now ready to use. Enjoy managing your medicine schedule with MediRemind!
