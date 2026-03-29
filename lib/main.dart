import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/workout_plan_provider.dart';
import 'providers/workout_session_provider.dart';
import 'providers/progression_provider.dart';
import 'providers/settings_provider.dart';
import 'services/hive_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await HiveService.init();
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  late WorkoutPlanProvider _workoutPlanProvider;
  late WorkoutSessionProvider _workoutSessionProvider;
  late ProgressionProvider _progressionProvider;
  late SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _workoutPlanProvider = WorkoutPlanProvider();
    _workoutSessionProvider = WorkoutSessionProvider();
    _progressionProvider = ProgressionProvider();
    _settingsProvider = SettingsProvider();

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.indigo,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Gym Tracker',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
              ],
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
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsProvider>();
          final seedColor = settings.getAccentSeed();
          final themeMode = settings.themeMode;

          return MaterialApp(
            title: 'Gym Tracker',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
