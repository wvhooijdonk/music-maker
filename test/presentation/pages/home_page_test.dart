import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/presentation/mijn_app.dart';
import 'package:mijn_app/presentation/pages/home_page.dart';

void main() {
  testWidgets('app starts on the home page with title and welcome text', (
    tester,
  ) async {
    await tester.pumpWidget(const MijnApp());

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text(MijnApp.title), findsOneWidget);
    expect(find.text(HomePage.welcomeText), findsOneWidget);
  });
}
