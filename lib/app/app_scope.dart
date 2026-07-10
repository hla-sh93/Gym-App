import 'package:flutter/widgets.dart';

import 'gym_app_controller.dart';

class GymScope extends InheritedNotifier<GymAppController> {
  const GymScope({
    required GymAppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static GymAppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GymScope>();
    assert(scope != null, 'GymScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
