import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:remember/main.dart';

void main() {
  testWidgets('Remind button needs a message', (WidgetTester tester) async {
    await tester.pumpWidget(const RememberApp());

    FilledButton button() =>
        tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Take medicine');
    await tester.pump();

    expect(button().onPressed, isNotNull);
  });
}
