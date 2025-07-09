# health_sync_plugin

A Flutter plugin to sync health data from Health Connect-compatible apps on Android.

## Features

- Discover installed Health Connect-compatible provider apps (Google Fit, Samsung Health, etc.).
- Sync health data like steps, heart rate, blood pressure, glucose, and more.
- Background syncing using a foreground service with Flutter Foreground Task.
- Stores daily averages of health data.
- Supports permission handling for Health Connect and sensors.
- Works seamlessly with Firebase for cloud storage (optional).

## Getting Started

This plugin provides platform-specific implementations for Android using Health Connect APIs. You can integrate it into your Flutter app to access and sync user health data from multiple providers.

### Installation

Add this plugin to your `pubspec.yaml`:

```yaml
dependencies:
  health_sync_plugin:
    path: ../path_to_plugin  # Or use your plugin's hosted location
