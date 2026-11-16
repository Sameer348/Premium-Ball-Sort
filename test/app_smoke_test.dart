import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/app.dart';
import 'package:sort_sphere/features/gameplay/game_screen.dart';
import 'package:sort_sphere/game/board/board_widget.dart';
import 'package:sort_sphere/services/app_services.dart';
import 'package:sort_sphere/services/storage/key_value_store.dart';

void main() {
  testWidgets('boots offline to home, opens level 1 and plays a move', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = await AppServices.create(store: MemoryStore());
    await tester.pumpWidget(SortSphereApp(services: services));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('CONTINUE'), findsOneWidget);

    // Dismiss the daily reward popup if it appeared.
    await tester.pump(const Duration(seconds: 1));
    if (find.text('CLAIM').evaluate().isNotEmpty) {
      await tester.tap(find.text('CLAIM'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('CLOSE'));
      await tester.pump(const Duration(milliseconds: 500));
    }

    await tester.tap(find.text('CONTINUE'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.byType(BoardWidget), findsOneWidget);

    // Level 1 = [[0,0,1,1],[1,1,0,0],[]]: move tube 1 → tube 3.
    final state = tester.state<State<GameScreen>>(find.byType(GameScreen));
    expect(state.mounted, isTrue);
    final board = tester.getRect(find.byType(BoardWidget));
    await tester.tapAt(Offset(board.left + board.width * 0.25, board.center.dy));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(Offset(board.left + board.width * 0.75, board.center.dy));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('1'), findsWidgets, reason: 'move counter advanced');
    expect(tester.takeException(), isNull);
  });
}
