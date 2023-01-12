# cleanlet

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Local Dev Setup

The simplest way to get local development running is to use the Firebase Emulator Suite

1. Install Firebase CLI (via NPM or Native)
2. Firebase Login


### Run Flutter App

1. Start Firebase Emulator Suite: `firebase emulators:start --import=./emulator-data`
2. Run Flutter App: `flutter run --dart-define GOOGLE_MAPS_KEY_IOS="xxxxx" --dart-define GOOGLE_MAPS_API_KEY_ANDROID="yyyyy"`
