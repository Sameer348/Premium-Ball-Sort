/// Play modes. Classic is the relaxed default: no timer, no move limit.
enum GameMode {
  classic('Classic', 'Relaxed sorting. No timer, no pressure.'),
  daily('Daily Challenge', 'One fresh puzzle every day.'),
  endless('Endless', 'Infinite generated puzzles that slowly ramp up.'),
  timeAttack('Time Attack', 'Beat the clock for a time bonus.'),
  perfect('Perfect Sort', 'Finish within the move target for big rewards.');

  const GameMode(this.label, this.description);
  final String label;
  final String description;

  bool get hasTimer => this == GameMode.timeAttack;
  bool get hasMoveLimit => this == GameMode.perfect;
}
