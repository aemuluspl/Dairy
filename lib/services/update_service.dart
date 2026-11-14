import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_info.dart';

/// Информация о последнем релизе на GitHub.
class ReleaseInfo {
  const ReleaseInfo({
    required this.tag,
    required this.url,
  });

  final String tag;
  final String url;

  String get version => UpdateService.normalizeVersion(tag);
}

/// Проверка обновлений через GitHub Releases API.
class UpdateService {
  const UpdateService._();

  static Future<ReleaseInfo?> fetchLatest({http.Client? client}) async {
    final ownsClient = client == null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(
        Uri.parse(AppInfo.releasesApiUrl),
        headers: const <String, String>{
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'Hash/${AppInfo.version}',
        },
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      return parseRelease(response.body);
    } catch (_) {
      return null;
    } finally {
      if (ownsClient) httpClient.close();
    }
  }

  /// Разбирает ответ GitHub API. Вынесено отдельно для тестов.
  static ReleaseInfo? parseRelease(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final tag = decoded['tag_name']?.toString().trim();
      if (tag == null || tag.isEmpty) return null;
      final url = decoded['html_url']?.toString().trim();
      return ReleaseInfo(
        tag: tag,
        url: url == null || url.isEmpty ? AppInfo.releasesPageUrl : url,
      );
    } catch (_) {
      return null;
    }
  }

  /// `v1.1.1` → `1.1.1`.
  static String normalizeVersion(String value) =>
      value.trim().replaceFirst(RegExp('^[vV]'), '');

  /// Сравнивает версии по major.minor.patch. Предрелизные суффиксы
  /// отбрасываются: для школьного приложения достаточно числовой части.
  static bool isNewer(String candidate, String current) {
    final a = _parts(candidate);
    final b = _parts(current);
    final length = a.length > b.length ? a.length : b.length;
    for (var index = 0; index < length; index++) {
      final left = index < a.length ? a[index] : 0;
      final right = index < b.length ? b[index] : 0;
      if (left != right) return left > right;
    }
    return false;
  }

  static List<int> _parts(String value) {
    final normalized = normalizeVersion(value).split(RegExp(r'[-+]')).first;
    return normalized
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList(growable: false);
  }
}
