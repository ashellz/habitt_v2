import 'dart:io';

import 'package:cupertino_native_better/components/button.dart';
import 'package:cupertino_native_better/style/button_style.dart';
import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/glass_blur_container.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class CircleButton extends StatefulWidget {
  const CircleButton({
    super.key,
    required this.tp,
    required this.icon,
    required this.cnIcon,
    required this.color,
    this.onPressed,
  });

  final ThemeProvider tp;
  final Widget icon;
  final CNSymbol cnIcon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  State<CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> {
  bool _supportsLiquidGlass = false;
  double scale = 1.0;

  Future<void> _checkIOSVersion() async {
    if (Platform.isIOS) {
      debugPrint("Checking iOS version for Liquid Glass support");
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      final version = iosInfo.systemVersion;
      final majorVersion = int.tryParse(version.split('.').first) ?? 0;
      debugPrint("iOS Major Version: $majorVersion");
      setState(() {
        _supportsLiquidGlass = majorVersion >= 26;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkIOSVersion();
  }

  @override
  Widget build(BuildContext context) {
    final preferencesProvider = context.watch<PreferencesProvider>();
    final glassFeel = preferencesProvider.glassFeel;
    if (_supportsLiquidGlass && glassFeel) {
      return SizedBox(
        height: 50,
        width: 50,
        child: CNButton.icon(
          icon: widget.cnIcon,
          onPressed: widget.onPressed,
          tint: widget.color,
          config: CNButtonConfig(style: CNButtonStyle.prominentGlass),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          scale = 0.9;
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() {
            scale = 1.0;
          });
        });

        if (widget.onPressed != null) {
          widget.onPressed!();
        }
      },
      onTapDown: (context) {
        setState(() {
          scale = 0.9;
        });
      },

      onTapCancel: () {
        setState(() {
          scale = 1.0;
        });
      },
      onTapUp: (context) {
        setState(() {
          scale = 1.0;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: scale,
        child: GlassBlurContainer(
          height: 50,
          width: 50,
          color: widget.color,
          borderRadius: 100,
          padding: const EdgeInsets.all(8),
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}
