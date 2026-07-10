import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_gym_progress_notebook/app/localization/app_localizations.dart';

void main() {
  testWidgets('Arabic localization reports RTL direction', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            final direction = AppLocalizations.of(context).textDirection;
            return Text(direction == TextDirection.rtl ? 'rtl' : 'ltr');
          },
        ),
      ),
    );

    expect(find.text('rtl'), findsOneWidget);
  });
}
