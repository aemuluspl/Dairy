/// Единая точка с версией приложения и адресами релизов.
///
/// Версия дублирует `version` из `pubspec.yaml` для UI и проверки обновлений:
/// Flutter не отдаёт её во время выполнения без дополнительного плагина.
class AppInfo {
  const AppInfo._();

  static const String version = '1.1.1';
  static const String repoOwner = 'aemuluspl';
  static const String repoName = 'Dairy';

  static const String releasesApiUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String releasesPageUrl =
      'https://github.com/$repoOwner/$repoName/releases/latest';

  static String releasePageFor(String tag) =>
      'https://github.com/$repoOwner/$repoName/releases/tag/$tag';
}
