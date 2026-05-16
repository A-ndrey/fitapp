# Workout Floating Action Design

## Goal

Replace the idle-state "Start workout" card on the workout screen with a persistent floating primary action that remains visible whether a workout session is active or not.

## User-Facing Behavior

- The workout screen always shows one floating action button.
- When no workout session is active, the button starts the existing workout flow by opening the training plan picker.
- When a workout session is active, the same button reopens the active workout session screen.
- The existing active workout summary card remains in the page body.
- The idle-state "Start workout" card is removed from the page body so the primary action is not duplicated.

## Implementation

- Update `WorkoutScreen` to derive the floating action button label, tooltip, icon, and tap handler from `store.activeWorkoutSession`.
- Reuse the existing `_openStartWorkoutPicker` and `_openActiveWorkout` methods so the change only affects the entry point, not the underlying flows.
- Remove the conditional body branch that renders the idle-state `ActionCard`.
- Leave the active workout card, workout stats, and workout history sections unchanged.

## Testing

- Update widget tests for the workout screen to assert the floating action button is present when idle and when a workout is active.
- Assert that the idle-state "Start workout" card is no longer rendered in the body.
- Assert that tapping the floating action button when a workout is active navigates to the workout session screen.

## Constraints

- Keep the existing localization keys and fallback strings unless a test proves a new string is necessary.
- Do not introduce a second primary workout action anywhere else on the screen.
