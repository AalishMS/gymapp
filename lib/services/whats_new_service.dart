import 'package:shared_preferences/shared_preferences.dart';

class WhatsNewInfo {
  final String version;
  final String releaseNotes;

  const WhatsNewInfo({
    required this.version,
    required this.releaseNotes,
  });
}

class WhatsNewService {
  static const String lastSeenVersionKey = 'last_seen_whats_new_version';
  static const String _fallbackReleaseNotes =
      'This update includes performance and stability improvements.';

  Future<WhatsNewInfo?> getWhatsNewIfNeeded({
    required String installedVersion,
    String? releaseNotes,
  }) async {
    try {
      final installed = _parseSemver(installedVersion);
      if (installed == null) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSeenRaw = prefs.getString(lastSeenVersionKey);

      if (lastSeenRaw == null) {
        await prefs.setString(lastSeenVersionKey, _toVersionString(installed));
        return null;
      }

      final lastSeen = _parseSemver(lastSeenRaw);
      if (lastSeen == null) {
        await prefs.setString(lastSeenVersionKey, _toVersionString(installed));
        return null;
      }

      if (_isGreaterVersion(installed, lastSeen)) {
        return WhatsNewInfo(
          version: _toVersionString(installed),
          releaseNotes: releaseNotes?.trim().isNotEmpty == true
              ? releaseNotes!.trim()
              : _fallbackReleaseNotes,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> markVersionAsSeen(String installedVersion) async {
    final parsed = _parseSemver(installedVersion);
    if (parsed == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSeenVersionKey, _toVersionString(parsed));
  }

  List<int>? _parseSemver(String version) {
    final noBuildMetadata = version.split('+').first;
    final parts = noBuildMetadata.split('.');
    if (parts.length < 3) {
      return null;
    }

    final major = int.tryParse(parts[0]);
    final minor = int.tryParse(parts[1]);
    final patch = int.tryParse(parts[2]);
    if (major == null || minor == null || patch == null) {
      return null;
    }

    return [major, minor, patch];
  }

  bool _isGreaterVersion(List<int> candidate, List<int> current) {
    for (var i = 0; i < 3; i++) {
      if (candidate[i] > current[i]) {
        return true;
      }
      if (candidate[i] < current[i]) {
        return false;
      }
    }
    return false;
  }

  String _toVersionString(List<int> version) {
    return '${version[0]}.${version[1]}.${version[2]}';
  }
}
