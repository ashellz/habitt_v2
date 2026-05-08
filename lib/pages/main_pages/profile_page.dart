import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class ProfileTopPart extends StatefulWidget {
  const ProfileTopPart({super.key, required this.cp});

  final ColorProvider cp;

  @override
  State<ProfileTopPart> createState() => _ProfileTopPartState();
}

class _ProfileTopPartState extends State<ProfileTopPart> {
  String? name;

  @override
  void initState() {
    super.initState();

    // Loading name
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        name = prefs.getString('name');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = this.name ?? 'Guest';

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
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
                    Text(
                      'oliviaolivia@gmail.com',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Profile',
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
          onPressed: () async {},
        ),
      ],
    );
  }
}

class ProfileOptions extends StatelessWidget {
  const ProfileOptions({super.key, required this.cp});

  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      color: cp.habitBg,
      child: Column(
        spacing: 10,
        children: [
          GetPremiumWidget(cp: cp),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: cp.field,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: cp.border),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    ProfileOption(
                      cp: cp,
                      text: 'Privacy policy',
                      svgPath: 'assets/images/new-svg/privacy-policy.svg',
                    ),

                    Divider(color: cp.border, height: 32),
                    ProfileOption(
                      cp: cp,
                      text: 'Terms of service',
                      svgPath: 'assets/images/new-svg/terms.svg',
                    ),
                    Divider(color: cp.border, height: 32),
                    ProfileOption(
                      cp: cp,
                      text: 'Rate us',
                      svgPath: 'assets/images/new-svg/rate.svg',
                    ),
                    Divider(color: cp.border, height: 32),
                    ProfileOption(
                      cp: cp,
                      text: 'Backup & Sync',
                      svgPath: 'assets/images/new-svg/backup.svg',
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: cp.field,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: cp.border),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    Text(
                      'Log out',
                      style: TextStyle(
                        color: cp.error,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    SvgPicture.asset(
                      'assets/images/new-svg/log-out.svg',
                      colorFilter: ColorFilter.mode(cp.error, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  const ProfileOption({
    super.key,
    required this.cp,
    required this.text,
    required this.svgPath,
  });

  final ColorProvider cp;
  final String text;
  final String svgPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Row(
        spacing: 12,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: SvgPicture.asset(
              svgPath,
              colorFilter: ColorFilter.mode(cp.lightGreyText, BlendMode.srcIn),
              fit: BoxFit.contain,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: cp.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          RotatedBox(
            quarterTurns: 2,
            child: SvgPicture.asset(
              'assets/images/new-svg/back.svg',
              colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}

class GetPremiumWidget extends StatelessWidget {
  const GetPremiumWidget({super.key, required this.cp});

  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: cp.bg,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.hardEdge,

      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/widget-images/premium-widget.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(
                      'Get Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    Text(
                      'Enjoy all the benefits of the app',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: Image.asset(
                    'assets/images/widget-images/gem.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
