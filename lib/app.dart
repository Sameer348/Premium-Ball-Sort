import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_info.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/transitions.dart';
import 'features/home/home_screen.dart';
import 'services/ads/admob_service.dart';
import 'services/analytics/analytics_service.dart';
import 'services/app_services.dart';
import 'services/audio/audio_service.dart';
import 'services/haptics/haptics_service.dart';
import 'state/progress_controller.dart';
import 'state/settings_controller.dart';
import 'widgets/achievement_toast.dart';

class SortSphereApp extends StatefulWidget {
  const SortSphereApp({super.key, required this.services});
  final AppServices services;

  @override
  State<SortSphereApp> createState() => _SortSphereAppState();
}

class _SortSphereAppState extends State<SortSphereApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = widget.services.audio;
    if (state == AppLifecycleState.paused) audio.onBackground();
    if (state == AppLifecycleState.resumed) audio.onForeground();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    return MultiProvider(
      providers: [
        Provider<AudioService>.value(value: s.audio),
        Provider<HapticsService>.value(value: s.haptics),
        Provider<AnalyticsService>.value(value: s.analytics),
        ChangeNotifierProvider<ProgressController>.value(value: s.progress),
        ChangeNotifierProvider<SettingsController>.value(value: s.settings),
        ChangeNotifierProvider<AdMobService>.value(value: s.ads),
      ],
      child: Builder(builder: (context) {
        final reduce = context.select<SettingsController, bool>((c) => c.value.reduceMotion);
        Transitions.reduceMotion = reduce;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
          child: MaterialApp(
            title: AppInfo.name,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reduce || MediaQuery.of(context).disableAnimations,
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
              ),
              child: AchievementToastHost(child: child!),
            ),
            home: const HomeScreen(),
          ),
        );
      }),
    );
  }
}
