import 'package:flutter/material.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/color_contrast.dart';
import 'package:habitt/widgets/default/alert_popup.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:habitt/widgets/dialogs/passphrase_dialog.dart';
import 'package:provider/provider.dart';

class BackupDataPage extends StatefulWidget {
  const BackupDataPage({super.key});

  @override
  State<BackupDataPage> createState() => _BackupDataPageState();
}

class _BackupDataPageState extends State<BackupDataPage> {
  String? _alertMessage;
  bool _showAlert = false;

  void _displayAlert(String message) {
    setState(() {
      _alertMessage = message;
      _showAlert = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAlert = false;
        });
      }
    });
  }

  String getLastSyncText(BackupProvider backupProvider) {
    if (backupProvider.localMetadata == null) {
      return "Never";
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
    final bool hasPassphraseSet = backupProvider.hasPassphraseSet;
    final bool dataExists = backupProvider.dataExists;

    final platform = Theme.of(context).platform;
    final double extraPadding = platform == TargetPlatform.android ? 12 : 0;

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
                      "Backup Data",
                      style: TextStyle(
                        fontSize: 38,
                        color: tp.primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Keep your data safe by backing it up to Google Drive.",
                      style: TextStyle(
                        fontSize: 16,
                        color: tp.secondaryTextColor,
                      ),
                    ),
                    Spacer(),
                    if (!isLoggedIn) ...[
                      Text(
                        "You are currently not connected to your Google account.",
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
                        label: "Connect to Google",
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
                                          title: "Opt out of Backup?",
                                          desc:
                                              "Are you sure you want to opt out of data backup? This will disconnect your Google account and stop all backups. Your existing backups on Google Drive will remain unless you delete them manually.",
                                          rightButtonCallback: () async {
                                            backupProvider.signOut();
                                          },
                                          rightButtonText: "Opt out",
                                          danger: true,
                                          leftButtonText: "Cancel",
                                        ),
                                  );
                                },
                                label: "Opt out",
                                color: tp.backgroundColor,
                              ),
                            ),
                            Expanded(
                              child: DefaultButton(
                                isLoading:
                                    backupProvider.syncState ==
                                    SyncState.syncing,
                                prefix: Icon(
                                  hasPassphraseSet ? Icons.sync : Icons.lock,
                                  color: bestContrastingOn(
                                    tp.primaryButtonBackground,
                                  ),
                                ),
                                onPressed: () async {
                                  if (!hasPassphraseSet) {
                                    await showDialog(
                                      context: context,
                                      builder: (context) {
                                        final TextEditingController controller =
                                            TextEditingController();
                                        return PassphraseDialog(
                                          controller: controller,
                                          dataExists: dataExists,
                                          displayAlert: _displayAlert,
                                        );
                                      },
                                    );
                                  } else {
                                    await backupProvider.performSync(true);
                                  }
                                },
                                label:
                                    hasPassphraseSet
                                        ? "Sync Now"
                                        : dataExists
                                        ? "Enter Passphrase"
                                        : "Set Passphrase",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AlertPopup(message: _alertMessage, show: _showAlert),
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

    switch (syncState) {
      case SyncState.idle:
        return "Last synced: $lastSyncText";
      case SyncState.syncing:
        return progressMessage != null && progressMessage.isNotEmpty
            ? "Syncing: $progressMessage"
            : "Syncing...";
      case SyncState.success:
        return "Last synced: $lastSyncText";
      case SyncState.error:
        return errorMessage != null && errorMessage.isNotEmpty
            ? "Sync error: $errorMessage"
            : "Last synced: $lastSyncText";
    }
  }
}
