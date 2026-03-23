import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

Future<bool?> showDialogSheet({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) async {
  final cp = context.read<ColorProvider>();
  return await showModalBottomSheet(
    backgroundColor: Colors.transparent,
    barrierColor: cp.greyText.darken().withOpacity(0.3),
    isScrollControlled: true,
    context: context,
    builder: builder,
  );
}
