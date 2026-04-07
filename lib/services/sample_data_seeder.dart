import 'dart:async';

import '../models/exercise.dart';
import '../models/exercise_template.dart';
import '../models/set.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/hive_service.dart';
import '../services/sync_queue_service.dart';
import '../services/sync_service.dart';
import 'app_logger.dart';

class SampleDataSeeder {
  static List<WorkoutPlan> buildSamplePlans() {
    return [
      WorkoutPlan(
        name: 'Sample - Push Strength',
        exercises: [
          ExerciseTemplate(name: 'Barbell Bench Press', setDefaults: [
            Set(reps: 6, weight: 70, rpe: 7),
            Set(reps: 6, weight: 70, rpe: 8),
            Set(reps: 5, weight: 72.5, rpe: 8),
            Set(reps: 5, weight: 72.5, rpe: 9),
          ]),
          ExerciseTemplate(name: 'Incline Dumbbell Press', setDefaults: [
            Set(reps: 10, weight: 26, rpe: 7),
            Set(reps: 10, weight: 26, rpe: 8),
            Set(reps: 8, weight: 28, rpe: 9),
          ]),
          ExerciseTemplate(
              name: 'Seated Dumbbell Shoulder Press',
              setDefaults: [
                Set(reps: 8, weight: 22, rpe: 7),
                Set(reps: 8, weight: 22, rpe: 8),
                Set(reps: 7, weight: 24, rpe: 9),
              ]),
          ExerciseTemplate(name: 'Cable Lateral Raise', setDefaults: [
            Set(reps: 15, weight: 7.5, rpe: 7),
            Set(reps: 12, weight: 7.5, rpe: 8),
            Set(reps: 12, weight: 10, rpe: 9),
          ]),
          ExerciseTemplate(name: 'Rope Tricep Pushdown', setDefaults: [
            Set(reps: 12, weight: 27.5, rpe: 7),
            Set(reps: 12, weight: 27.5, rpe: 8),
            Set(reps: 10, weight: 30, rpe: 9),
          ]),
        ],
      ),
      WorkoutPlan(
        name: 'Sample - Pull Hypertrophy',
        exercises: [
          ExerciseTemplate(name: 'Weighted Pull-up', setDefaults: [
            Set(reps: 8, weight: 10, rpe: 7),
            Set(reps: 8, weight: 10, rpe: 8),
            Set(reps: 6, weight: 12.5, rpe: 9),
          ]),
          ExerciseTemplate(name: 'Chest Supported Row', setDefaults: [
            Set(reps: 10, weight: 45, rpe: 7),
            Set(reps: 10, weight: 45, rpe: 8),
            Set(reps: 8, weight: 50, rpe: 9),
          ]),
          ExerciseTemplate(name: 'Wide Grip Lat Pulldown', setDefaults: [
            Set(reps: 12, weight: 50, rpe: 7),
            Set(reps: 10, weight: 52.5, rpe: 8),
            Set(reps: 8, weight: 55, rpe: 9),
          ]),
          ExerciseTemplate(name: 'Face Pull', setDefaults: [
            Set(reps: 15, weight: 17.5, rpe: 6),
            Set(reps: 15, weight: 17.5, rpe: 7),
            Set(reps: 12, weight: 20, rpe: 8),
          ]),
          ExerciseTemplate(name: 'Incline Dumbbell Curl', setDefaults: [
            Set(reps: 12, weight: 12, rpe: 7),
            Set(reps: 10, weight: 14, rpe: 8),
            Set(reps: 8, weight: 14, rpe: 9),
          ]),
        ],
      ),
      WorkoutPlan(
        name: 'Sample - Legs Performance',
        exercises: [
          ExerciseTemplate(name: 'Back Squat', setDefaults: [
            Set(reps: 6, weight: 90, rpe: 7),
            Set(reps: 6, weight: 90, rpe: 8),
            Set(reps: 5, weight: 95, rpe: 9),
            Set(reps: 5, weight: 95, rpe: 9),
          ]),
          ExerciseTemplate(name: 'Romanian Deadlift', setDefaults: [
            Set(reps: 8, weight: 70, rpe: 7),
            Set(reps: 8, weight: 70, rpe: 8),
            Set(reps: 6, weight: 75, rpe: 9),
          ]),
          ExerciseTemplate(name: 'Leg Press', setDefaults: [
            Set(reps: 12, weight: 140, rpe: 7),
            Set(reps: 10, weight: 150, rpe: 8),
            Set(reps: 8, weight: 160, rpe: 9),
          ]),
          ExerciseTemplate(name: 'Seated Hamstring Curl', setDefaults: [
            Set(reps: 12, weight: 35, rpe: 7),
            Set(reps: 10, weight: 37.5, rpe: 8),
            Set(reps: 10, weight: 40, rpe: 9),
          ]),
          ExerciseTemplate(name: 'Standing Calf Raise', setDefaults: [
            Set(reps: 15, weight: 70, rpe: 7),
            Set(reps: 15, weight: 70, rpe: 8),
            Set(reps: 12, weight: 75, rpe: 9),
          ]),
        ],
      ),
    ];
  }

  static List<WorkoutSession> buildSampleSessions({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);
    final startOfWeek = baseDate.subtract(Duration(days: baseDate.weekday - 1));
    final weekOneMonday = startOfWeek.subtract(const Duration(days: 21));

    return [
      WorkoutSession(
        date: weekOneMonday,
        planName: 'Sample - Push Strength',
        weekNumber: 1,
        exercises: [
          Exercise(name: 'Barbell Bench Press', sets: [
            Set(reps: 6, weight: 67.5, rpe: 7),
            Set(reps: 6, weight: 67.5, rpe: 8),
            Set(reps: 5, weight: 70, rpe: 9),
          ]),
          Exercise(name: 'Incline Dumbbell Press', sets: [
            Set(reps: 10, weight: 24, rpe: 7),
            Set(reps: 9, weight: 24, rpe: 8),
            Set(reps: 8, weight: 26, rpe: 9),
          ]),
          Exercise(name: 'Seated Dumbbell Shoulder Press', sets: [
            Set(reps: 8, weight: 20, rpe: 7),
            Set(reps: 8, weight: 20, rpe: 8),
            Set(reps: 7, weight: 22, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 2)),
        planName: 'Sample - Pull Hypertrophy',
        weekNumber: 1,
        exercises: [
          Exercise(name: 'Weighted Pull-up', sets: [
            Set(reps: 8, weight: 7.5, rpe: 7),
            Set(reps: 8, weight: 7.5, rpe: 8),
            Set(reps: 6, weight: 10, rpe: 9),
          ]),
          Exercise(name: 'Chest Supported Row', sets: [
            Set(reps: 10, weight: 42.5, rpe: 7),
            Set(reps: 10, weight: 42.5, rpe: 8),
            Set(reps: 8, weight: 45, rpe: 9),
          ]),
          Exercise(name: 'Wide Grip Lat Pulldown', sets: [
            Set(reps: 12, weight: 47.5, rpe: 7),
            Set(reps: 10, weight: 50, rpe: 8),
            Set(reps: 8, weight: 52.5, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 4)),
        planName: 'Sample - Legs Performance',
        weekNumber: 1,
        exercises: [
          Exercise(name: 'Back Squat', sets: [
            Set(reps: 6, weight: 85, rpe: 7),
            Set(reps: 6, weight: 87.5, rpe: 8),
            Set(reps: 5, weight: 90, rpe: 9),
          ]),
          Exercise(name: 'Romanian Deadlift', sets: [
            Set(reps: 8, weight: 67.5, rpe: 7),
            Set(reps: 8, weight: 67.5, rpe: 8),
            Set(reps: 6, weight: 70, rpe: 9),
          ]),
          Exercise(name: 'Leg Press', sets: [
            Set(reps: 12, weight: 130, rpe: 7),
            Set(reps: 10, weight: 140, rpe: 8),
            Set(reps: 8, weight: 150, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 7)),
        planName: 'Sample - Push Strength',
        weekNumber: 2,
        exercises: [
          Exercise(name: 'Barbell Bench Press', sets: [
            Set(reps: 6, weight: 70, rpe: 7),
            Set(reps: 6, weight: 70, rpe: 8),
            Set(reps: 5, weight: 72.5, rpe: 9),
          ]),
          Exercise(name: 'Incline Dumbbell Press', sets: [
            Set(reps: 10, weight: 25, rpe: 7),
            Set(reps: 9, weight: 25, rpe: 8),
            Set(reps: 8, weight: 27.5, rpe: 9),
          ]),
          Exercise(name: 'Seated Dumbbell Shoulder Press', sets: [
            Set(reps: 8, weight: 21, rpe: 7),
            Set(reps: 8, weight: 21, rpe: 8),
            Set(reps: 7, weight: 23, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 9)),
        planName: 'Sample - Pull Hypertrophy',
        weekNumber: 2,
        exercises: [
          Exercise(name: 'Weighted Pull-up', sets: [
            Set(reps: 8, weight: 10, rpe: 7),
            Set(reps: 8, weight: 10, rpe: 8),
            Set(reps: 6, weight: 10, rpe: 9),
          ]),
          Exercise(name: 'Chest Supported Row', sets: [
            Set(reps: 10, weight: 45, rpe: 7),
            Set(reps: 10, weight: 45, rpe: 8),
            Set(reps: 8, weight: 47.5, rpe: 9),
          ]),
          Exercise(name: 'Wide Grip Lat Pulldown', sets: [
            Set(reps: 12, weight: 50, rpe: 7),
            Set(reps: 10, weight: 52.5, rpe: 8),
            Set(reps: 8, weight: 55, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 11)),
        planName: 'Sample - Legs Performance',
        weekNumber: 2,
        exercises: [
          Exercise(name: 'Back Squat', sets: [
            Set(reps: 6, weight: 87.5, rpe: 7),
            Set(reps: 6, weight: 90, rpe: 8),
            Set(reps: 5, weight: 92.5, rpe: 9),
          ]),
          Exercise(name: 'Romanian Deadlift', sets: [
            Set(reps: 8, weight: 70, rpe: 7),
            Set(reps: 8, weight: 70, rpe: 8),
            Set(reps: 6, weight: 72.5, rpe: 9),
          ]),
          Exercise(name: 'Leg Press', sets: [
            Set(reps: 12, weight: 135, rpe: 7),
            Set(reps: 10, weight: 145, rpe: 8),
            Set(reps: 8, weight: 155, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 14)),
        planName: 'Sample - Push Strength',
        weekNumber: 3,
        exercises: [
          Exercise(name: 'Barbell Bench Press', sets: [
            Set(reps: 6, weight: 72.5, rpe: 7),
            Set(reps: 6, weight: 72.5, rpe: 8),
            Set(reps: 5, weight: 75, rpe: 9),
          ]),
          Exercise(name: 'Incline Dumbbell Press', sets: [
            Set(reps: 10, weight: 26, rpe: 7),
            Set(reps: 9, weight: 26, rpe: 8),
            Set(reps: 8, weight: 28, rpe: 9),
          ]),
          Exercise(name: 'Seated Dumbbell Shoulder Press', sets: [
            Set(reps: 8, weight: 22, rpe: 7),
            Set(reps: 8, weight: 22, rpe: 8),
            Set(reps: 7, weight: 24, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 16)),
        planName: 'Sample - Pull Hypertrophy',
        weekNumber: 3,
        exercises: [
          Exercise(name: 'Weighted Pull-up', sets: [
            Set(reps: 8, weight: 10, rpe: 7),
            Set(reps: 8, weight: 12.5, rpe: 8),
            Set(reps: 6, weight: 12.5, rpe: 9),
          ]),
          Exercise(name: 'Chest Supported Row', sets: [
            Set(reps: 10, weight: 47.5, rpe: 7),
            Set(reps: 10, weight: 47.5, rpe: 8),
            Set(reps: 8, weight: 50, rpe: 9),
          ]),
          Exercise(name: 'Wide Grip Lat Pulldown', sets: [
            Set(reps: 12, weight: 52.5, rpe: 7),
            Set(reps: 10, weight: 55, rpe: 8),
            Set(reps: 8, weight: 57.5, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 18)),
        planName: 'Sample - Legs Performance',
        weekNumber: 3,
        exercises: [
          Exercise(name: 'Back Squat', sets: [
            Set(reps: 6, weight: 90, rpe: 7),
            Set(reps: 6, weight: 92.5, rpe: 8),
            Set(reps: 5, weight: 95, rpe: 9),
          ]),
          Exercise(name: 'Romanian Deadlift', sets: [
            Set(reps: 8, weight: 72.5, rpe: 7),
            Set(reps: 8, weight: 72.5, rpe: 8),
            Set(reps: 6, weight: 75, rpe: 9),
          ]),
          Exercise(name: 'Leg Press', sets: [
            Set(reps: 12, weight: 140, rpe: 7),
            Set(reps: 10, weight: 150, rpe: 8),
            Set(reps: 8, weight: 160, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 21)),
        planName: 'Sample - Push Strength',
        weekNumber: 4,
        exercises: [
          Exercise(name: 'Barbell Bench Press', sets: [
            Set(reps: 6, weight: 72.5, rpe: 8),
            Set(reps: 5, weight: 75, rpe: 9),
            Set(reps: 4, weight: 77.5, rpe: 9),
          ]),
          Exercise(name: 'Incline Dumbbell Press', sets: [
            Set(reps: 10, weight: 27.5, rpe: 7),
            Set(reps: 8, weight: 27.5, rpe: 8),
            Set(reps: 8, weight: 30, rpe: 9),
          ]),
          Exercise(name: 'Seated Dumbbell Shoulder Press', sets: [
            Set(reps: 8, weight: 22, rpe: 8),
            Set(reps: 7, weight: 24, rpe: 8),
            Set(reps: 6, weight: 24, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 23)),
        planName: 'Sample - Pull Hypertrophy',
        weekNumber: 4,
        exercises: [
          Exercise(name: 'Weighted Pull-up', sets: [
            Set(reps: 8, weight: 12.5, rpe: 7),
            Set(reps: 7, weight: 12.5, rpe: 8),
            Set(reps: 6, weight: 15, rpe: 9),
          ]),
          Exercise(name: 'Chest Supported Row', sets: [
            Set(reps: 10, weight: 47.5, rpe: 7),
            Set(reps: 9, weight: 50, rpe: 8),
            Set(reps: 8, weight: 52.5, rpe: 9),
          ]),
          Exercise(name: 'Wide Grip Lat Pulldown', sets: [
            Set(reps: 12, weight: 55, rpe: 7),
            Set(reps: 10, weight: 57.5, rpe: 8),
            Set(reps: 8, weight: 60, rpe: 9),
          ]),
        ],
      ),
      WorkoutSession(
        date: weekOneMonday.add(const Duration(days: 25)),
        planName: 'Sample - Legs Performance',
        weekNumber: 4,
        exercises: [
          Exercise(name: 'Back Squat', sets: [
            Set(reps: 6, weight: 92.5, rpe: 8),
            Set(reps: 5, weight: 95, rpe: 9),
            Set(reps: 4, weight: 97.5, rpe: 9),
          ]),
          Exercise(name: 'Romanian Deadlift', sets: [
            Set(reps: 8, weight: 75, rpe: 7),
            Set(reps: 7, weight: 77.5, rpe: 8),
            Set(reps: 6, weight: 80, rpe: 9),
          ]),
          Exercise(name: 'Leg Press', sets: [
            Set(reps: 12, weight: 145, rpe: 7),
            Set(reps: 10, weight: 155, rpe: 8),
            Set(reps: 8, weight: 165, rpe: 9),
          ]),
        ],
      ),
    ];
  }

  static Future<void> clearAllData() async {
    try {
      // Reset local user data immediately for fresh empty-state UX.
      await HiveService.clearAllPlans();
      await HiveService.clearAllSessions();

      final cacheService = CacheService();
      await cacheService.clearAll();

      // Remove stale pending operations, then enqueue one full server wipe.
      final syncQueueService = SyncQueueService.instance;
      await syncQueueService.clearQueue();
      await syncQueueService.addDataWipeAll();

      // Start server wipe in background so UI can update instantly.
      unawaited(_syncServerWipeInBackground());

      AppLogger.i('All user data cleared locally; server wipe queued');
    } catch (e) {
      AppLogger.e('Error clearing all user data', error: e);
      rethrow;
    }
  }

  static Future<void> _syncServerWipeInBackground() async {
    try {
      final isOnline = await ConnectivityService().isOnline();
      if (!isOnline) {
        return;
      }

      await SyncService.instance.processQueue();
    } catch (e) {
      AppLogger.w('Background server wipe sync failed; will retry later',
          error: e);
    }
  }
}
