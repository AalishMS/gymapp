import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../repositories/workout_plan_repository.dart';
import '../repositories/workout_session_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(AuthService().warmupApi());
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // Prime the cache by loading data from API
      try {
        final planRepo = WorkoutPlanRepository();
        final sessionRepo = WorkoutSessionRepository();

        await planRepo.getPlans();
        await sessionRepo.getSessionsAsync();
      } catch (e) {
        // Ignore errors during cache priming, proceed to home anyway
      }

      // Check if we're still logged in after cache priming
      final stillLoggedIn = await authService.isLoggedIn();

      if (!mounted) return;

      if (stillLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
