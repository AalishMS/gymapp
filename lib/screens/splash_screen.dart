import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/workout_plan_provider.dart';
import '../providers/workout_session_provider.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../services/whats_new_service.dart';
import '../theme/app_theme.dart';

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
    var nextRoute = '/login';

    if (!mounted) return;

    if (isLoggedIn) {
      final planProvider = context.read<WorkoutPlanProvider>();
      final sessionProvider = context.read<WorkoutSessionProvider>();

      planProvider.loadPlans();
      sessionProvider.loadSessions();

      // Check if we're still logged in after cache priming
      final stillLoggedIn = await authService.isLoggedIn();

      if (!mounted) return;

      if (stillLoggedIn) {
        nextRoute = '/home';
      } else {
        nextRoute = '/login';
      }
    }

    final updateAvailable = await _checkForUpdates();
    if (!updateAvailable) {
      await _checkAndShowWhatsNew();
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, nextRoute);
  }

  Future<bool> _checkForUpdates() async {
    try {
      final updateInfo = await UpdateService().checkForUpdate();
      if (!mounted || updateInfo == null) return false;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final accent = accentColor(dialogContext);

          return AlertDialog(
            backgroundColor: backgroundColor(dialogContext),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: accent),
            ),
            title: Text(
              '> UPDATE AVAILABLE v${updateInfo.latestVersion}',
              style: GoogleFonts.jetBrainsMono(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Text(
              _formatReleaseNotes(updateInfo.releaseNotes),
              style: GoogleFonts.jetBrainsMono(
                color: textPrimaryColor(dialogContext),
                fontSize: 14,
              ),
            ),
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimaryColor(dialogContext),
                  side: BorderSide(color: borderColor(dialogContext)),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'SKIP',
                  style: GoogleFonts.jetBrainsMono(),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () async {
                  final uri = Uri.tryParse(updateInfo.apkUrl);
                  if (uri != null) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'UPDATE NOW',
                  style: GoogleFonts.jetBrainsMono(),
                ),
              ),
            ],
          );
        },
      );
      return true;
    } catch (_) {
      // Fail silently to avoid blocking auth flow.
      return false;
    }
  }

  Future<void> _checkAndShowWhatsNew() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final releaseInfo = await UpdateService().fetchLatestReleaseInfo();
      final whatsNewInfo = await WhatsNewService().getWhatsNewIfNeeded(
        installedVersion: packageInfo.version,
        releaseNotes: releaseInfo?.releaseNotes,
      );

      if (!mounted || whatsNewInfo == null) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          final accent = accentColor(dialogContext);

          return AlertDialog(
            backgroundColor: backgroundColor(dialogContext),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: accent),
            ),
            title: Text(
              '> WHAT\'S NEW v${whatsNewInfo.version}',
              style: GoogleFonts.jetBrainsMono(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Text(
              _formatReleaseNotes(whatsNewInfo.releaseNotes),
              style: GoogleFonts.jetBrainsMono(
                color: textPrimaryColor(dialogContext),
                fontSize: 14,
              ),
            ),
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'CONTINUE',
                  style: GoogleFonts.jetBrainsMono(),
                ),
              ),
            ],
          );
        },
      );

      await WhatsNewService().markVersionAsSeen(packageInfo.version);
    } catch (_) {
      // Fail silently to avoid blocking auth flow.
    }
  }

  String _formatReleaseNotes(String releaseNotes) {
    final lines = releaseNotes
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return releaseNotes;
    }

    final allBulleted =
        lines.every((line) => line.startsWith('-') || line.startsWith('•'));

    if (allBulleted || lines.length == 1) {
      return lines.join('\n');
    }

    return lines.map((line) => '• $line').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentColor(context);

    return Scaffold(
      backgroundColor: backgroundColor(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '> OPENGYM',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
