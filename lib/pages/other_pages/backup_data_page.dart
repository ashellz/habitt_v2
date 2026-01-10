import 'package:flutter/material.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/color_contrast.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:provider/provider.dart';

class BackupDataPage extends StatelessWidget {
  const BackupDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final backupProvider = context.watch<BackupProvider>();
    final bool isLoggedIn = backupProvider.isLoggedIn;

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
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
                style: TextStyle(fontSize: 16, color: tp.secondaryTextColor),
              ),
              const SizedBox(height: 32),
              if (!isLoggedIn) ...[
                Text(
                  "You are currently not connected to your Google account.",
                  style: TextStyle(fontSize: 16, color: tp.secondaryTextColor),
                ),
                DefaultButton(
                  onPressed: () async {
                    try {
                      await backupProvider.signIn();
                      if (context.mounted) {
                        await backupProvider.performSync();
                      }
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
                  style: TextStyle(fontSize: 16, color: tp.secondaryTextColor),
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: DefaultButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder:
                                (context) => DefaultDialog(
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
                            backupProvider.syncState == SyncState.syncing,
                        prefix: Icon(
                          Icons.sync,
                          color: bestContrastingOn(tp.primaryButtonBackground),
                        ),
                        onPressed: () async {
                          await backupProvider.performSync();
                        },
                        label: "Sync Now",
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
