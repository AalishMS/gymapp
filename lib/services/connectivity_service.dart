import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import 'app_logger.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  final SyncService _syncService = SyncService.instance;

  bool _wasOffline = false;

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isNowOnline = _isConnected(results);
    _connectivityController.add(isNowOnline);

    // If we were offline and now we're online, trigger sync
    if (_wasOffline && isNowOnline) {
      _triggerSync();
    }

    _wasOffline = !isNowOnline;
  }

  void _triggerSync() async {
    try {
      await _syncService.processQueue();
    } catch (e) {
      AppLogger.e('Sync failed when connectivity was restored', error: e);
    }
  }

  void startListening() {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    isOnline().then((online) {
      _connectivityController.add(online);
      _wasOffline = !online;
    });
  }

  void dispose() {
    _connectivityController.close();
  }
}
