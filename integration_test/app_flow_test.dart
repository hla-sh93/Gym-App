import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personal_gym_progress_notebook/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches to onboarding or shell', (tester) async {
    await tester.pumpWidget(GymNotebookApp());
    await tester.pumpAndSettle();

    expect(find.byType(GymNotebookApp), findsOneWidget);
  });
}
