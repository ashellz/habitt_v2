import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingTile extends StatefulWidget {
  const SettingTile({
    super.key,
    required this.title,
    required this.desc,
    required this.iconData,
    required this.onTap,
    this.hasSwitch = false,
    this.switchValue = false,
  });

  final String title;
  final String desc;
  final IconData iconData;
  final void Function() onTap;
  final bool hasSwitch;
  final bool switchValue;

  @override
  State<SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<SettingTile> {
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

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
                    child: mainWidget(tp),
                  )
                  : mainWidget(tp),
        ),
      ),
    );
  }

  Container mainWidget(ThemeProvider tp) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Row(
        children: [
          Icon(widget.iconData, color: tp.primaryColor, size: 32),
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
                if (widget.hasSwitch)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Switch(
                      activeTrackColor: tp.successColor,
                      activeThumbColor: Colors.white,
                      inactiveThumbColor: tp.primaryTextColor,
                      inactiveTrackColor: tp.surfaceColor,
                      value: widget.switchValue,
                      onChanged: (value) {
                        widget.onTap();
                      },
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
