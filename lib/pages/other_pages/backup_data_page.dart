import 'package:flutter/material.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/color_contrast.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class BackupDataPage extends StatefulWidget {
  const BackupDataPage({super.key});

  @override
  State<BackupDataPage> createState() => _BackupDataPageState();
}

class _BackupDataPageState extends State<BackupDataPage> {
  String getLastSyncText(BackupProvider backupProvider) {
    final loc = AppLocalizations.of(context)!;
    if (backupProvider.localMetadata == null) {
      return loc.never;
    } else {
      final date = backupProvider.localMetadata!.createdAt;
      // DD.MM.YYYY - HH:MM
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return "$day.$month.$year - $hour:$minute";
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final backupProvider = context.watch<BackupProvider>();
    final bool isLoggedIn = backupProvider.isLoggedIn;

    final platform = Theme.of(context).platform;
    final double extraPadding = platform == TargetPlatform.android ? 12 : 0;
    final loc = AppLocalizations.of(context)!;

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NavBackButton(tp: tp),

                    Text(
                      loc.backupData,
                      style: TextStyle(
                        fontSize: 38,
                        color: tp.primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      loc.keepYourDataSafeByBackingItUpToGoogleDrive,
                      style: TextStyle(
                        fontSize: 16,
                        color: tp.secondaryTextColor,
                      ),
                    ),
                    Spacer(),
                    if (!isLoggedIn) ...[
                      Text(
                        loc.youAreCurrentlyNotConnectedToYourGoogleAccount,
                        style: TextStyle(
                          fontSize: 16,
                          color: tp.secondaryTextColor,
                        ),
                      ),
                      DefaultButton(
                        onPressed: () async {
                          try {
                            await backupProvider.signIn(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Google sign-in failed. Please try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        label: loc.connectToGoogle,
                      ),
                    ] else ...[
                      Text(
                        "Connected as ${backupProvider.currentUser?.email}",
                        style: TextStyle(
                          fontSize: 16,
                          color: tp.secondaryTextColor,
                        ),
                      ),
                      Text(
                        getSyncProgressText(),
                        style: TextStyle(
                          fontSize: 16,
                          color: tp.secondaryTextColor,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: extraPadding),
                        child: Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: DefaultButton(
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => OldDefaultDialog(
                                          title: loc.optOutOfBackup,
                                          desc: loc.optOutOfBackup,
                                          rightButtonCallback: () async {
                                            backupProvider.signOut();
                                          },
                                          rightButtonText: loc.optOut,
                                          danger: true,
                                          leftButtonText: "Cancel",
                                        ),
                                  );
                                },
                                label: loc.optOut,
                                color: tp.backgroundColor,
                              ),
                            ),
                            Expanded(
                              child: DefaultButton(
                                isLoading:
                                    backupProvider.syncState ==
                                    SyncState.syncing,
                                prefix: Icon(
                                  Icons.sync,
                                  color: bestContrastingOn(
                                    tp.primaryButtonBackground,
                                  ),
                                ),
                                onPressed: () async {
                                  await backupProvider.performSync(true);
                                },
                                label: loc.syncNow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getSyncProgressText() {
    final backupProvider = context.read<BackupProvider>();
    final syncState = backupProvider.syncState;
    final lastSyncText = getLastSyncText(backupProvider);
    final progressMessage = backupProvider.progressMessage;
    final errorMessage = backupProvider.lastError;
    final loc = AppLocalizations.of(context)!;

    switch (syncState) {
      case SyncState.idle:
        return loc.lastSynced(lastSyncText);
      case SyncState.syncing:
        return progressMessage != null && progressMessage.isNotEmpty
            ? loc.syncingProgressmessage(progressMessage)
            : loc.syncing;
      case SyncState.success:
        return loc.lastSynced(lastSyncText);
      case SyncState.error:
        return errorMessage != null && errorMessage.isNotEmpty
            ? loc.syncErrorErrormessage(errorMessage)
            : loc.lastSynced(lastSyncText);
    }
  }
}
