import 'package:flutter_test/flutter_test.dart';
import 'package:zip_puzzle/main.dart';

void main() {
  testWidgets('zip puzzle home loads after splash', (tester) async {
    await tester.pumpWidget(const ZipPuzzleApp());

    expect(find.text('Zip Puzzle'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    expect(find.text('Blank cells are free. Only the shown numbers must be hit at the right step.'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
    expect(find.text('New Puzzle'), findsOneWidget);
  });
}
