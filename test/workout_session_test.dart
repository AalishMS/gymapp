import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/models/workout_session.dart';

void main() {
  test('copyWith preserves id when id is not overridden', () {
    final session = WorkoutSession(
      id: 'server-session-id',
      date: DateTime(2026, 1, 1),
      planName: 'Push Day',
      exercises: const [],
      weekNumber: 1,
    );

    final updated = session.copyWith(weekNumber: 2);

    expect(updated.id, 'server-session-id');
  });
}
