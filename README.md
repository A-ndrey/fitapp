# FitApp

FitApp is a Flutter application for tracking workouts, training plans, food
intake, recipes, and daily nutrition targets. The app is local-first: user data
is saved on the device with `shared_preferences`, and web builds can optionally
sync account data through Firebase Authentication and Cloud Firestore.

This repository contains the Flutter client source code. It is intended to be
easy to run locally without a backend; cloud sync requires your own Firebase
configuration.

## Features

- Today dashboard with daily calorie and protein progress, plus the current or
  next workout.
- Workout tracking with active sessions, set logging, completed workout history,
  duration tracking, and volume summaries.
- Training library for managing reusable training plans and exercises.
- Nutrition log for recording foods or recipes by grams or servings.
- Food library for custom foods and recipes with calories, protein, fat, and
  carbohydrate data.
- Settings for macro targets, light/dark/system appearance, and metric or
  imperial unit preferences.
- Responsive Material UI with bottom navigation on compact screens and a
  navigation rail on wider screens.
- English localization generated from ARB files.
- Optional web account sign-in/sign-up, sync status display, sign-out, and
  account deletion.

## Tech Stack

- Flutter and Dart, with Material Design widgets.
- `ChangeNotifier` app state in `lib/state/app_store.dart`.
- Local persistence through `shared_preferences`.
- Firebase web integration through `firebase_core`, `firebase_auth`, and
  `cloud_firestore`.
- Generated Flutter localization from `lib/l10n/app_en.arb`.
- `flutter_lints` plus stricter analyzer settings in `analysis_options.yaml`.

## Platform Support

The Flutter project contains Android, iOS, web, macOS, Linux, and Windows
platform folders.

Local app tracking works without Firebase. Firebase initialization is currently
enabled only for web builds, so account authentication and Firestore sync are
web-only in the current implementation. On non-web platforms, account actions
surface the app's "Firebase Auth is only available on web." failure message.

## Getting Started

### Prerequisites

- Flutter SDK with Dart `^3.11.4` support.
- A configured Flutter target device, emulator, browser, or desktop runtime.
- Optional for web sync: a Firebase project with Authentication and Firestore
  configured for your own environment.

Check your environment:

```sh
flutter doctor
```

Install dependencies:

```sh
flutter pub get
```

Run the app:

```sh
flutter run
```

Run on Chrome when you want to exercise the web-specific path:

```sh
flutter run -d chrome
```

Build a web release:

```sh
flutter build web
```

## Firebase Web Sync

The app can sync web account data through Firebase Auth and Cloud Firestore.
The checked-in Firebase files reflect one development configuration, but public
contributors should configure their own Firebase project before relying on
cloud sync.

The sync flow is:

1. The app loads local state from `shared_preferences`.
2. When a web user signs in, Firebase initializes and starts background sync.
3. The sync coordinator reconciles local state with the remote Firestore
   snapshot.
4. Local persisted-state changes enqueue a remote upload.
5. Deleting an account removes the remote state document and then deletes the
   Firebase Auth account.

To use sync with your own Firebase project:

1. Create a Firebase project.
2. Register a web app.
3. Enable Email/Password sign-in in Firebase Authentication.
4. Enable Cloud Firestore.
5. Generate Flutter Firebase options for your project.
6. Replace the local Firebase configuration with your generated values.
7. Add Firestore security rules that allow each authenticated user to read and
   write only their own `users/{uid}/state/current` document.

The remote app-state document path is:

```text
users/{uid}/state/current
```

Deploy a web build only after configuring Firebase for your own project:

```sh
flutter build web
firebase deploy
```

## Project Structure

```text
lib/
  main.dart                         App startup, navigation, sync bootstrap
  firebase/                         Firebase initialization abstraction
  firebase_options.dart             Generated Firebase options
  l10n/                             ARB source and generated localizations
  models/                           Immutable domain models
  screens/                          Today, workout, nutrition, library, settings
  state/
    app_store.dart                  Central app state and mutations
    auth/                           Auth service abstraction and Firebase auth
    persistence/                    Local persisted state codec/storage
    sync/                           Firestore sync coordinator and status
  ui/                               Reusable layout, theme, and feature widgets
  widgets/                          Food, recipe, and shared form widgets
test/                               Widget, model, persistence, sync, and UI tests
fonts/lexend/                       Bundled Lexend font
```

## Data Model

FitApp stores a single persisted app snapshot containing:

- User preferences: appearance, language, units, and daily macro targets.
- User-defined foods and recipes.
- Meal entries and calculated nutrition totals.
- User-defined exercises and training plans.
- Active workout session, if one exists.
- Completed workout sessions.

The app also bootstraps sample foods, exercises, and training plans. Built-in
items are protected from destructive edits where necessary, and user-created
items are validated before being saved.

## Development

Run static analysis:

```sh
flutter analyze
```

Run all tests:

```sh
flutter test
```

Format Dart files:

```sh
dart format .
```

Regenerate localizations after editing ARB files:

```sh
flutter gen-l10n
```

Useful test areas:

- `test/state/app_store_test.dart` covers core state behavior.
- `test/state/persistence/*` covers local serialization and metadata storage.
- `test/state/sync/*` covers sync reconciliation and Firestore service behavior.
- `test/widgets/*` and `test/screens/*` cover UI forms and flows.
- `test/localization_test.dart` checks generated localization behavior.

## Localization

Localization is configured in `l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

Edit `lib/l10n/app_en.arb` for English strings, then regenerate localization
files. The generated `app_localizations*.dart` files should not be edited by
hand.

## Persistence Notes

Local data is stored under these `shared_preferences` keys:

- `app_store_state_v1` for the persisted application snapshot.
- Sync metadata keys in `SharedPreferencesSyncMetadataStore`.
- Installation identity keys in `InstallationIdStore` when that fallback is
  used.

The web auth path uses the Firebase user id as the sync identity. Remote
snapshots are schema-versioned and include a hash so the coordinator can detect
matching, stale, or unsynced state.

## Quality Expectations

- Keep app state mutations inside `AppStore` or the existing state services.
- Add tests for changes to persistence, sync, validation, or user-facing flows.
- Prefer existing UI components in `lib/ui` and `lib/widgets` before adding new
  patterns.
- Run `dart format .`, `flutter analyze`, and `flutter test` before merging.

## License

See `LICENSE`.
