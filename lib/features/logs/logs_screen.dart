import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/diagnostics/app_log.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/max_width_box.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/top_bar.dart';

/// Журнал действий и ошибок: что происходило в приложении и что упало.
class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  Future<void> _copy(BuildContext context) async {
    final strings = context.read<AppState>().strings;
    await Clipboard.setData(ClipboardData(text: AppLog.instance.dump()));
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      strings.logsCopied,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _clear(BuildContext context) async {
    final strings = context.read<AppState>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.clearLogQuestion),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AppLog.instance.clear();
    AppLog.instance.info('Журнал очищен вручную');
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      strings.logsCleared,
      icon: Icons.delete_sweep_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final strings = context.read<AppState>().strings;
    final entries = AppLog.instance.entries.reversed.toList(growable: false);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: MaxWidthBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TopBar(
                  title: strings.logsTitle,
                  leading: RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: strings.back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      RoundIconButton(
                        icon: Icons.copy_rounded,
                        tooltip: strings.copyLog,
                        onTap: () => _copy(context),
                      ),
                      const SizedBox(width: 8),
                      RoundIconButton(
                        icon: Icons.delete_sweep_rounded,
                        tooltip: strings.clearLog,
                        onTap: () => _clear(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.logsSubtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: entries.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: strings.logsEmpty,
                          message: strings.logsSubtitle,
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final isError = entry.contains('ERROR');
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: palette.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isError
                                      ? palette.danger.withValues(alpha: 0.4)
                                      : palette.border,
                                ),
                              ),
                              child: SelectableText(
                                entry,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  height: 1.45,
                                  color: isError
                                      ? palette.danger
                                      : palette.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
