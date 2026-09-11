import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peachtalk/main.dart';
import 'package:peachtalk/screens/character_select_screen.dart';

void main() {
  testWidgets(
    'Splash screen shows a progress bar, then navigates to character selection',
    (WidgetTester tester) async {
      await tester.pumpWidget(const PeachTalkApp());

      // The JSON asset config loads asynchronously; let that future resolve
      // without advancing far enough for the loading animation to finish.
      await tester.pump();
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(CharacterSelectScreen), findsNothing);

      // Advance past the loading duration: the splash screen hands off to
      // character selection.
      await tester.pumpAndSettle();

      expect(find.byType(CharacterSelectScreen), findsOneWidget);
    },
  );
}
