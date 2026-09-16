import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finny/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows onboarding brand', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinnyApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Финни'), findsWidgets);
    expect(find.text('Питомец Финни'), findsOneWidget);
    expect(find.text('Дальше'), findsOneWidget);

    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();
    expect(find.text('Создать питомца'), findsOneWidget);
  });
}
