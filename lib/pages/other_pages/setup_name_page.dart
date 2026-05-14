import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/habits_page/pulse_animation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitt/l10n/app_localizations.dart';

class SetupNamePage extends StatefulWidget {
  const SetupNamePage({
    super.key,
    required this.prefs,
    required this.stateSetter,
  });

  final SharedPreferences prefs;
  final StateSetter stateSetter;

  @override
  State<SetupNamePage> createState() => _SetupNamePageState();
}

class _SetupNamePageState extends State<SetupNamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Widget getSuffixIcon(ThemeProvider tp) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 150),
      switchInCurve: Curves.decelerate,
      switchOutCurve: Curves.decelerate,
      child: KeyedSubtree(
        key: _nameController.text == "" ? ValueKey(1) : ValueKey(2),
        child:
            _nameController.text == ""
                ? SizedBox.shrink()
                : GestureDetector(
                  onTap: () {
                    debugPrint("Setting name to: ${_nameController.text}");
                    widget.stateSetter(() {
                      widget.prefs.setString('name', _nameController.text);
                      final dateJoined = widget.prefs.getString('dateJoined');
                      if (dateJoined == null) {
                        widget.prefs.setString(
                          'dateJoined',
                          DateTime.now().toString(),
                        );
                      }
                    });
                  },
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: tp.primaryTextColor,
                    size: 16,
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final loc = AppLocalizations.of(context)!;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: tp.backgroundColor,
        statusBarIconBrightness: tp.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            tp.isDark ? Brightness.dark : Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: PulseAnimation(_animation.value, tp),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        loc.welcomeToHabitt,
                        style: TextStyle(
                          color: tp.primaryTextColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        loc.whatShouldWeCallYou,
                        style: TextStyle(color: tp.primaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        style: TextStyle(
                          color: tp.primaryTextColor,
                          fontSize: 14,
                        ),
                        cursorColor: tp.primaryTextColor,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: tp.mutedTextColor.withAlpha(50),

                          hintText: loc.yourName,
                          hintStyle: TextStyle(color: tp.mutedTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          suffix: getSuffixIcon(tp),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
