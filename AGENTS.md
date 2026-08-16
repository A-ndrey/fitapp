# AGENTS.md

## Purpose

This repository is a Flutter client for FitApp. It tracks workouts, training
plans, meals, foods, recipes, and daily nutrition targets.

The app is local-first:

- mutable app state is owned by `AppStore`
- local persistence uses `shared_preferences`
- Firebase auth and Firestore sync are currently web-only

## Stack

- Flutter
- Dart `^3.11.4`
- Material UI
- `ChangeNotifier` state via `lib/state/app_store.dart`
- Generated localization from `lib/l10n/app_en.arb`
- Firebase web integration through `firebase_core`, `firebase_auth`, and
  `cloud_firestore`

## Important Paths

- `lib/main.dart`: app bootstrap, hydration, navigation, sync wiring
- `lib/state/`: app state, auth, persistence, and sync services
- `lib/models/`: immutable domain models
- `lib/screens/`: top-level screens
- `lib/ui/`: reusable layout, theme, and feature widgets
- `lib/widgets/`: shared forms and editing widgets
- `test/`: widget, model, persistence, sync, and UI coverage
- `docs/`: local-only design and planning notes

## Working Rules

- Keep state mutations inside `AppStore` or the existing state service layer.
- Prefer existing widgets and layout helpers before adding new UI patterns.
- Keep Firebase-specific logic out of general domain models and out of most
  screens unless the existing structure already routes it there.
- Treat generated localization files as generated output. Edit
  `lib/l10n/app_en.arb`, then run localization generation.
- Respect the current responsive structure. The app already supports compact and
  wide layouts.

## Quality Bar

Before finishing a change, run the relevant commands:

```sh
dart format .
flutter analyze
flutter test
```

Use narrower test runs while iterating when possible, then expand to the
relevant broader suite for the final check.

## Common Commands

```sh
flutter pub get
flutter run
flutter run -d chrome
flutter build web
flutter gen-l10n
```

## Testing Guidance

- Add or update tests for persistence changes.
- Add or update tests for sync behavior.
- Add or update tests for validation logic.
- Add or update tests for user-facing flows or responsive UI behavior.
- Prefer focused tests near the changed feature first, then run broader checks.

Useful existing areas:

- `test/state/app_store_test.dart`
- `test/state/persistence/`
- `test/state/sync/`
- `test/widgets/`
- `test/screens/`
- `test/localization_test.dart`

## Docs Rule

`docs/` is ignored by git in this repository.

- Do not commit files under `docs/`.
- Do not force-add ignored docs files.
- Keep design, spec, and planning notes under `docs/` local-only unless the
  user explicitly asks to change that policy.
