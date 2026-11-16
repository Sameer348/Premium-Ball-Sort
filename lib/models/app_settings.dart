enum GraphicsQuality { low, high }

class AppSettings {
  const AppSettings({
    this.music = true,
    this.sfx = true,
    this.haptics = true,
    this.notifications = false,
    this.reduceMotion = false,
    this.colorSymbols = false,
    this.graphics = GraphicsQuality.high,
  });

  final bool music;
  final bool sfx;
  final bool haptics;
  final bool notifications;
  final bool reduceMotion;

  /// Draw a shape glyph on each ball so color is not the only cue.
  final bool colorSymbols;
  final GraphicsQuality graphics;

  AppSettings copyWith({
    bool? music,
    bool? sfx,
    bool? haptics,
    bool? notifications,
    bool? reduceMotion,
    bool? colorSymbols,
    GraphicsQuality? graphics,
  }) =>
      AppSettings(
        music: music ?? this.music,
        sfx: sfx ?? this.sfx,
        haptics: haptics ?? this.haptics,
        notifications: notifications ?? this.notifications,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        colorSymbols: colorSymbols ?? this.colorSymbols,
        graphics: graphics ?? this.graphics,
      );

  Map<String, Object?> toJson() => {
        'music': music,
        'sfx': sfx,
        'haptics': haptics,
        'notifications': notifications,
        'reduceMotion': reduceMotion,
        'colorSymbols': colorSymbols,
        'graphics': graphics.name,
      };

  factory AppSettings.fromJson(Map<String, Object?> j) => AppSettings(
        music: j['music'] as bool? ?? true,
        sfx: j['sfx'] as bool? ?? true,
        haptics: j['haptics'] as bool? ?? true,
        notifications: j['notifications'] as bool? ?? false,
        reduceMotion: j['reduceMotion'] as bool? ?? false,
        colorSymbols: j['colorSymbols'] as bool? ?? false,
        graphics: GraphicsQuality.values.firstWhere(
          (g) => g.name == j['graphics'],
          orElse: () => GraphicsQuality.high,
        ),
      );
}
