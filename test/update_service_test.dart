import 'package:flutter_test/flutter_test.dart';
import 'package:school_diary/core/app_info.dart';
import 'package:school_diary/services/update_service.dart';

void main() {
  test('parseRelease читает тег и ссылку', () {
    final release = UpdateService.parseRelease(
      '{"tag_name":"v1.2.0","html_url":"https://example.com/release"}',
    );

    expect(release, isNotNull);
    expect(release!.tag, 'v1.2.0');
    expect(release.version, '1.2.0');
    expect(release.url, 'https://example.com/release');
  });

  test('parseRelease без ссылки подставляет страницу релизов', () {
    final release = UpdateService.parseRelease('{"tag_name":"v1.2.0"}');

    expect(release, isNotNull);
    expect(release!.url, AppInfo.releasesPageUrl);
  });

  test('parseRelease не падает на мусоре', () {
    expect(UpdateService.parseRelease('не json'), isNull);
    expect(UpdateService.parseRelease('{"tag_name":""}'), isNull);
    expect(UpdateService.parseRelease('[]'), isNull);
  });

  test('isNewer сравнивает версии по числам', () {
    expect(UpdateService.isNewer('v1.1.1', '1.1.0'), isTrue);
    expect(UpdateService.isNewer('1.2', '1.1.9'), isTrue);
    expect(UpdateService.isNewer('1.1.0', '1.1.0'), isFalse);
    expect(UpdateService.isNewer('v1.1.0', '1.1.1'), isFalse);
    expect(UpdateService.isNewer('1.10.0', '1.9.9'), isTrue);
  });

  test('isNewer игнорирует предрелизный суффикс', () {
    expect(UpdateService.isNewer('1.1.1-beta.2', '1.1.0'), isTrue);
    expect(UpdateService.isNewer('1.1.1+6', '1.1.1'), isFalse);
  });

  test('normalizeVersion убирает префикс v', () {
    expect(UpdateService.normalizeVersion('v1.1.1'), '1.1.1');
    expect(UpdateService.normalizeVersion(' V2.0 '), '2.0');
  });
}
