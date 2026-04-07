import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';

class UpdateInfo {
  final String latestVersion;
  final String apkUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  static const Duration _requestTimeout = Duration(seconds: 5);

  Future<UpdateInfo?> fetchLatestReleaseInfo() async {
    try {
      final response = await http
          .get(AppConfig.uriForPath('/version'))
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersionRaw = body['version'];
      final apkUrlRaw = body['apk_url'];
      final releaseNotesRaw = body['release_notes'];

      if (latestVersionRaw is! String ||
          apkUrlRaw is! String ||
          releaseNotesRaw is! String) {
        return null;
      }

      final latestVersion = _parseSemver(latestVersionRaw);
      if (latestVersion == null) {
        return null;
      }

      return UpdateInfo(
        latestVersion: _toVersionString(latestVersion),
        apkUrl: apkUrlRaw,
        releaseNotes: releaseNotesRaw,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = _parseSemver(packageInfo.version);
      if (installedVersion == null) {
        return null;
      }

      final latestRelease = await fetchLatestReleaseInfo();
      if (latestRelease == null) {
        return null;
      }

      final latestVersion = _parseSemver(latestRelease.latestVersion);
      if (latestVersion != null &&
          _isGreaterVersion(latestVersion, installedVersion)) {
        return latestRelease;
      }

      return null;
    } catch (_) {
      return null;
    }
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
