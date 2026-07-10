/// An exception carrying a localization key instead of user-facing text,
/// so errors surface in the user's language.
class AppException implements Exception {
  const AppException(this.l10nKey);

  final String l10nKey;

  @override
  String toString() => l10nKey;
}
