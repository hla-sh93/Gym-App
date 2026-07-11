import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/theme.dart';
import '../../common/presentation/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _initialized = false;
  bool _savingName = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _nameController.text = GymScope.of(context).settings?.displayName ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = GymScope.of(context);
    final languageCode = controller.settings?.languageCode ?? 'en';
    return AppPage(
      title: context.l10n.t('settings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NotebookCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.t('language'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'en',
                      label: Text(context.l10n.t('english')),
                    ),
                    ButtonSegment<String>(
                      value: 'ar',
                      label: Text(context.l10n.t('arabic')),
                    ),
                  ],
                  selected: <String>{languageCode},
                  onSelectionChanged: (selection) {
                    controller.changeLanguage(selection.single);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NotebookCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.t('weightUnit'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'kg',
                      label: Text(context.l10n.t('kg')),
                    ),
                    ButtonSegment<String>(
                      value: 'lb',
                      label: Text(context.l10n.t('lb')),
                    ),
                  ],
                  selected: <String>{controller.weightUnit},
                  onSelectionChanged: (selection) {
                    controller.changeWeightUnit(selection.single);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NotebookCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.t('displayName'),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _savingName ? null : _saveName,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(context.l10n.t('save')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NotebookCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.lock_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.t('privacyNote'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveName() async {
    setState(() => _savingName = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final savedLabel = context.l10n.t('saved');
      await GymScope.of(context).updateDisplayName(_nameController.text);
      messenger.showSnackBar(SnackBar(content: Text(savedLabel)));
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _savingName = false);
      }
    }
  }
}
