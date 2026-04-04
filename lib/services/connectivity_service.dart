import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

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
    _connectivityController.add(_isConnected(results));
  }

  void startListening() {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    isOnline().then((online) => _connectivityController.add(online));
  }

  void dispose() {
    _connectivityController.close();
  }
}
