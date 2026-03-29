import 'package:flutter/foundation.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../services/hive_service.dart';

class WorkoutSessionProvider with ChangeNotifier {
  List<WorkoutSession> _sessions = [];
  WorkoutSession? _currentSession;
  int _currentWeek = 1;

  List<WorkoutSession> get sessions => _sessions;
  WorkoutSession? get currentSession => _currentSession;
  int get currentWeek => _currentWeek;

  WorkoutSessionProvider() {
    loadSessions();
  }

  void loadSessions() {
    _sessions = HiveService.getSessions();
    notifyListeners();
  }

  void startWorkout(String planName, List<Exercise> exercises,
      {int weekNumber = 1}) {
    _currentWeek = weekNumber;
    _currentSession = WorkoutSession(
      date: DateTime.now(),
      planName: planName,
      exercises: exercises,
      weekNumber: weekNumber,
    );
    notifyListeners();
  }

  void updateCurrentSession(WorkoutSession session) {
    _currentSession = session;
    notifyListeners();
  }

  void setCurrentWeek(int week) {
    _currentWeek = week;
    notifyListeners();
  }

  Future<void> saveWorkout() async {
    if (_currentSession != null) {
      await HiveService.addSession(_currentSession!);
      _currentSession = null;
      loadSessions();
    }
  }

  Future<void> deleteSession(int index) async {
    await HiveService.deleteSession(index);
    loadSessions();
  }

  Future<void> updateSession(int index, WorkoutSession session) async {
    await HiveService.updateSession(index, session);
    loadSessions();
  }

  List<int> getWeeksForPlan(String planName) {
    return HiveService.getWeeksForPlan(planName);
  }

  WorkoutSession? getSessionForPlanAndWeek(String planName, int week) {
    return HiveService.getSessionForPlanAndWeek(planName, week);
  }
}
