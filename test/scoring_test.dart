import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/game/engine/scoring.dart';

void main() {
  test('stars: 3 at/under par, 2 within 35%, else 1', () {
    expect(Scoring.stars(moves: 20, par: 20), 3);
    expect(Scoring.stars(moves: 15, par: 20), 3);
    expect(Scoring.stars(moves: 27, par: 20), 2);
    expect(Scoring.stars(moves: 28, par: 20), 1);
    expect(Scoring.stars(moves: 200, par: 20), 1, reason: 'finishing always earns a star');
  });

  test('score rewards efficiency and clean play', () {
    final clean = Scoring.score(moves: 20, par: 20, colors: 5, usedUndo: false, usedHint: false);
    final assisted = Scoring.score(moves: 20, par: 20, colors: 5, usedUndo: true, usedHint: true);
    final slow = Scoring.score(moves: 40, par: 20, colors: 5, usedUndo: false, usedHint: false);
    expect(clean, greaterThan(assisted));
    expect(clean, greaterThan(slow));
    expect(slow, greaterThan(0));
  });

  test('coins: replays pay half, multiplier applies', () {
    expect(Scoring.coins(stars: 3, firstClear: true), 25);
    expect(Scoring.coins(stars: 3, firstClear: false), 13);
    expect(Scoring.coins(stars: 1, firstClear: true, multiplier: 2), 30);
  });

  test('evaluate marks perfect runs', () {
    final r = Scoring.evaluate(moves: 18, par: 18, colors: 4, seconds: 40, usedUndo: false, usedHint: false, firstClear: true);
    expect(r.perfect, isTrue);
    expect(r.stars, 3);
  });
}
