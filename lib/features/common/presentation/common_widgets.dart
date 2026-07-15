import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme.dart';
import '../../../core/errors/app_exception.dart';
import '../../workout/domain/models.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.child,
    this.actions,
    this.bottom,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
        actions: actions,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              child: child,
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              // heightFactor 1.0 shrink-wraps the bar to its child; without
              // it Align expands and floating SnackBars assert off-screen.
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: bottom,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Gradient hero card used for the most important element on a page
/// (today's workout, the active session header).
class HeroCard extends StatelessWidget {
  const HeroCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

/// Circular icon badge with a soft tinted background.
class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    this.color = AppColors.primary,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

class NotebookCard extends StatelessWidget {
  const NotebookCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) {
      return card;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: card,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Icons.note_alt_outlined,
    this.action,
    this.illustration = false,
    super.key,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  /// When true, shows the bundled notebook illustration instead of an icon.
  final bool illustration;

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (illustration)
            Image.asset(
              'assets/images/empty_notebook.png',
              height: 150,
              errorBuilder: (_, __, ___) =>
                  IconBadge(icon: icon, size: 56),
            )
          else
            IconBadge(icon: icon, size: 56),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          if (action != null) ...<Widget>[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class InlineStat extends StatelessWidget {
  const InlineStat({
    required this.label,
    required this.value,
    this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color ?? AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

void showAppError(BuildContext context, Object error) {
  final String message;
  if (error is AppException) {
    message = context.l10n.t(error.l10nKey);
  } else if (error is StateError || error is ArgumentError) {
    message = error.toString().replaceFirst(
          RegExp(r'^(Bad state|Invalid argument(?:\(s\))?)\:?\s*'),
          '',
        );
  } else {
    message = context.l10n.t('unknownError');
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Localized label of the user's chosen weight unit ('kg' or 'lb').
String weightUnitLabel(BuildContext context) {
  final unit = GymScope.of(context).weightUnit;
  return context.l10n.t(unit == 'lb' ? 'lb' : 'kg');
}

String formatWeight(num value) {
  final asDouble = value.toDouble();
  if (asDouble == asDouble.roundToDouble()) {
    return asDouble.toInt().toString();
  }
  // Show one decimal when exact (42.5), two when needed (42.25).
  final oneDecimal = (asDouble * 10).roundToDouble() / 10;
  if (oneDecimal == asDouble) {
    return asDouble.toStringAsFixed(1);
  }
  return asDouble.toStringAsFixed(2);
}

String formatSetLine(
  BuildContext context,
  WorkoutSetLog set,
  ExerciseType type, {
  bool isBest = false,
}) {
  final star = isBest ? ' ★' : '';
  if (type == ExerciseType.weighted) {
    final weight = set.weight == null ? '-' : formatWeight(set.weight!);
    final reps = set.reps?.toString() ?? '-';
    return '${context.l10n.t('set')} ${set.setNumber} · $weight${weightUnitLabel(context)} x $reps$star';
  }
  final reps = set.reps?.toString() ?? '-';
  return '${context.l10n.t('set')} ${set.setNumber} · $reps ${context.l10n.t('reps')}$star';
}
