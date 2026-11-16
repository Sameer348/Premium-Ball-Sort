import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/game_themes.dart';
import '../../core/utils/transitions.dart';
import '../../game/board/board_widget.dart';
import '../../models/app_settings.dart';
import '../../models/booster.dart';
import '../../models/game_mode.dart';
import '../../models/level_data.dart';
import '../../services/ads/ad_config.dart';
import '../../services/ads/admob_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/audio/audio_service.dart';
import '../../services/haptics/haptics_service.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/dialogs.dart';
import 'game_controller.dart';
import 'game_launcher.dart';
import 'level_complete_screen.dart';
import 'widgets/booster_bar.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/game_hud.dart';

/// The puzzle screen. Ads never appear here; interstitials only run after
/// the player leaves the result card.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.mode,
    this.endlessIndex = 0,
  });

  final LevelData level;
  final GameMode mode;
  final int endlessIndex;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameController _g;
  PlayStatus _handled = PlayStatus.playing;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _g = GameController(
      level: widget.level,
      mode: widget.mode,
      progress: context.read<ProgressController>(),
      analytics: context.read<AnalyticsService>(),
      endlessIndex: widget.endlessIndex,
    )..start();
    _g.addListener(_onStatus);
    if (widget.mode == GameMode.classic) {
      GameLauncher.prefetch(widget.level.number + 1);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _g.removeListener(_onStatus);
    _g.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_g.status == PlayStatus.playing && !_dialogOpen) _g.pause();
    } else if (state == AppLifecycleState.resumed &&
        _g.status == PlayStatus.paused &&
        !_dialogOpen) {
      _onPause(alreadyPaused: true);
    }
  }

  String get _title => switch (widget.mode) {
    GameMode.classic => 'LEVEL ${widget.level.number}',
    GameMode.daily => 'DAILY',
    GameMode.endless => 'ENDLESS ${widget.endlessIndex + 1}',
    GameMode.timeAttack => 'TIME ATTACK',
    GameMode.perfect => 'PERFECT SORT',
  };

  void _onStatus() {
    final s = _g.status;
    if (s == _handled) return;
    if (s == PlayStatus.solved && _g.result == null) return; // wait for landing
    _handled = s;
    switch (s) {
      case PlayStatus.solved:
        unawaited(_showResult());
      case PlayStatus.stuck:
        unawaited(_g.fx.settled().then((_) => _showStuck()));
      case PlayStatus.timeUp:
      case PlayStatus.outOfMoves:
        unawaited(_showFail(timeUp: s == PlayStatus.timeUp));
      case PlayStatus.playing:
      case PlayStatus.paused:
        break;
    }
  }

  Future<void> _showResult() async {
    final r = _g.result!;
    final progress = context.read<ProgressController>();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    context.read<AdMobService>().onLevelCompleted();
    final best = widget.mode == GameMode.classic
        ? progress.value.bestMoves[widget.level.number]
        : null;
    final action = await Navigator.of(context).push<ResultAction>(
      Transitions.overlay(
        LevelCompleteScreen(
          result: r,
          coins: _g.coinsEarned,
          mode: widget.mode,
          title: _title,
          best: best,
        ),
      ),
    );
    if (!mounted) return;
    final tutorial =
        widget.mode == GameMode.classic &&
        widget.level.number <= AdConfig.tutorialLevels;
    switch (action ?? ResultAction.home) {
      case ResultAction.replay:
        _handled = PlayStatus.playing;
        _g.restart();
      case ResultAction.next:
        await context.read<AdMobService>().maybeShowInterstitial(
          inTutorial: tutorial,
        );
        if (!mounted) return;
        await GameLauncher.play(
          context,
          mode: widget.mode,
          level: _nextLevel(),
          replace: true,
        );
      case ResultAction.home:
        await context.read<AdMobService>().maybeShowInterstitial(
          inTutorial: tutorial,
        );
        if (mounted) Navigator.of(context).pop();
    }
  }

  int? _nextLevel() => switch (widget.mode) {
    GameMode.classic => widget.level.number + 1,
    GameMode.endless => widget.endlessIndex + 1,
    _ => null,
  };

  Future<void> _showStuck() async {
    if (!mounted || _g.status != PlayStatus.stuck || _dialogOpen) return;
    _dialogOpen = true;
    final c = await showStuckDialog(context, canAddTube: _g.canAddTube);
    _dialogOpen = false;
    if (!mounted) return;
    _handled = PlayStatus.playing;
    _g.dismissStuck();
    switch (c) {
      case StuckChoice.undo:
        _onBooster(Booster.undo);
      case StuckChoice.hint:
        _onBooster(Booster.hint);
      case StuckChoice.addTube:
        _onBooster(Booster.extraTube);
      case StuckChoice.restart:
        _g.restart();
      case StuckChoice.keepLooking:
        break;
    }
  }

  Future<void> _showFail({required bool timeUp}) async {
    _dialogOpen = true;
    final c = await showFailDialog(
      context,
      timeUp: timeUp,
      canContinue: !_g.continued,
    );
    _dialogOpen = false;
    if (!mounted) return;
    _handled = PlayStatus.playing;
    switch (c) {
      case FailChoice.continueAd:
        _g.continueAfterReward();
      case FailChoice.retry:
        _g.restart();
      case FailChoice.home:
        Navigator.of(context).pop();
    }
  }

  Future<void> _onPause({bool alreadyPaused = false}) async {
    if (_dialogOpen) return;
    if (!alreadyPaused) _g.pause();
    _dialogOpen = true;
    final c = await showPauseDialog(context);
    _dialogOpen = false;
    if (!mounted) return;
    _g.resume();
    switch (c) {
      case PauseChoice.resume:
        break;
      case PauseChoice.restart:
        _handled = PlayStatus.playing;
        _g.restart();
      case PauseChoice.home:
        Navigator.of(context).pop();
    }
  }

  Future<void> _onBooster(Booster b) async {
    BoosterOutcome out = switch (b) {
      Booster.undo => _g.undo(),
      Booster.hint => await _g.hint(),
      Booster.extraTube => _g.addTube(),
      Booster.shuffle => await _g.shuffle(),
    };
    if (!mounted) return;
    if (out == BoosterOutcome.needsMore) {
      _dialogOpen = true;
      final got = await showGetBooster(context, b);
      _dialogOpen = false;
      if (!got || !mounted) return;
      out = switch (b) {
        Booster.undo => _g.undo(),
        Booster.hint => await _g.hint(),
        Booster.extraTube => _g.addTube(),
        Booster.shuffle => await _g.shuffle(),
      };
      if (!mounted) return;
    }
    if (out == BoosterOutcome.unavailable) {
      final msg = switch (b) {
        Booster.undo => 'Nothing to undo yet.',
        Booster.hint =>
          _g.status == PlayStatus.stuck
              ? 'This position can’t be solved — try Undo.'
              : 'No hint available right now.',
        Booster.extraTube => 'Tube limit reached for this level.',
        Booster.shuffle => 'Nothing left to shuffle.',
      };
      showToast(context, msg);
    } else if (out == BoosterOutcome.used && b != Booster.undo) {
      context.read<HapticsService>().move();
    }
  }

  void _restart() {
    _handled = PlayStatus.playing;
    context.read<AudioService>().play(Sfx.button);
    _g.restart();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>().value;
    final settings = context.watch<SettingsController>().value;
    final theme = GameThemeSpec.of(progress.theme);
    return ChangeNotifierProvider<GameController>.value(
      value: _g,
      child: PopScope(
        canPop: true,
        child: Scaffold(
          body: AnimatedBackground(
            theme: theme,
            orbs: false,
            reduceMotion: true,
            child: SafeArea(
              child: Column(
                children: [
                  GameHud(
                    title: _title,
                    onPause: _onPause,
                    onHome: () => Navigator.of(context).maybePop(),
                  ),
                  if (widget.mode == GameMode.classic &&
                      widget.level.number <= 2)
                    const _TutorialTip(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: BoardWidget(
                        controller: _g,
                        audio: context.read<AudioService>(),
                        haptics: context.read<HapticsService>(),
                        ballSkin: progress.ballSkin,
                        tubeSkin: progress.tubeSkin,
                        tubeTint: theme.tubeTint,
                        accent: theme.accent,
                        reduceMotion: settings.reduceMotion,
                        colorSymbols: settings.colorSymbols,
                        lowGraphics: settings.graphics == GraphicsQuality.low,
                      ),
                    ),
                  ),
                  BoosterBar(onBooster: _onBooster, onRestart: _restart),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialTip extends StatelessWidget {
  const _TutorialTip();

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameController>();
    final text = g.selected == null
        ? 'Tap a tube to pick up its top ball'
        : 'Now tap a matching tube or an empty one';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: SizedBox(
        // Tall enough for two lines, so narrow phones that wrap the tip
        // don't clip it, while keeping the layout from jumping.
        height: 56,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(text),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.cyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
