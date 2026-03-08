import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';

class NewDefaultDialog extends StatelessWidget {
  const NewDefaultDialog({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cp.bg,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
