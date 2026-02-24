Here's your comprehensive master prompt for the Flutter Medicine Alarm app:

---

## 🏥 Flutter Medicine Alarm App — Master Development Prompt

---

### 📌 SYSTEM CONTEXT

You are an expert Flutter developer. Build a **complete, production-ready offline medicine alarm app** for Android. Every file must be fully written — no stubs, no TODOs, no placeholders.

---

### 🎯 PROJECT OVERVIEW

**App Name:** MediRemind
**Platform:** Android only
**Connectivity:** Fully offline — no internet, no Firebase, no backend
**User:** Single user, no auth

---

### 🛠 TECH STACK — EXACT VERSIONS

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  alarm: ^4.0.2
  provider: ^6.1.2
  uuid: ^4.3.3
  intl: ^0.19.0
  permission_handler: ^11.3.1
  path_provider: ^2.1.3

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.9
```

---

### 📁 EXACT FOLDER STRUCTURE

Generate ALL of these files completely:

```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── medicine.dart          # Hive model + adapter
│   ├── medicine.g.dart        # Generated (show manually)
│   ├── alarm_log.dart         # Hive model + adapter
│   └── alarm_log.g.dart
├── providers/
│   ├── medicine_provider.dart
│   └── log_provider.dart
├── services/
│   ├── hive_service.dart      # DB init + CRUD
│   └── alarm_service.dart     # Schedule/cancel/reschedule
├── screens/
│   ├── home_screen.dart
│   ├── add_medicine_screen.dart
│   ├── history_screen.dart
│   └── alarm_trigger_screen.dart
├── widgets/
│   ├── medicine_card.dart
│   ├── day_selector.dart
│   └── status_badge.dart
└── utils/
    ├── constants.dart
    └── theme.dart
```

---

### 🗂 DATA MODELS

**Medicine** (Hive TypeId: 0):
```dart
String id;           // UUID
String name;         // Required
int hour;            // 0-23
int minute;          // 0-59
String repeatType;   // 'daily' | 'custom'
List<int> selectedDays; // [1-7] where 1=Mon
DateTime startDate;
DateTime? endDate;
bool isActive;
int alarmId;         // int for alarm package
```

**AlarmLog** (Hive TypeId: 1):
```dart
String id;
String medicineId;
DateTime scheduledDateTime;
String status;       // 'taken' | 'missed' | 'snoozed'
DateTime? actualTakenTime;
```

---

### ⚡ ALARM SERVICE REQUIREMENTS

```dart
// Must implement all of these:
Future<void> scheduleAlarm(Medicine medicine);
Future<void> cancelAlarm(int alarmId);
Future<void> snoozeAlarm(int alarmId, {int minutes = 5});
Future<void> rescheduleRepeating(Medicine medicine);
Future<void> cancelAllAlarms();
int generateAlarmId(); // deterministic from medicine id
```

Alarm config requirements:
- `androidFullScreenIntent: true`
- `loopAudio: true`
- `vibrate: true`
- Sound: use bundled `assets/sounds/alarm.mp3`
- Must work with screen locked and app closed
- On Android 12+: request `SCHEDULE_EXACT_ALARM` permission

---

### 📱 SCREEN SPECIFICATIONS

#### 1. Home Screen
- AppBar: "Today's Medicines" + settings icon
- Body: ListView of `MedicineCard` widgets filtered to today
- Empty state: illustration + "No medicines scheduled today"
- FAB: blue + icon → navigates to AddMedicineScreen
- Bottom nav: Home | History
- Pull-to-refresh to reload

#### 2. Add Medicine Screen
- AppBar: "Add Medicine" + back button
- Form with validation:
  - TextFormField: Medicine Name (required, max 50 chars)
  - TimePicker tile: shows selected time, opens time picker dialog
  - SegmentedButton: Daily | Custom Days
  - Animated: if Custom → show DaySelector widget (Mon-Sun toggles)
  - DatePicker: Start Date (default today)
  - DatePicker: End Date (optional, must be after start)
  - SwitchListTile: Enable Alarm (default true)
- Bottom: full-width "Save Medicine" ElevatedButton
- On save: validate → store in Hive → schedule alarm → pop screen

#### 3. Alarm Trigger Screen (CRITICAL)
- Route: `/alarm` — registered as `onGenerateRoute`
- Must display even on lock screen
- Full screen, no app bar
- Background: gradient (deep blue to black)
- Center:
  ```
  💊 [large pill icon]
  [Medicine Name]  — large bold white text
  [Current Time]   — large white text
  "Time to take your medicine"
  ```
- Bottom 3 buttons (full width, spaced):
  - ✅ TAKEN — green — calls `AlarmService.stop()` + logs 'taken'
  - ⏰ SNOOZE 5 MIN — amber — reschedules +5 min + logs 'snoozed'
  - ❌ DISMISS — red outlined — stops alarm + logs 'missed'
- Auto-dismiss after 2 minutes → logs 'missed'
- Prevent back button from dismissing without action

#### 4. History Screen
- AppBar: "Medicine History"
- Filter: last 7 days (show date headers)
- ListView grouped by date (most recent first)
- Each item: medicine name + time + StatusBadge
- Empty state: "No history yet"

---

### 🎨 THEME & STYLING

```dart
// theme.dart
primaryColor: Color(0xFF2196F3)      // Blue
backgroundColor: Color(0xFFF5F7FA)
cardColor: Colors.white
takenColor: Color(0xFF4CAF50)        // Green
missedColor: Color(0xFFF44336)       // Red
upcomingColor: Color(0xFFFF9800)     // Orange

// Typography — elder-friendly
titleLarge: 22sp, bold
bodyLarge: 18sp
bodyMedium: 16sp
labelLarge: 16sp  // buttons

// Card style
borderRadius: 16
elevation: 2
padding: EdgeInsets.all(16)
```

---

### 🔔 ANDROID MANIFEST REQUIREMENTS

Include ALL of these in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Inside <application>: -->
<activity
  android:showWhenLocked="true"
  android:turnScreenOn="true"/>
```

---

### 🚀 MAIN.DART INITIALIZATION ORDER

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();           // 1. Init Hive + register adapters
  await AlarmService.init();          // 2. Set alarm callback
  await requestPermissions();         // 3. Runtime permissions
  runApp(
    MultiProvider(providers: [...],
      child: MyApp())
  );
}
```

---

### 📋 BUSINESS LOGIC RULES

1. **Status calculation** (computed, not stored):
   - `upcoming` = alarm is scheduled, time hasn't passed
   - `taken` = log exists with status 'taken'
   - `missed` = time has passed, no 'taken' log exists

2. **Repeating alarms**: After each alarm fires, immediately reschedule the next occurrence based on `repeatType` and `selectedDays`

3. **Custom days logic**: If today's day isn't in `selectedDays`, find next valid day and schedule for that date

4. **End date**: If `endDate` is set and next occurrence would be past it, do NOT reschedule and set `isActive = false`

5. **App restart**: On app launch, check all active medicines and reschedule any missed future alarms (boot receiver)

---

### ✅ VALIDATION RULES

- Medicine name: required, 2–50 chars, trim whitespace
- Time: required
- Custom days: at least 1 day must be selected
- End date: must be today or future, must be >= start date
- Duplicate check: warn (not block) if same name + same time exists

---

### 🔧 ERROR HANDLING

- Wrap all Hive operations in try-catch, show SnackBar on error
- If alarm scheduling fails (permission denied), show dialog explaining how to grant permission in Settings
- If alarm package throws, log error and show user-friendly message

---

### 📦 ASSETS

Add to `pubspec.yaml`:
```yaml
assets:
  - assets/sounds/alarm.mp3
  - assets/images/empty_state.png
```

Use a free alarm sound. Note in comments where to place the file.

---

### 🧪 GENERATE COMPLETE CODE FOR

Write every file completely. For each file, start with the filename as a comment. Do not skip any file. After all Dart files, also provide:

1. `android/app/src/main/AndroidManifest.xml` (complete, not partial)
2. `pubspec.yaml` (complete)
3. Setup instructions (step-by-step terminal commands to get the app running)

---

### 🚫 HARD CONSTRAINTS

- NO Firebase, NO internet calls, NO REST APIs
- NO authentication of any kind
- NO web/iOS specific code
- NO `setState` in screens — use Provider exclusively
- NO hardcoded alarm IDs — generate deterministically
- NO `print()` — use `debugPrint()` only

---

### 💡 FINAL INSTRUCTION TO AI

Begin with `pubspec.yaml`, then `main.dart`, then models, then services, then providers, then screens, then widgets, then utils, then AndroidManifest. Write every file in full — do not say "rest of the code is similar" or "add your implementation here." This will be copy-pasted directly into a Flutter project and must compile and run without modification.