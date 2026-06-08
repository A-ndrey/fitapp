import 'package:fitapp/ui/core/forms/form_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('humanReadableFormError', () {
    test('rewrites duplicate id errors for named form resources', () {
      expect(
        humanReadableFormError(
          ArgumentError('Duplicate item id: rice'),
          resourceName: 'food',
          fallback: 'Could not save food.',
        ),
        'A food with this name already exists.',
      );
    });

    test('rewrites missing references without leaking ids', () {
      expect(
        humanReadableFormError(
          ArgumentError('Missing exercise id: bench-press'),
          resourceName: 'training',
          fallback: 'Could not save training.',
        ),
        'One of the selected exercises is no longer available.',
      );
    });

    test('keeps useful StateError messages without technical prefixes', () {
      expect(
        humanReadableFormError(
          StateError('Exercise is used by a training plan.'),
          resourceName: 'exercise',
          fallback: 'Could not delete exercise.',
        ),
        'Exercise is used by a training plan.',
      );
    });

    test('uses fallback for empty or generic exception text', () {
      expect(
        humanReadableFormError(
          Exception(''),
          resourceName: 'recipe',
          fallback: 'Could not save recipe.',
        ),
        'Could not save recipe.',
      );

      expect(
        humanReadableFormError(
          Exception('Exception'),
          resourceName: 'recipe',
          fallback: 'Could not save recipe.',
        ),
        'Could not save recipe.',
      );
    });
  });
}
