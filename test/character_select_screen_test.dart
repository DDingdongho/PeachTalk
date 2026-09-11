import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peachtalk/screens/character_select_screen.dart';

void main() {
  testWidgets('Character select screen lists all characters with a chat button each', (
    WidgetTester tester,
  ) async {
    // Use a tall viewport so all three cards build without needing to scroll.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: CharacterSelectScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('니아'), findsOneWidget);
    expect(find.text('아야'), findsOneWidget);
    expect(find.text('코미'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '대화하기'), findsNWidgets(3));
  });
}
