import 'package:flutter/foundation.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/set.dart' as gym;
import '../repositories/workout_session_repository.dart';

class WorkoutSessionProvider with ChangeNotifier {
  final WorkoutSessionRepository _repository = WorkoutSessionRepository();
  List<WorkoutSession> _sessions = [];
  WorkoutSession? _currentSession;
  int _currentWeek = 1;
  String? _error;
  bool _isLoading = false;

  List<WorkoutSession> get sessions => _sessions;
  WorkoutSession? get currentSession => _currentSession;
  int get currentWeek => _currentWeek;
  String? get error => _error;
  bool get isLoading => _isLoading;
  WorkoutSessionRepository get repository => _repository;

  WorkoutSessionProvider() {
    loadSessions();
  }

  void loadSessions() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _sessions = await _repository.getSessionsAsync();
    } catch (e) {
      // The ApiService now provides user-friendly error messages
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startWorkout(String planName, List<Exercise> exercises,
      {int weekNumber = 1}) {
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
    if (_currentSession == null) return;

    try {
      _error = null;

      final sessions = _repository.cachedSessions;
      final existingIndex = sessions.indexWhere(
        (s) =>
            s.planName.toLowerCase() ==
                _currentSession!.planName.toLowerCase() &&
            s.weekNumber == _currentSession!.weekNumber,
      );

      if (existingIndex != -1) {
        await _repository.updateSession(existingIndex, _currentSession!);
      } else {
        await _repository.addSession(_currentSession!);
      }

      // Since repository uses optimistic updates, refresh our provider's cache
      _sessions = _repository.cachedSessions;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> addSession(WorkoutSession session) async {
    try {
      _error = null;
      await _repository.addSession(session);
      _sessions = _repository.cachedSessions;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deleteSession(int index) async {
    try {
      _error = null;
      await _repository.deleteSession(index);
      _sessions = _repository.cachedSessions;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> updateSession(int index, WorkoutSession session) async {
    try {
      _error = null;
      await _repository.updateSession(index, session);
      _sessions = _repository.cachedSessions;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> updateSessionObject(WorkoutSession session) async {
    try {
      _error = null;

      // Find the session in the current list
      final index = _sessions.indexWhere((s) =>
          s.planName.toLowerCase() == session.planName.toLowerCase() &&
          s.weekNumber == session.weekNumber &&
          s.date.isAtSameMomentAs(session.date));

      if (index != -1) {
        await _repository.updateSession(index, session);
        _sessions = _repository.cachedSessions;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  WorkoutSession? getSessionForPlanAndWeek(String planName, int week) {
    return _repository.getSessionForPlanAndWeek(planName, week);
  }

  List<int> getWeeksForPlan(String planName) {
    return _repository.getWeeksForPlan(planName);
  }

  gym.Set? getLastSetForExercise(String exerciseName) {
    return _repository.getLastSetForExercise(exerciseName);
  }

  Future<void> renameSessionWeek(
      String planName, int oldWeek, int newWeek) async {
    try {
      _error = null;
      await _repository.renameSessionWeek(planName, oldWeek, newWeek);
      _sessions = _repository.cachedSessions;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deleteSessionForPlanAndWeek(
      String planName, int weekNumber) async {
    try {
      _error = null;
      await _repository.deleteSessionForPlanAndWeek(planName, weekNumber);
      _sessions = _repository.cachedSessions;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  int get workoutsThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return _sessions.where((s) => s.date.isAfter(startDate)).length;
  }

  void clearLocalState() {
    _repository.clearCachedSessions();
    _sessions = [];
    _currentSession = null;
    _currentWeek = 1;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
