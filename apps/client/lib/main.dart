import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import 'app.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = openAppDatabase();
  final deviceId = await InstallInfo.deviceId(db);
  runApp(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      deviceIdProvider.overrideWithValue(deviceId),
    ],
    child: const RemindMeApp(),
  ));
}
