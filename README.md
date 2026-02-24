# MediRemind - Medicine Alarm App 💊

A complete, production-ready offline medicine reminder app for Android built with Flutter.

## 🎯 Features

- ✅ **Offline First**: No internet, no Firebase, no backend required
- ⏰ **Reliable Alarms**: Exact alarm scheduling with full-screen notifications
- 📅 **Flexible Scheduling**: Daily or custom day selection
- 📊 **History Tracking**: View medicine adherence with statistics
- 🔔 **Snooze Function**: 5-minute snooze option
- 📱 **Elder-Friendly UI**: Large text, simple navigation, clear icons
- 🎨 **Material Design 3**: Modern, clean interface
- 🔋 **Battery Optimized**: Efficient alarm management

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.10.8 or higher
- Android Studio or VS Code
- Android device or emulator (Android 5.0+)

### Installation

1. **Clone or navigate to project directory**
   ```bash
   cd medi_reminder
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Add required assets** (see [SETUP.md](SETUP.md))
   - Place `alarm.mp3` in `assets/sounds/`
   - Optionally add `empty_state.png` to `assets/images/`

4. **Run the app**
   ```bash
   flutter run
   ```

📖 **For detailed setup instructions, see [SETUP.md](SETUP.md)**

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point with initialization
├── app.dart                  # Main app widget with routing
├── models/                   # Data models
│   ├── medicine.dart         # Medicine model
│   ├── medicine.g.dart       # Generated Hive adapter
│   ├── alarm_log.dart        # Log model
│   └── alarm_log.g.dart      # Generated Hive adapter
├── services/                 # Business logic
│   ├── hive_service.dart     # Database operations (CRUD)
│   └── alarm_service.dart    # Alarm scheduling and management
├── providers/                # State management (Provider pattern)
│   ├── medicine_provider.dart
│   └── log_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart      # Main screen with today's medicines
│   ├── add_medicine_screen.dart  # Add/edit medicine form
│   ├── alarm_trigger_screen.dart # Full-screen alarm notification
│   └── history_screen.dart   # Medicine history and statistics
├── widgets/                  # Reusable widgets
│   ├── medicine_card.dart    # Medicine list item
│   ├── day_selector.dart     # Custom day picker
│   └── status_badge.dart     # Status indicator (taken/missed/upcoming)
└── utils/                    # Constants and theme
    ├── constants.dart        # App constants and colors
    └── theme.dart            # Theme configuration
```

## 🏗️ Architecture

- **Database**: Hive (local NoSQL)
- **State Management**: Provider
- **Alarms**: alarm package (native Android alarms)
- **Data Flow**: Unidirectional (Provider -> UI)
- **Pattern**: Clean Architecture

## 📱 Screens

### Home Screen
- Today's scheduled medicines
- Quick status view (taken/missed/upcoming)
- Pull to refresh
- Navigation to History

### Add Medicine Screen
- Medicine name input
- Time picker
- Repeat schedule selector (daily/custom days)
- Start/end date pickers
- Active status toggle

### Alarm Trigger Screen
- Full-screen overlay (works on lock screen)
- Large medicine name and time
- Three actions: Taken, Snooze 5 min, Dismiss
- Auto-dismiss after 2 minutes

### History Screen
- Last 7/14/30 days filter
- Grouped by date
- Adherence statistics
- Color-coded status indicators

## 🔔 Permissions

The app requires these Android permissions (already configured):
- `RECEIVE_BOOT_COMPLETED` - Reschedule alarms after device restart
- `VIBRATE` - Vibrate when alarm rings
- `WAKE_LOCK` - Wake device for alarm
- `SCHEDULE_EXACT_ALARM` - Schedule exact-time alarms (Android 12+)
- `USE_FULL_SCREEN_INTENT` - Show full-screen alarm on lock screen
- `POST_NOTIFICATIONS` - Display notifications

## 🎨 Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.10.8 |
| Language | Dart |
| Database | Hive 2.2.3 |
| State Management | Provider 6.1.2 |
| Alarms | alarm 4.0.2 |
| Permissions | permission_handler 11.3.1 |
| Local Storage | hive_flutter 1.1.0 |

## 📊 Database Schema

### Medicine Model
```dart
{
  id: String (UUID),
  name: String,
  hour: int (0-23),
  minute: int (0-59),
  repeatType: String ('daily'|'custom'),
  selectedDays: List<int> (1-7, Mon-Sun),
  startDate: DateTime,
  endDate: DateTime? (optional),
  isActive: bool,
  alarmId: int
}
```

### AlarmLog Model
```dart
{
  id: String (UUID),
  medicineId: String,
  scheduledDateTime: DateTime,
  status: String ('taken'|'missed'|'snoozed'),
  actualTakenTime: DateTime? (optional)
}
```

## 🛠️ Building

### Debug APK
```bash
flutter build apk --debug
```

### Release APK
```bash
flutter build apk --release
```

### App Bundle (Google Play)
```bash
flutter build appbundle --release
```

## 🧪 Testing

Run widget tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

## 📝 License

This project is provided as-is for educational and personal use.

## 🤝 Contributing

This is a complete project based on specific requirements. Feel free to fork and customize for your needs.

## 🐛 Known Issues

- Asset files must be manually added (alarm.mp3 required)
- Android 12+ requires manual "Alarms & Reminders" permission
- Some manufacturers aggressively kill background apps (requires battery optimization exemption)

## 📞 Support

For issues:
1. Check [SETUP.md](SETUP.md) troubleshooting section
2. Review console logs for errors
3. Ensure all permissions are granted

## 🎉 Credits

Built with Flutter by following modern app development best practices.

---

**Made with ❤️ for better health management**
