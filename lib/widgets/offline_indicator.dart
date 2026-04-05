import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  void _initConnectivity() async {
    // Get initial connectivity state
    final isOnline = await _connectivityService.isOnline();
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen(
      (isOnline) {
        if (mounted) {
          setState(() {
            _isOnline = isOnline;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(
        Icons.wifi_off,
        color: errorColor(context),
        size: 20,
        semanticLabel: 'Offline',
      ),
    );
  }
}
