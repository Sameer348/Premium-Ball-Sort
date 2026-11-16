enum Booster {
  hint('Hint', 'Shows the best next move'),
  undo('Undo', 'Takes back your last move'),
  extraTube('Extra Tube', 'Adds an empty tube'),
  shuffle('Shuffle', 'Re-mixes unsorted balls (always solvable)');

  const Booster(this.label, this.description);
  final String label;
  final String description;
}
