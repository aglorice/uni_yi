# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **uni_yi**, an all-in-one campus assistant app for Wuyi University students. Built with Flutter, it supports multiple platforms (Android, iOS, Web, macOS, Linux, Windows).

The project is currently in early development stage with the default Flutter counter demo app as the foundation.

## Development Commands

### Running the Application

```bash
# Run on connected device/emulator (hot reload enabled)
flutter run

# Run on specific platform
flutter run -d chrome          # Web
flutter run -d macos           # macOS
flutter run -d windows         # Windows
flutter run -d linux           # Linux

# Run without hot reload
flutter run --no-hot-reload
```

### Building

```bash
# Build for Android
flutter build apk                          # Debug APK
flutter build appbundle --release          # Release App Bundle (for Play Store)

# Build for iOS
flutter build ios                          # iOS (requires macOS and Xcode)

# Build for other platforms
flutter build web                          # Web
flutter build macos                        # macOS
flutter build windows                      # Windows
flutter build linux                        # Linux
```

### Testing and Analysis

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Check for outdated dependencies
flutter pub outdated
```

### Dependency Management

```bash
# Install dependencies
flutter pub get

# Upgrade dependencies to latest versions
flutter pub upgrade

# Interactive dependency upgrade
flutter pub upgrade --major-versions
```

### Hot Reload/Restart

While the app is running:
- Press `r` in the terminal to trigger hot reload (preserves app state)
- Press `R` to trigger hot restart (resets app state)
- Press `q` to quit

## Project Structure

### Core Files

- `lib/main.dart` - Entry point containing `MyApp` (root widget) and `MyHomePage` (demo home page)
- `pubspec.yaml` - Dependencies and project configuration
- `analysis_options.yaml` - Dart analyzer configuration using `flutter_lints` rules

### Platform-Specific Code

- `android/` - Android native code (Kotlin/Java)
- `ios/` - iOS native code (Swift/Objective-C)
- `web/` - Web-specific assets and configuration
- `macos/` - macOS native code
- `windows/` - Windows native code (C++)
- `linux/` - Linux native code

### Configuration Files

- Android: `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`
- App name: "uni_yi" (set in AndroidManifest.xml)

## Architecture Notes

### Current State

The app currently uses Flutter's default counter demo architecture:
- `MyApp` - Root `StatelessWidget` with MaterialApp and theme configuration
- `MyHomePage` - Demo `StatefulWidget` with counter functionality
- Uses Material Design 3 with `ColorScheme.fromSeed()`

### State Management

Currently using basic `setState()` for local state management. As the app grows, consider:
- Provider for simple state management
- Riverpod for more complex scenarios
- Bloc/Cubit for business logic separation

### Navigation

Currently uses direct widget instantiation. For a campus assistant app with multiple features, implement:
- Named routes with `routes` parameter in MaterialApp
- Navigation libraries (go_router, auto_route) for deep linking and complex navigation

## Development Guidelines

### Code Organization

As the app expands, structure the `lib/` directory with feature-based organization:

```
lib/
├── main.dart
├── core/           # Shared utilities, constants, themes
├── features/       # Feature modules (schedule, grades, campus map, etc.)
└── shared/         # Shared widgets and components
```

### Platform Channel Considerations

This campus assistant app may need native platform features:
- Use Platform Channels (MethodChannel/EventChannel) for native communication
- Keep platform-specific code in respective platform directories
- Test on all target platforms before release

### Multi-Platform Testing

Always test on target platforms:
- Web: Chrome, Safari, Firefox
- Desktop: macOS, Windows, Linux (if supported)
- Mobile: Android, iOS (requires macOS for iOS builds)

## Common Issues

### Hot Reload Not Working
- Make changes to `build()` method or widget tree
- Some changes (like `main()` function, generics) require hot restart (`R`)
- State changes during hot reload may behave unexpectedly

### Platform-Specific Builds
- iOS builds require macOS with Xcode
- Android builds work on any platform
- Web builds require no additional tools

### Dependency Conflicts
- Run `flutter pub get` after modifying `pubspec.yaml`
- Check `flutter doctor` for environment issues
- Use `flutter clean` if experiencing build issues
