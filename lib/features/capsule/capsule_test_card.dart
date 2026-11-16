import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../settings/settings_common.dart';

/// Эксперимент «Капля»: кнопка запускает Android-сервис, который держит
/// постоянное уведомление с таймером и просит систему вывести его в
/// статус-бар как live update Android 16.
///
/// Ветка `feature/capsule-test`: в основной сборке карточки нет.
class CapsuleTestCard extends StatefulWidget {
  const CapsuleTestCard({super.key, required this.strings});

  final Strings strings;

  @override
  State<CapsuleTestCard> createState() => _CapsuleTestCardState();
}

class _CapsuleTestCardState extends State<CapsuleTestCard> {
  static const MethodChannel _channel = MethodChannel('hash/capsule_test');

  bool _busy = false;

  Future<void> _start() async {
    await _run(() => _channel.invokeMethod<String>('startCapsule'), onSuccess: (
      status,
    ) {
      return switch (status) {
        'promoted' => widget.strings.capsuleStartedPromoted,
        'permission' => widget.strings.capsulePermission,
        _ => widget.strings.capsuleStartedLegacy,
      };
    });
  }

  Future<void> _stop() async {
    await _run(() => _channel.invokeMethod<String>('stopCapsule'), onSuccess: (
      _,
    ) {
      return widget.strings.capsuleStopped;
    });
  }

  Future<void> _run(
    Future<String?> Function() action, {
    required String Function(String?) onSuccess,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    String message;
    try {
      final status = await action();
      message = onSuccess(status);
    } on MissingPluginException {
      message = widget.strings.capsuleUnavailable;
    } on PlatformException {
      message = widget.strings.capsuleUnavailable;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final strings = widget.strings;

    return SettingsCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.bubble_chart_rounded,
                size: 20,
                color: palette.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.capsuleTestButton,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.capsuleTestSubtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onAccent,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    strings.capsuleTestButton,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _busy ? null : _stop,
                style: TextButton.styleFrom(
                  foregroundColor: palette.textMuted,
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  strings.capsuleTestStop,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
