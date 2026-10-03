import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_tarefas/main.dart';

void main() {
  testWidgets('Adiciona uma tarefa na lista', (WidgetTester tester) async {
    await tester.pumpWidget(const MeuMiniApp());

    await tester.enterText(find.byType(TextField), 'Estudar Flutter');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Estudar Flutter'), findsOneWidget);
    expect(find.text('Total: 3 | Concluídas: 0'), findsOneWidget);
  });
}
