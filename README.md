# OpenGym

A terminal-style gym workout tracking app built with Flutter.

## Features

- **Workout Tracking** - Log exercises, sets, reps, and weights
- **Plan Management** - Create and manage workout plans
- **PR Tracking** - Automatically track personal records
- **Terminal Aesthetic** - Clean, retro terminal-inspired UI
- **Offline-First** - All data stored locally with Hive

## Screenshots

### Home Screen
![Home Screen](screenshots/home.png)

### Workout Session
![Workout Screen](screenshots/workout.png)

### Exercise Details
![Exercise Details](screenshots/exercise.png)

## Installation

### Prerequisites
- Flutter SDK (3.x or later)
- Dart SDK
- Android Studio or Xcode (for mobile development)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/gymapp.git
   cd gymapp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Building

### Android APK
```bash
flutter build apk --release
```
APK will be at `build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models
├── screens/               # App screens
├── services/              # Business logic
├── widgets/               # Reusable widgets
└── theme/                 # App theming
```

## Tech Stack

- **Flutter** - UI framework
- **Provider** - State management
- **Hive** - Local storage
- **fl_chart** - Charts for progress
- **google_fonts** - JetBrains Mono font

## License

MIT License
