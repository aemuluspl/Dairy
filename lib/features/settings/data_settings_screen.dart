import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import '../logs/logs_screen.dart';
import 'settings_common.dart';

class DataSettingsScreen extends StatelessWidget {
  const DataSettingsScreen({super.key});

  Future<void> _copyJson(BuildContext context, AppState state) async {
    await Clipboard.setData(
      ClipboardData(text: state.exportScheduleJson()),
    );
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      state.strings.transferJsonCopied,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _copyText(BuildContext context, AppState state) async {
    await Clipboard.setData(
      ClipboardData(text: state.exportScheduleText()),
    );
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      state.strings.transferTextCopied,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _import(BuildContext context, AppState state) async {
    final strings = state.strings;
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => _ImportDialog(strings: strings),
    );
    if (raw == null || !context.mounted) return;
    if (raw.trim().isEmpty) {
      showAppSnackBar(
        context,
        strings.transferEmpty,
        icon: Icons.error_outline_rounded,
        isError: true,
      );
      return;
    }

    final count = await state.importSchedule(raw);
    if (!context.mounted) return;
    if (count < 0) {
      showAppSnackBar(
        context,
        strings.transferImportFailed,
        icon: Icons.error_outline_rounded,
        isError: true,
      );
      return;
    }
    showAppSnackBar(
      context,
      strings.transferImported(count),
      icon: Icons.download_done_rounded,
    );
  }

  Future<void> _restore(BuildContext context, AppState state) async {
    if (!state.hasBackup) return;
    final strings = state.strings;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.restoreTitle),
        content: Text(strings.restoreMessage(state.backupCount)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.restore),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final restored = await state.restoreBackup();
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      strings.restoredBackupSnack(restored),
      icon: Icons.restore_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;
    final backupAt = state.backupAt;
    final backupSubtitle = backupAt == null
        ? strings.backupNever
        : strings.backupUpdatedAt(
            formatDeadline(backupAt, english: strings.isEnglish),
          );

    return SettingsSubScaffold(
      title: strings.settingsData,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2, bottom: 24),
        children: <Widget>[
          SettingsSectionLabel(strings.transferSection),
          const SizedBox(height: 8),
          SettingsCard(
            padding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
            child: Column(
              children: <Widget>[
                SettingsActionRow(
                  icon: Icons.data_object_rounded,
                  title: strings.transferJson,
                  subtitle: strings.transferJsonHint,
                  onTap: () => _copyJson(context, state),
                ),
                Divider(height: 1, color: palette.border),
                SettingsActionRow(
                  icon: Icons.notes_rounded,
                  title: strings.transferText,
                  subtitle: strings.transferTextHint,
                  onTap: () => _copyText(context, state),
                ),
                Divider(height: 1, color: palette.border),
                SettingsActionRow(
                  icon: Icons.download_rounded,
                  title: strings.transferImport,
                  subtitle: strings.transferImportHintShort,
                  onTap: () => _import(context, state),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SettingsSectionLabel(strings.dataSection),
          const SizedBox(height: 8),
          SettingsCard(
            padding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
            child: Column(
              children: <Widget>[
                SettingsActionRow(
                  icon: Icons.history_rounded,
                  title: strings.backupTitle,
                  subtitle: backupSubtitle,
                  trailing: TextButton(
                    onPressed:
                        state.hasBackup ? () => _restore(context, state) : null,
                    child: Text(strings.restore),
                  ),
                  onTap: () => _restore(context, state),
                ),
                Divider(height: 1, color: palette.border),
                SettingsActionRow(
                  icon: Icons.receipt_long_rounded,
                  title: strings.logsTitle,
                  subtitle: strings.logsSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LogsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.strings});

  final Strings strings;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null) return;
    setState(() => _controller.text = text);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AlertDialog(
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: Text(
        widget.strings.transferImportTitle,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          minLines: 6,
          maxLines: 10,
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.strings.transferImportHint,
            hintStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
            filled: true,
            fillColor: palette.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.accent),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _paste,
          child: Text(widget.strings.transferPaste),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.strings.transferImport),
        ),
      ],
    );
  }
}
