import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import 'settings_common.dart';

class AliasesSettingsScreen extends StatelessWidget {
  const AliasesSettingsScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    AppState state,
    String subject,
  ) async {
    final strings = state.strings;
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
    final state = context.watch<AppState>();
    final strings = state.strings;
    final subjects = state.resolver.subjects;

    return SettingsSubScaffold(
      title: strings.settingsAliases,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2, bottom: 24),
        children: <Widget>[
          if (subjects.isEmpty)
            SettingsCard(
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
            )
          else
            SettingsCard(
              padding: const EdgeInsets.fromLTRB(14, 2, 10, 2),
              child: Column(
                children: <Widget>[
                  for (var index = 0;
                      index < subjects.length;
                      index++) ...<Widget>[
                    if (index > 0) Divider(height: 1, color: palette.border),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _edit(context, state, subjects[index]),
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
                                    state.resolver
                                            .aliasesFor(subjects[index])
                                            .isEmpty
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
            ),
        ],
      ),
    );
  }
}
