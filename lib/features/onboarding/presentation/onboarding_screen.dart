import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../app/localization/app_localizations.dart';
import '../../common/presentation/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _languageCode = 'en';
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations(Locale(_languageCode));
    return Directionality(
      textDirection:
          _languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  const SizedBox(height: 24),
                  Image.asset(
                    'assets/images/empty_notebook.png',
                    height: 180,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('appTitle'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 24),
                  NotebookCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          l10n.t('chooseLanguage'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: <ButtonSegment<String>>[
                            ButtonSegment<String>(
                              value: 'en',
                              label: Text(l10n.t('english')),
                            ),
                            ButtonSegment<String>(
                              value: 'ar',
                              label: Text(l10n.t('arabic')),
                            ),
                          ],
                          selected: <String>{_languageCode},
                          onSelectionChanged: (selection) {
                            setState(() => _languageCode = selection.single);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: l10n.t('displayNameOptional'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(l10n.t('continue')),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.t('privacyNote'),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await GymScope.of(context).completeOnboarding(
        languageCode: _languageCode,
        displayName: _nameController.text,
      );
    } catch (error) {
      if (mounted) {
        showAppError(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
