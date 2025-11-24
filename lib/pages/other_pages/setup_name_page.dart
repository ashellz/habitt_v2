import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/pulse_animation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Widget getSuffixIcon(ColorProvider colorProvider) {
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
                    color: colorProvider.textColor,
                    size: 16,
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: colorProvider.backgroundColor,
        statusBarIconBrightness:
            colorProvider.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colorProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light, // for iOS
      ),
      child: Scaffold(
        backgroundColor: colorProvider.backgroundColor,
        body: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: PulseAnimation(_animation.value, colorProvider),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Welcome to Habitt.",
                        style: TextStyle(
                          color: colorProvider.textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "What should we call you?",
                        style: TextStyle(color: colorProvider.textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        style: TextStyle(
                          color: colorProvider.textColor,
                          fontSize: 14,
                        ),
                        cursorColor: colorProvider.textColor,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colorProvider.mutedTextColor.withAlpha(50),

                          hintText: "Your name",
                          hintStyle: TextStyle(
                            color: colorProvider.mutedTextColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          suffix: getSuffixIcon(colorProvider),
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
