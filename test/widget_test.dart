import 'package:flutter_test/flutter_test.dart';
import 'package:zip_puzzle/main.dart';

void main() {
  testWidgets('zip puzzle home loads after splash', (tester) async {
    await tester.pumpWidget(const ZipPuzzleApp());

    expect(find.text('Zip Puzzle'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    expect(find.text('Easy mode only accepts the original hidden route.'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
    expect(find.text('New Puzzle'), findsOneWidget);
  });
}
