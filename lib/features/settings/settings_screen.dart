import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../core/utils/max_width_box.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/pill_nav_bar.dart';
import '../../widgets/top_bar.dart';
import '../logs/logs_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;

    return SafeArea(
      bottom: false,
      child: MaxWidthBox(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TopBar(title: strings.settingsTitle),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 2,
                    bottom: PillNavBar.contentInset,
                  ),
                  children: <Widget>[
                    _SectionLabel(strings.appearance),
                    const SizedBox(height: 8),
                    _Card(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              _ThemeOption(
                                mode: ThemeMode.light,
                                current: state.themeMode,
                                icon: Icons.light_mode_rounded,
                                label: strings.themeLight,
                                onSelect: state.setThemeMode,
                              ),
                              const SizedBox(width: 6),
                              _ThemeOption(
                                mode: ThemeMode.dark,
                                current: state.themeMode,
                                icon: Icons.dark_mode_rounded,
                                label: strings.themeDark,
                                onSelect: state.setThemeMode,
                              ),
                              const SizedBox(width: 6),
                              _ThemeOption(
                                mode: ThemeMode.system,
                                current: state.themeMode,
                                icon: Icons.brightness_auto_rounded,
                                label: strings.themeSystem,
                                onSelect: state.setThemeMode,
                              ),
                            ],
                          ),
                          Divider(height: 14, color: palette.border),
                          _SwitchRow(
                            icon: state.newIconLines
                                ? Icons.draw_rounded
                                : Icons.edit_rounded,
                            title: strings.newIconTitle,
                            subtitle: strings.newIconHint,
                            value: state.newIconLines,
                            onChanged: state.setNewIconLines,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.languageSection),
                    const SizedBox(height: 8),
                    _LanguageCard(state: state, strings: strings),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.scheduleSection),
                    const SizedBox(height: 8),
                    _Card(
                      padding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
                      child: Column(
                        children: <Widget>[
                          _SwitchRow(
                            icon: Icons.meeting_room_outlined,
                            title: strings.showRooms,
                            subtitle: strings.showRoomsHint,
                            value: state.showRooms,
                            onChanged: state.setShowRooms,
                          ),
                          Divider(height: 1, color: palette.border),
                          _SwitchRow(
                            icon: Icons.weekend_rounded,
                            title: strings.saturdayOffTitle,
                            subtitle: strings.saturdayOffHint,
                            value: state.saturdayOff,
                            onChanged: state.setSaturdayOff,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.aliasesSection),
                    const SizedBox(height: 8),
                    _AliasesCard(state: state, strings: strings),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.transferSection),
                    const SizedBox(height: 8),
                    _TransferCard(state: state, strings: strings),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.dataSection),
                    const SizedBox(height: 8),
                    _Card(
                      padding: const EdgeInsets.fromLTRB(14, 2, 10, 2),
                      child: Column(
                        children: <Widget>[
                          _BackupCard(state: state, strings: strings),
                          Divider(height: 1, color: palette.border),
                          _LogsCard(strings: strings),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      strings.footerTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AliasesCard extends StatelessWidget {
  const _AliasesCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  Future<void> _edit(BuildContext context, String subject) async {
    final controller = TextEditingController(
      text: state.resolver.aliasesFor(subject).join(', '),
    );
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.palette;
        return AlertDialog(
          backgroundColor: palette.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: Text(
            strings.aliasesEditTitle(subject),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.none,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: strings.aliasesField,
              labelStyle: TextStyle(
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
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                controller.text
                    .split(RegExp(r'[,;\n]'))
                    .map((alias) => alias.trim())
                    .where((alias) => alias.isNotEmpty)
                    .toList(growable: false),
              ),
              child: Text(strings.save),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result == null || !context.mounted) return;
    await state.setSubjectAliases(subject, result);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      strings.aliasesSaved(subject),
      icon: Icons.tag_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subjects = state.resolver.subjects;

    if (subjects.isEmpty) {
      return _Card(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Text(
          strings.aliasesEmpty,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: palette.textMuted,
          ),
        ),
      );
    }

    return _Card(
      padding: const EdgeInsets.fromLTRB(14, 2, 10, 2),
      child: Column(
        children: <Widget>[
          for (var index = 0; index < subjects.length; index++) ...<Widget>[
            if (index > 0) Divider(height: 1, color: palette.border),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _edit(context, subjects[index]),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            subjects[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.resolver.aliasesFor(subjects[index]).isEmpty
                                ? strings.noAliases
                                : state.resolver
                                    .aliasesFor(subjects[index])
                                    .join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: palette.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  Future<void> _copyJson(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: state.exportScheduleJson()));
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      strings.transferJsonCopied,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _copyText(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: state.exportScheduleText()));
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      strings.transferTextCopied,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _import(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _Card(
      padding: const EdgeInsets.fromLTRB(14, 2, 10, 2),
      child: Column(
        children: <Widget>[
          _ActionRow(
            icon: Icons.data_object_rounded,
            title: strings.transferJson,
            onTap: () => _copyJson(context),
          ),
          Divider(height: 1, color: palette.border),
          _ActionRow(
            icon: Icons.notes_rounded,
            title: strings.transferText,
            onTap: () => _copyText(context),
          ),
          Divider(height: 1, color: palette.border),
          _ActionRow(
            icon: Icons.download_rounded,
            title: strings.transferImport,
            onTap: () => _import(context),
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 19, color: palette.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: context.palette.textMuted,
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 19, color: palette.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: palette.onAccent,
            activeTrackColor: palette.accent,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.current,
    required this.icon,
    required this.label,
    required this.onSelect,
  });

  final ThemeMode mode;
  final ThemeMode current;
  final IconData icon;
  final String label;
  final Future<void> Function(ThemeMode mode) onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected = mode == current;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? palette.accent : palette.chip,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: selected ? palette.onAccent : palette.textSecondary,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? palette.onAccent : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _Card(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: <Widget>[
          for (final language in AppLanguage.values) ...<Widget>[
            if (language != AppLanguage.values.first) const SizedBox(width: 6),
            Expanded(
              child: _LanguageOption(
                language: language,
                current: state.language,
                title: language == AppLanguage.mixed
                    ? strings.languageMixed
                    : strings.languageEnglish,
                hint: language == AppLanguage.mixed
                    ? strings.languageMixedHint
                    : strings.languageEnglishHint,
                onSelect: state.setLanguage,
                palette: palette,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.current,
    required this.title,
    required this.hint,
    required this.onSelect,
    required this.palette,
  });

  final AppLanguage language;
  final AppLanguage current;
  final String title;
  final String hint;
  final Future<void> Function(AppLanguage language) onSelect;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final selected = language == current;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(language),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? palette.accent : palette.chip,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? palette.onAccent : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: selected ? palette.onAccent : palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  Future<void> _restore(BuildContext context) async {
    if (!state.hasBackup) return;

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
    final at = state.backupAt;
    final subtitle = at == null
        ? strings.backupNever
        : strings.backupUpdatedAt(
            formatDeadline(at, english: strings.isEnglish),
          );

    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.history_rounded,
            size: 19,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.backupTitle,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: state.hasBackup ? () => _restore(context) : null,
          child: Text(strings.restore),
        ),
      ],
    );
  }
}

class _LogsCard extends StatefulWidget {
  const _LogsCard({required this.strings});

  final Strings strings;

  @override
  State<_LogsCard> createState() => _LogsCardState();
}

class _LogsCardState extends State<_LogsCard> {
  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LogsScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _open,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 19,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.strings.logsTitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.strings.logsSubtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
