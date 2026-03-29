import 'package:flutter/material.dart';
import 'package:habitt/pages/other_pages/backup_data_page.dart';
import 'package:habitt/pages/other_pages/notifications_page.dart';
import 'package:habitt/pages/other_pages/subscriptions_page.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/services/backup_service.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/alert_popup.dart';
import 'package:habitt/widgets/default/custom_switcher_wrapper.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:habitt/widgets/default/default_text_field.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/settings/select_color_sheet.dart';
import 'package:habitt/widgets/settings/segmented_control.dart';
import 'package:habitt/widgets/settings/setting_tile.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _alertMessage;
  bool _showAlert = false;

  String? appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;

    // v2+build
    setState(() {
      final versionCore = packageInfo.version.split('+').first;
      appVersion =
          "v${_stripTrailingZeroSegments(versionCore)}+${packageInfo.buildNumber} (alpha)";
    });
  }

  String _stripTrailingZeroSegments(String version) {
    final parts = version.split('.');
    while (parts.isNotEmpty && parts.last == '0') {
      parts.removeLast();
    }
    return parts.isEmpty ? '0' : parts.join('.');
  }

  Future<void> _handleExport(BuildContext context) async {
    final result = await _showOperationDialog(
      context,
      title: 'Set export passphrase',
      buttonText: 'Export',
      operation:
          (passphrase) => BackupService.exportDataLocally(
            context: context,
            passphrase: passphrase,
          ),
    );

    if (result == BackupOperationResult.success) {
      _displayAlert('Exported backup.');
    } else if (result == BackupOperationResult.failed) {
      _displayAlert('Export failed.');
    }
    // If cancelled, show no popup
  }

  Future<void> _handleImport(BuildContext context) async {
    final result = await _showOperationDialog(
      context,
      title: 'Enter passphrase',
      buttonText: 'Import',
      operation:
          (passphrase) => BackupService.importLocalData(
            context: context,
            passphrase: passphrase,
          ),
    );

    if (result == BackupOperationResult.success) {
      _displayAlert('Import complete.');
    } else if (result == BackupOperationResult.failed) {
      _displayAlert('Import failed.');
    } else if (result == BackupOperationResult.wrongPassphrase) {
      _displayAlert('Wrong passphrase.');
    }
    // If cancelled, show no popup
  }

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

  Future<BackupOperationResult> _showOperationDialog(
    BuildContext context, {
    required String title,
    required String buttonText,
    required Future<BackupOperationResult> Function(String passphrase)
    operation,
  }) async {
    final controller = TextEditingController();

    final result = await showDialog<BackupOperationResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            controller.addListener(() {
              if (!isLoading) setState(() {});
            });

            return DefaultDialog(
              title: title,
              desc:
                  "You will use this passphrase to decrypt your data when importing it.",
              content: DefaultTextField(
                controller: controller,
                title: "Passphrase",
                obscureText: true,
              ),
              leftButtonText: "Cancel",
              rightButtonText: buttonText,
              rightButtonEnabled: controller.text.isNotEmpty && !isLoading,
              rightButtonLoading: isLoading,
              rightButtonCallback: () async {
                setState(() {
                  isLoading = true;
                });
                final result = await operation(controller.text);
                if (context.mounted) {
                  Navigator.of(context).pop(result);
                }
              },
            );
          },
        );
      },
    );

    return result ?? BackupOperationResult.cancelled;
  }

  @override
  Widget build(BuildContext context) {
    final prefsProvider = context.watch<PreferencesProvider>();
    final tp = context.watch<ThemeProvider>();
    final cp = context.watch<ColorProvider>();
    bool isTinted = prefsProvider.colorfulness == Colorfulness.tinted;
    final Color primary = tp.primaryColor;

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: Stack(
          children: [
            GradientBackground(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Settings",
                          style: TextStyle(
                            fontSize: 38,
                            color: tp.primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (appVersion != null)
                          Text(
                            appVersion!,
                            style: TextStyle(
                              fontSize: 16,
                              color: tp.secondaryTextColor,
                            ),
                          ),
                      ],
                    ),
                    SettingTile(
                      title: "Dark Mode",
                      desc: "Change a color theme for your interface",
                      icon: CustomSwitcherWrapper(
                        value: isTinted,
                        widget: Icon(
                          Icons.dark_mode,
                          color: tp.primaryColor,
                          size: 32,
                        ),
                        secondaryWidget: Image.asset(
                          "assets/images/icons/moon.png",
                        ),
                      ),
                      hasSwitch: true,
                      switchValue: tp.isDark && cp.isDark,
                      onTap: () {
                        tp.setMode(
                          tp.isDark ? ThemeMode.light : ThemeMode.dark,
                        );
                        cp.setMode(
                          cp.isDark ? ColorMode.light : ColorMode.dark,
                        );
                      },
                    ),
                    SettingTile(
                      title: "Accent Color",
                      desc: "Select a color pallete for your interface",
                      trailing: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: primary,
                          border: Border.all(
                            color: primary.darken(tp.isDark ? 20 : 10),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.28),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        height: 36,
                        width: 36,
                      ),
                      icon: CustomSwitcherWrapper(
                        delay: Duration(milliseconds: 100),
                        value: isTinted,
                        widget: Icon(
                          Icons.color_lens,
                          color: tp.primaryColor,
                          size: 32,
                        ),
                        secondaryWidget: Image.asset(
                          "assets/images/icons/color-wheel.png",
                        ),
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          enableDrag: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SelectColorSheet(tp: tp),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomSwitcherWrapper(
                            delay: Duration(milliseconds: 200),
                            value: isTinted,
                            widget: Icon(
                              Icons.colorize,
                              color: tp.primaryColor,
                              size: 32,
                            ),
                            secondaryWidget: Image.asset(
                              "assets/images/icons/colorful.png",
                              width: 32,
                              height: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Colorful Interface",
                                  style: TextStyle(
                                    color: tp.primaryTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "Choose how colorful the UI should be",
                                  style: TextStyle(color: tp.primaryTextColor),
                                ),
                                const SizedBox(height: 8),
                                SegmentedControl(
                                  segments: const [
                                    'Tinted',
                                    'Standard',
                                    'Colorful',
                                  ],
                                  selectedIndex:
                                      prefsProvider.colorfulness.index,
                                  onChanged: (i) {
                                    prefsProvider.setColorfulness(i);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SettingTile(
                      title: "Glass Feel",
                      desc: "Makes widgets look more glassy",
                      icon: CustomSwitcherWrapper(
                        delay: Duration(milliseconds: 300),
                        value: isTinted,
                        widget: Icon(
                          Icons.blur_on,
                          color: tp.primaryColor,
                          size: 32,
                        ),
                        secondaryWidget: Image.asset(
                          "assets/images/icons/blur.png",
                          width: 32,
                          height: 32,
                        ),
                      ),
                      hasSwitch: true,
                      switchValue: prefsProvider.glassFeel,
                      onTap: () {
                        prefsProvider.toggleGlassFeel();
                      },
                    ),

                    SettingTile(
                      title: "Notifications",
                      desc: "Manage your notification preferences",
                      icon: CustomSwitcherWrapper(
                        delay: Duration(milliseconds: 400),
                        value: isTinted,
                        widget: Icon(
                          Icons.notifications,
                          color: tp.primaryColor,
                          size: 32,
                        ),
                        secondaryWidget: Image.asset(
                          "assets/images/icons/notification.png",
                        ),
                      ),
                      hasArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsPage(),
                          ),
                        );
                      },
                    ),

                    SettingTile(
                      title: "Subscriptions",
                      desc:
                          "Manage your subscriptions and view premium benefits",
                      icon: CustomSwitcherWrapper(
                        delay: Duration(milliseconds: 500),
                        value: isTinted,
                        widget: Icon(
                          Icons.monetization_on,
                          color: tp.primaryColor,
                          size: 32,
                        ),
                        secondaryWidget: Image.asset(
                          "assets/images/icons/subscription.png",
                        ),
                      ),
                      hasArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubscriptionsPage(),
                          ),
                        );
                      },
                    ),

                    SettingTile(
                      title: "Backup Data",
                      desc:
                          "Use your google drive to backup encrypted app data",
                      icon: CustomSwitcherWrapper(
                        delay: Duration(milliseconds: 600),
                        value: isTinted,
                        widget: Icon(
                          Icons.sync,
                          color: tp.primaryColor,
                          size: 32,
                        ),
                        secondaryWidget: Image.asset(
                          "assets/images/icons/google-drive.png",
                        ),
                      ),
                      hasArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BackupDataPage(),
                          ),
                        );
                      },
                    ),

                    SettingTile(
                      title: 'Export Data',
                      desc: 'Backup all habits and days to encrypted file',
                      icon: CustomSwitcherWrapper(
                        delay: Duration(milliseconds: 700),
                        value: isTinted,
                        widget: Icon(
                          Icons.file_upload,
                          color: tp.primaryColor,
                          size: 32,
                        ),
                        secondaryWidget: Image.asset(
                          "assets/images/icons/export.png",
                          width: 32,
                          height: 32,
                        ),
                      ),
                      onTap: () => _handleExport(context),
                    ),
                    SettingTile(
                      title: 'Import Data',
                      desc: 'Restore from encrypted backup file',
                      icon: CustomSwitcherWrapper(
                        delay: Duration(milliseconds: 800),
                        value: isTinted,
                        widget: Icon(
                          Icons.file_download,
                          color: tp.primaryColor,
                          size: 32,
                        ),
                        secondaryWidget: Image.asset(
                          "assets/images/icons/import.png",
                          width: 32,
                          height: 32,
                        ),
                      ),
                      onTap: () => _handleImport(context),
                    ),

                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            AlertPopup(message: _alertMessage, show: _showAlert),
          ],
        ),
      ),
    );
  }
}
