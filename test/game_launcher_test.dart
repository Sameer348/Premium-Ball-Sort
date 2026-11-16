import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/features/gameplay/game_launcher.dart';
import 'package:sort_sphere/models/game_mode.dart';

void main() {
  // Regression: Daily / Endless / Time Attack / Perfect used to hang on the
  // spinner because their Isolate.run closures captured unsendable state.
  for (final mode in GameMode.values) {
    test('${mode.name} generates a level off the UI thread', () async {
      final level = await GameLauncher.levelFor(
        mode,
        campaign: 60,
        endlessIndex: 23,
        dateKey: 20261116,
        seed: 12345,
      ).timeout(const Duration(seconds: 30));
      expect(level.tubes, isNotEmpty);
    });
  }
}
