import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../database/app_database.dart';
import '../data/gym_repository.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/shell/presentation/shell_screen.dart';
import 'app_scope.dart';
import 'gym_app_controller.dart';
import 'localization/app_localizations.dart';
import 'theme.dart';

class GymNotebookApp extends StatefulWidget {
  GymNotebookApp({super.key, GymAppController? controller})
      : controller = controller ?? _ControllerFactory.createDefaultController();

  final GymAppController controller;

  @override
  State<GymNotebookApp> createState() => _GymNotebookAppState();
}

class _GymNotebookAppState extends State<GymNotebookApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return GymScope(
      controller: widget.controller,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gym Notebook',
            theme: buildAppTheme(),
            locale: controller.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: context.l10n.textDirection,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: _HomeGate(controller: controller),
          );
        },
      ),
    );
  }
}

class _HomeGate extends StatelessWidget {
  const _HomeGate({required this.controller});

  final GymAppController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!(controller.settings?.isReady ?? false)) {
      return const OnboardingScreen();
    }
    return const ShellScreen();
  }
}

class _ControllerFactory {
  const _ControllerFactory._();

  static GymAppController createDefaultController() {
    return GymAppController(GymRepository(AppDatabase()));
  }
}
