# Consulting CRM App

A Flutter-based CRM application for small consulting businesses.

## Project Recreation Guide

### Flutter Version
- Flutter SDK: 3.24.0 (from .metadata)
- Dart SDK: >=3.5.0 <4.0.0 (from pubspec.lock)

### Dependencies
```yaml
dependencies:
  drag_and_drop_lists: 0.4.2
  printing: ^5.0.0
  pdf: ^3.0.0
  flutter_slidable: ^3.0.0
  path: ^1.0.0
  intl: 0.20.2
  sqflite: ^2.0.0
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.0
  fl_chart: ^0.68.0
  google_fonts: 6.1.0
  shared_preferences: 2.3.2
  path_provider: 2.1.4
  provider: 6.1.2
  http: '>=1.0.0'
  uuid: '>=3.0.0'

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Project Structure
```
lib/
  main.dart
  models/
    database_models.dart
    user_model.dart
  screens/
    auth/
    client/
    consultant/
  services/
    auth_service.dart
    database_service.dart
  theme.dart
  widgets/
    kanban_board.dart
    report_card.dart
```

### Setup Instructions
1. Install Flutter SDK (version 3.24.0)
2. Run `flutter pub get` to install dependencies
3. For Android development, ensure INTERNET permission is set in AndroidManifest.xml

### Running the Project
- Use `flutter run` to start the development version
- Use `flutter build` to create production builds

This README contains all necessary information for an AI to recreate this project structure, dependencies, and configuration.