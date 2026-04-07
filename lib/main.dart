import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/workout_plan_provider.dart';
import 'providers/workout_session_provider.dart';
import 'providers/progression_provider.dart';
import 'providers/settings_provider.dart';
import 'services/hive_service.dart';
import 'services/sync_queue_service.dart';
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'services/app_logger.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? initError;
  HiveInitResult? hiveInitResult;

  try {
    hiveInitResult = await HiveService.init();
    if (hiveInitResult.requiresRecovery == false) {
      await SyncQueueService.instance.init();
    }
  } catch (e) {
    initError = e;
  }

  runApp(MyApp(initError: initError, hiveInitResult: hiveInitResult));
}

class MyApp extends StatefulWidget {
  final Object? initError;
  final HiveInitResult? hiveInitResult;

  const MyApp({super.key, this.initError, this.hiveInitResult});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _needsRecovery = false;
  bool _isRecovering = false;
  String? _recoveryError;
  HiveInitResult? _recoveryState;
  late WorkoutPlanProvider _workoutPlanProvider;
  late WorkoutSessionProvider _workoutSessionProvider;
  late ProgressionProvider _progressionProvider;
  late SettingsProvider _settingsProvider;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.hiveInitResult?.requiresRecovery ?? false) {
      setState(() {
        _needsRecovery = true;
        _recoveryState = widget.hiveInitResult;
        _initialized = true;
      });
      return;
    }

    await _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    _workoutPlanProvider = WorkoutPlanProvider();
    _workoutSessionProvider = WorkoutSessionProvider();
    _progressionProvider = ProgressionProvider();
    _settingsProvider = SettingsProvider();

    // Set up repository references in SyncService for post-sync refreshes
    SyncService.instance.setRepositories(
      _workoutPlanProvider.repository,
      _workoutSessionProvider.repository,
    );

    _connectivityService.startListening();

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _recoverAffectedBoxes() async {
    setState(() {
      _isRecovering = true;
      _recoveryError = null;
    });

    try {
      await HiveService.recoverCorruptedBoxes();
      await SyncQueueService.instance.init();
      await _initializeProviders();

      if (mounted) {
        setState(() {
          _needsRecovery = false;
          _recoveryState = null;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to recover corrupted Hive boxes', error: e);
      if (mounted) {
        setState(() {
          _recoveryError =
              'Could not recover affected local data. You can retry or reset local storage.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  Future<void> _resetLocalStorage({required bool restoreBackup}) async {
    setState(() {
      _isRecovering = true;
      _recoveryError = null;
    });

    try {
      await HiveService.resetDatabase(restoreFromBackup: restoreBackup);
      await SyncQueueService.instance.init();
      await _initializeProviders();

      if (mounted) {
        setState(() {
          _needsRecovery = false;
          _recoveryState = null;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to reset local Hive storage', error: e);
      if (mounted) {
        setState(() {
          _recoveryError =
              'Reset failed. Please restart the app and try recovery again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  Future<void> _confirmAndReset({required bool restoreBackup}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            restoreBackup ? '> RESTORE BACKUP' : '> RESET LOCAL DATA',
            style: GoogleFonts.jetBrainsMono(),
          ),
          content: Text(
            restoreBackup
                ? 'This will reset local storage and restore from the latest backup snapshot when possible.'
                : 'This will remove all local workout data on this device. Cloud data remains intact.',
            style: GoogleFonts.jetBrainsMono(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('[ CANCEL ]', style: GoogleFonts.jetBrainsMono()),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('[ CONFIRM ]', style: GoogleFonts.jetBrainsMono()),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _resetLocalStorage(restoreBackup: restoreBackup);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to initialize local storage. Please restart the app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '> OPENGYM',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00A8FF),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF00A8FF),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_needsRecovery) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '> LOCAL STORAGE ISSUE DETECTED',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF6B6B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _recoveryState?.message ??
                          'OpenGym detected local storage corruption.',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Affected boxes: ${_recoveryState?.failedBoxes.join(', ') ?? HiveService.failedBoxes.join(', ')}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: const Color(0xFFB0B0B0),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_recoveryError != null)
                      Text(
                        _recoveryError!,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFFFF6B6B),
                        ),
                      ),
                    if (_recoveryError != null) const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isRecovering ? null : _recoverAffectedBoxes,
                        child: Text(
                          _isRecovering
                              ? '[ RECOVERING... ]'
                              : '[ RECOVER AFFECTED DATA ]',
                          style: GoogleFonts.jetBrainsMono(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_recoveryState?.backupAvailable == true)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isRecovering
                              ? null
                              : () => _confirmAndReset(restoreBackup: true),
                          child: Text(
                            '[ RESET + RESTORE BACKUP ]',
                            style: GoogleFonts.jetBrainsMono(),
                          ),
                        ),
                      ),
                    if (_recoveryState?.backupAvailable == true)
                      const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isRecovering
                            ? null
                            : () => _confirmAndReset(restoreBackup: false),
                        child: Text(
                          '[ RESET LOCAL DATA ]',
                          style: GoogleFonts.jetBrainsMono(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _workoutPlanProvider),
        ChangeNotifierProvider.value(value: _workoutSessionProvider),
        ChangeNotifierProvider.value(value: _progressionProvider),
        ChangeNotifierProvider.value(value: _settingsProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final accentDark = settingsProvider.accentColorDark;
          final accentLight = settingsProvider.accentColorLight;

          return MaterialApp(
            title: 'OpenGym',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(accentLight, Brightness.light),
            darkTheme: buildTheme(accentDark, Brightness.dark),
            themeMode: settingsProvider.themeMode,
            initialRoute: '/splash',
            onGenerateRoute: (routeSettings) {
              switch (routeSettings.name) {
                case '/splash':
                  return MaterialPageRoute(
                      builder: (_) => const SplashScreen());
                case '/login':
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
                case '/register':
                  return MaterialPageRoute(
                      builder: (_) => const RegisterScreen());
                case '/home':
                  return MaterialPageRoute(builder: (_) => const HomeScreen());
                default:
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
              }
            },
          );
        },
      ),
    );
  }
}
