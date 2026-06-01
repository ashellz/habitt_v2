import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/profile_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/profile/edit_profile_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinycolor2/tinycolor2.dart';

class ProfileTopPart extends StatefulWidget {
  const ProfileTopPart({super.key, required this.cp});

  final ColorProvider cp;

  @override
  State<ProfileTopPart> createState() => _ProfileTopPartState();
}

class _ProfileTopPartState extends State<ProfileTopPart> {
  String? name;
  String? email;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }


  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      name = prefs.getString('name');
      email = prefs.getString('backup_user_email');
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bp = context.watch<BackupProvider>();
    final googleName = bp.currentUser?.displayName;
    final name = this.name ?? googleName ?? loc.guest;
    final googlePhotoUrl = bp.isLoggedIn ? bp.currentUser?.photoUrl : null;
    final email = bp.isLoggedIn ? (bp.currentUser?.email ?? this.email ?? '') : '';

    return Container(
      color: widget.cp.bg,
      child: Padding(
        padding: EdgeInsets.only(
          top: 20 + MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
        ),
        child: Column(
          spacing: 14,
          children: [
            _topBar(widget.cp),
            Column(
              spacing: 16,
              children: [
                Consumer<ProfileImageProvider>(
                  builder: (context, pip, _) {
                    final file = pip.imageFile;
                    Widget avatarChild;
                    if (file != null) {
                      avatarChild = Image.file(
                        file,
                        fit: BoxFit.cover,
                        key: Key('profile_image_${pip.version}'),
                      );
                    } else if (googlePhotoUrl != null) {
                      avatarChild = Image.network(
                        googlePhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    } else {
                      avatarChild = Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return Container(
                      height: 80,
                      width: 80,
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(child: avatarChild),
                    );
                  },
                ),
                Column(
                  spacing: 8,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.cp.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          color: widget.cp.lightGreyText,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Row _topBar(ColorProvider cp) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          loc.profile,
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),

        NewCircleButton(
          svgPath: 'assets/images/new-svg/edit.svg',
          cnIcon: CNSymbol('pencil.line', size: 14),
          width: 44,
          height: 44,
          color: cp.bg,
          padding: const EdgeInsets.all(13),
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
              barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
              isScrollControlled: true,
              builder: (context) => EditProfileSheet(),
            );

            await _loadProfile();
            await context.read<ProfileImageProvider>().load();
          },
        ),
      ],
    );
  }
}
