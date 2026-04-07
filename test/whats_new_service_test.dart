import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymapp/services/whats_new_service.dart';

void main() {
  group('WhatsNewService', () {
    late WhatsNewService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = WhatsNewService();
    });

    test('does not show on first run and records current version', () async {
      final result = await service.getWhatsNewIfNeeded(
        installedVersion: '1.0.0+3',
        releaseNotes: 'Notes',
      );

      expect(result, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(WhatsNewService.lastSeenVersionKey), '1.0.0');
    });

    test('shows dialog payload when installed version is newer', () async {
      SharedPreferences.setMockInitialValues({
        WhatsNewService.lastSeenVersionKey: '1.0.0',
      });

      final result = await service.getWhatsNewIfNeeded(
        installedVersion: '1.1.0+5',
        releaseNotes: 'Added OTA improvements',
      );

      expect(result, isNotNull);
      expect(result!.version, '1.1.0');
      expect(result.releaseNotes, 'Added OTA improvements');
    });

    test('does not show when only build metadata changed', () async {
      SharedPreferences.setMockInitialValues({
        WhatsNewService.lastSeenVersionKey: '1.0.0+1',
      });

      final result = await service.getWhatsNewIfNeeded(
        installedVersion: '1.0.0+9',
        releaseNotes: 'Notes',
      );

      expect(result, isNull);
    });
  });
}
