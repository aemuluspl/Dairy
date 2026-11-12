import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/diagnostics/app_log.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../core/utils/max_width_box.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/soft_chip.dart';
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
                  padding: const EdgeInsets.only(top: 2, bottom: 20),
                  children: <Widget>[
                    _SectionLabel(strings.appearance),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
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
                    ),
                    const SizedBox(height: 8),
                    _NewIconCard(state: state, strings: strings),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.languageSection),
                    const SizedBox(height: 8),
                    _LanguageCard(state: state, strings: strings),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.scheduleSection),
                    const SizedBox(height: 8),
                    _RoomsCard(state: state, strings: strings),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.localDb),
                    const SizedBox(height: 8),
                    _StatsCard(state: state, strings: strings),
                    const SizedBox(height: 8),
                    _BackupCard(state: state, strings: strings),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.transfer),
                    const SizedBox(height: 8),
                    _ExportCard(state: state, strings: strings),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.diagnostics),
                    const SizedBox(height: 8),
                    _LogsCard(strings: strings),
                    const SizedBox(height: 18),
                    _SectionLabel(strings.unifiedDb),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            strings.modulesTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: <Widget>[
                              SoftChip(
                                label: strings.moduleHomework,
                                icon: Icons.checklist_rounded,
                                accent: true,
                              ),
                              SoftChip(
                                label: strings.moduleNotes,
                                icon: Icons.sticky_note_2_rounded,
                              ),
                              SoftChip(
                                label: strings.moduleContacts,
                                icon: Icons.contacts_rounded,
                              ),
                              SoftChip(
                                label: strings.moduleMore,
                                icon: Icons.add_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: strings.exportFormat,
                            value: 'school-diary.unified-db',
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(label: strings.schemaVersion, value: '1'),
                          const SizedBox(height: 6),
                          _InfoRow(
                            label: strings.storage,
                            value: 'Hive (offline)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      strings.footerTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.footerSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
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

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final totalLessons = state.schedule.values.fold<int>(
      0,
      (sum, lessons) => sum + lessons.length,
    );

    final stats = <({String value, String label})>[
      (
        value: '${state.tasks.length}',
        label: strings.tasksWord(state.tasks.length),
      ),
      (value: '${state.activeCount}', label: strings.inProgress),
      (value: '${state.completedCount}', label: strings.completed),
      (
        value: '${state.subjectCount}',
        label: strings.subjectsWord(state.subjectCount),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final stat in stats)
                    SizedBox(
                      width: tileWidth,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                        decoration: BoxDecoration(
                          color: palette.chip,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              stat.value,
                              style: TextStyle(
                                fontSize: 24,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stat.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: strings.lessonsInSchedule,
            value: strings.lessonsCount(totalLessons),
          ),
        ],
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
        : strings.backupSummary(
            state.backupCount,
            formatDeadline(at, english: strings.isEnglish),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
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
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.data_object_rounded,
                  size: 21,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.exportTitle,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.exportSubtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showExportSheet(context),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(strings.showJson),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportSheet(BuildContext context) async {
    final json = state.exportJson();
    final palette = context.palette;
    final strings = state.strings;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final height = MediaQuery.of(sheetContext).size.height;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              height: height * 0.82,
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  strings.exportSheetTitle,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.exportSheetSubtitle(
                                    state.tasks.length,
                                    state.subjectCount,
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SoftChip(
                            label: strings.copy,
                            icon: Icons.copy_rounded,
                            accent: true,
                            onTap: () async {
                              await Clipboard.setData(
                                ClipboardData(text: json),
                              );
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              if (!context.mounted) return;
                              showAppSnackBar(
                                context,
                                strings.copied,
                                icon: Icons.copy_rounded,
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          RoundIconButton(
                            icon: Icons.close_rounded,
                            tooltip: strings.close,
                            onTap: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.background,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: palette.border),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: SelectableText(
                              json,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                height: 1.5,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.exportHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.palette.border),
      ),
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
  });

  final AppLanguage language;
  final AppLanguage current;
  final String title;
  final String hint;
  final Future<void> Function(AppLanguage language) onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
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

class _NewIconCard extends StatelessWidget {
  const _NewIconCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
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
              state.newIconLines ? Icons.draw_rounded : Icons.edit_rounded,
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
                  strings.newIconTitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.newIconHint,
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
            value: state.newIconLines,
            onChanged: state.setNewIconLines,
            activeThumbColor: palette.onAccent,
            activeTrackColor: palette.accent,
          ),
        ],
      ),
    );
  }
}

class _RoomsCard extends StatelessWidget {
  const _RoomsCard({required this.state, required this.strings});

  final AppState state;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
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
              Icons.meeting_room_outlined,
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
                  strings.showRooms,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.showRoomsHint,
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
            value: state.showRooms,
            onChanged: state.setShowRooms,
            activeThumbColor: palette.onAccent,
            activeTrackColor: palette.accent,
          ),
        ],
      ),
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
    final entries = AppLog.instance.entries.length;
    final errors = AppLog.instance.errorCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.border),
        ),
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
                    widget.strings.logsSummary(entries, errors),
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
