import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import 'app.dart';
import 'data/providers.dart';
import 'platform/device_time.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = openAppDatabase();
  final deviceId = await InstallInfo.deviceId(db);
  final tz = await deviceTimeZone();
  runApp(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      deviceIdProvider.overrideWithValue(deviceId),
      deviceTimeZoneProvider.overrideWithValue(tz),
    ],
    child: const RemindMeApp(),
  ));
}
