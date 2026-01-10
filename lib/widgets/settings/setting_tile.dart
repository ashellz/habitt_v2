import 'package:flutter/material.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/default_switch.dart';
import 'package:provider/provider.dart';

class SettingTile extends StatefulWidget {
  const SettingTile({
    super.key,
    required this.title,
    required this.desc,
    required this.icon,
    required this.onTap,
    this.hasSwitch = false,
    this.switchValue = false,
    this.hasArrow = false,
    this.trailing,
  });

  final String title;
  final String desc;
  final Widget icon;
  final void Function() onTap;
  final bool hasSwitch;
  final bool switchValue;
  final bool hasArrow;
  final Widget? trailing;

  @override
  State<SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<SettingTile> {
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isTinted =
        context.watch<PreferencesProvider>().colorfulness ==
        Colorfulness.tinted;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: Duration(milliseconds: 150),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child:
              !widget.hasSwitch
                  ? GestureDetector(
                    onTapDown: (details) {
                      setState(() {
                        _opacity = 0.5;
                      });
                    },
                    onTapUp: (details) {
                      setState(() {
                        _opacity = 1.0;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _opacity = 1.0;
                      });
                    },
                    onTap: () {
                      setState(() {
                        _opacity = 0.5;
                      });

                      widget.onTap();

                      Future.delayed(const Duration(milliseconds: 150), () {
                        setState(() {
                          _opacity = 1.0;
                        });
                      });
                    },
                    child: mainWidget(tp, isTinted),
                  )
                  : mainWidget(tp, isTinted),
        ),
      ),
    );
  }

  Widget getTrailingWidget(ThemeProvider tp) {
    Widget trailingWidget;

    if (widget.trailing != null) {
      trailingWidget = widget.trailing!;
    } else if (widget.hasArrow) {
      trailingWidget = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: tp.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tp.borderColor, width: 2),
        ),
        child: Icon(
          Icons.chevron_right_rounded,
          color: tp.primaryTextColor,
          size: 24,
        ),
      );
    } else if (widget.hasSwitch) {
      trailingWidget = DefaultSwitch(
        switchValue: widget.switchValue,
        onTap: () {
          widget.onTap();
        },
      );
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: trailingWidget,
    );
  }

  Container mainWidget(ThemeProvider tp, bool isTinted) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Row(
        children: [
          SizedBox(width: 32, height: 32, child: widget.icon),
          const SizedBox(width: 16), // spacing between icon and text
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: tp.primaryTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        widget.desc,
                        style: TextStyle(color: tp.primaryTextColor),
                      ),
                    ],
                  ),
                ),
                getTrailingWidget(tp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
