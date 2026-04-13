# Harvest Tracker

A personal Flutter web app for logging time entries to [Harvest](https://www.getharvest.com/) directly from the browser.

## Features

- **Project & task selection** — loads your assigned projects and tasks from the Harvest API, with cascading dropdowns
- **Default project & task** — configure a default project and task in Settings so the form is pre-filled on load
- **Hours & minutes input** — pick hours (0–24) and minutes (5-minute intervals) instead of typing decimals
- **Azure DevOps linking** — optionally link a work item from two configured ADO instances:
  - **Transport** (`codecollective1`)
  - **TFN Project** (`agile-bridge`)
  - Permalink is auto-constructed from the work item number; notes are automatically prefixed with e.g. `Transport Azure DevOps User Story #13483`
- **Daily entries view** — browse entries by day with prev/next navigation and a date picker
- **8-hour progress bar** — visual indicator of daily progress toward the 8h goal, with overflow tracking

## Project Structure

```
lib/
├── main.dart
├── config/
│   └── app_config.dart          # credentials & ADO config (gitignored)
├── models/
│   ├── project_assignment.dart
│   └── time_entry.dart
├── services/
│   └── harvest_service.dart     # Harvest API v2 calls
├── providers/
│   ├── assignment_provider.dart
│   └── time_entry_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── log_time_screen.dart
│   ├── recent_entries_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── error_banner.dart
    ├── project_task_selector.dart
    └── time_entry_card.dart
```

## Setup

### 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (web support enabled)
- A [Harvest personal access token](https://id.getharvest.com/developers)

### 2. Configure credentials

Create `lib/config/app_config.dart` (this file is gitignored — never commit it):

```dart
import '../models/time_entry.dart';

class AppConfig {
  static const String defaultToken = 'YOUR_HARVEST_TOKEN';
  static const String defaultAccountId = 'YOUR_ACCOUNT_ID';
  static const int userId = YOUR_USER_ID;
  static const String userAgent = 'YourName (your@email.com)';
  static const String baseUrl = 'https://api.harvestapp.com/v2';

  static const List<AdoInstance> adoInstances = [
    AdoInstance(
      label: 'Transport',
      baseUrl: 'https://dev.azure.com/your-org/Your-Project/_workitems/edit/',
    ),
  ];
}
```

### 3. Install dependencies & run

```bash
flutter pub get
flutter run -d web-server --web-port=8080
```

Then open `http://localhost:8080` in Chrome.

### 4. Build for production

```bash
flutter build web --release
```

Serve the `build/web` directory from any static host.

## Runtime credential override

Credentials can be changed at runtime via the **Settings** tab without recompiling. Values are stored in browser `localStorage` and take precedence over the compiled-in defaults.
