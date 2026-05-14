import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/rate_bug_report_service.dart';
import 'package:habitt/widgets/profile/profile_options.dart';
import 'package:habitt/widgets/profile/profile_top_part.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: cp.habitBg,
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [ProfileTopPart(cp: cp), ProfileOptions(cp: cp)],
      ),
    );
  }
}
