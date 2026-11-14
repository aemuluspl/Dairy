import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_text.dart';
import '../../state/app_state.dart';
import '../../widgets/app_snackbar.dart';
import 'settings_common.dart';

class UpdateSettingsScreen extends StatelessWidget {
  const UpdateSettingsScreen({super.key});

  Future<void> _download(BuildContext context, AppState state) async {
    final raw = state.updateUrl ?? AppInfo.releasesPageUrl;
    final uri = Uri.tryParse(raw);
    var opened = false;
    if (uri != null) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!opened && context.mounted) {
      showAppSnackBar(
        context,
        state.strings.updateDownloadFailed,
        icon: Icons.error_outline_rounded,
        isError: true,
      );
    }
  }

  Future<void> _check(BuildContext context, AppState state) async {
    final available = await state.checkForUpdates(force: true);
    if (!context.mounted) return;
    if (!available && state.latestVersion == null) {
      showAppSnackBar(
        context,
        state.strings.updateCheckFailed,
        icon: Icons.error_outline_rounded,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<AppState>();
    final strings = state.strings;
    final available = state.updateAvailable;
    final latest = state.latestVersion;
    final checkedAt = state.lastUpdateCheck;
    final statusTitle = available && latest != null
        ? strings.updateAvailableTitle(latest)
        : latest == null
            ? strings.updateNotChecked
            : strings.updateUpToDate;

    return SettingsSubScaffold(
      title: strings.settingsUpdate,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 2, bottom: 24),
        children: <Widget>[
          SettingsCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: <Widget>[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: available ? palette.dangerSoft : palette.accentSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    available
                        ? Icons.system_update_rounded
                        : latest == null
                            ? Icons.cloud_sync_rounded
                            : Icons.verified_rounded,
                    size: 26,
                    color: available ? palette.danger : palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  statusTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${strings.updateCurrentVersion}: ${state.version}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textMuted,
                  ),
                ),
                if (checkedAt != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    strings.updateLastCheck(
                      formatDeadline(
                        checkedAt,
                        english: strings.isEnglish,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textMuted,
                    ),
                  ),
                ],
                if (available) ...<Widget>[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _download(context, state),
                      icon: const Icon(Icons.download_rounded, size: 19),
                      label: Text(strings.updateDownload),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: palette.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  state.updateChecking ? null : () => _check(context, state),
              icon: state.updateChecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 19),
              label: Text(
                state.updateChecking
                    ? strings.updateChecking
                    : strings.updateCheck,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.textPrimary,
                side: BorderSide(color: palette.border),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
