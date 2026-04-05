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
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_currentSession != null) {
        await _repository.addSession(_currentSession!);
        _currentSession = null;
        loadSessions();
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSession(int index) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteSession(index);
      loadSessions();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSession(int index, WorkoutSession session) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateSession(index, session);
      loadSessions();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  List<int> getWeeksForPlan(String planName) {
    return _repository.getWeeksForPlan(planName);
  }

  WorkoutSession? getSessionForPlanAndWeek(String planName, int week) {
    return _repository.getSessionForPlanAndWeek(planName, week);
  }

  gym.Set? getLastSetForExercise(String exerciseName) {
    return _repository.getLastSetForExercise(exerciseName);
  }

  Future<void> renameSessionWeek(
      String planName, int oldWeek, int newWeek) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.renameSessionWeek(planName, oldWeek, newWeek);
      loadSessions();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSessionForPlanAndWeek(
      String planName, int weekNumber) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteSessionForPlanAndWeek(planName, weekNumber);
      loadSessions();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }
}
