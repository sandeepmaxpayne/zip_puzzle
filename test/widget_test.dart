import 'package:flutter_test/flutter_test.dart';
import 'package:zip_puzzle/app.dart';

void main() {
  testWidgets('auth screen loads after splash when signed out', (tester) async {
    await tester.pumpWidget(const ZipPuzzleApp());

    expect(find.text('Zip Puzzle'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();

    expect(find.text('Choose how you want to play'), findsOneWidget);
    expect(find.text('Continue With Google'), findsOneWidget);
  });
}
