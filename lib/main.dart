import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/screenshot_mode.dart';
import 'repositories/progress_repository.dart';
import 'services/app_services.dart';
import 'services/storage/key_value_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  KeyValueStore? store;
  if (screenshotMode) {
    // Demo progress kept in memory only, so real saves are never touched.
    store = MemoryStore();
    await LocalProgressRepository(store).saveProgress(screenshotProgress(DateTime.now()));
  }

  final services = await AppServices.create(store: store);
  runApp(SortSphereApp(services: services));

  // Non-blocking: audio and ads initialise after the first frame so the
  // app opens instantly and works fully offline.
  final s = services.settings.value;
  unawaited(services.audio.init(music: s.music, sfx: s.sfx));
  if (!screenshotMode) unawaited(services.ads.init());
}
