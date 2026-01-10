import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:provider/provider.dart';

class BackupDataPage extends StatelessWidget {
  const BackupDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              const SizedBox(height: 48),
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
              Text(
                "You are currently not connected to your Google account.",
                style: TextStyle(fontSize: 16, color: tp.secondaryTextColor),
              ),
              DefaultButton(onPressed: () {}, label: "Connect to Google"),
            ],
          ),
        ),
      ),
    );
  }
}
