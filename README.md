# medibuddy

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Libraries and usage

- `flutter` (SDK): Provides the `material` widgets that build the login UI, form handling, the `CircularProgressIndicator` spinner animation, buttons, text fields, and the navigator stack that could later be wired to real screens.
- `cupertino_icons`: Supplies the iOS-style icon glyphs (we currently use `Icons.g_mobiledata` inside the Google sign-in button) so the app looks consistent across platforms.

## Development tooling

- `flutter_test`: Enables unit and widget testing for the login flow once we add test files.
- `flutter_lints`: Applies the recommended lint rules configured in `analysis_options.yaml` to keep the Dart codebase consistent.

## Assets & services

- `assets/cat_login.png`: A friendly illustration shown in the login screen.
- `lib/services/mock_auth_service.dart`: A mock login service that validates a fixed email/password pair before we replace it with real API calls.

## Login with Google
- `lib/services/mock_auth_service.dart` 
   Run this command: flutter pub add google_sign_in 
