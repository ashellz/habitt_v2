import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

enum ProgressType { amount, duration }

class LogProgressDialog extends StatelessWidget {
  const LogProgressDialog({
    super.key,
    required this.progressType,
    required this.habit,
  });

  final ProgressType progressType;
  final Habit habit;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [titleAndDesc(cp), progress(cp), buttons(cp, context)],
        ),
      ),
    );
  }

  Widget progress(ColorProvider cp) {
    return Column(
      spacing: 16,
      children: [
        if (progressType == ProgressType.amount)
          AmountProgressInput(
            amount: habit.amount,
            amountCompleted: habit.amountCompleted,
          )
        else
          DurationProgressInput(),
        target(cp),
      ],
    );
  }

  Row buttons(ColorProvider cp, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: 8,
      children: [
        Expanded(
          child: NewDefaultButton.secondary(
            onPressed: () {
              Navigator.pop(context);
            },
            label: "Cancel",
          ),
        ),
        Expanded(
          child: NewDefaultButton.primary(
            onPressed: () {
              Navigator.pop(context);
            },
            label: "Save",
          ),
        ),
      ],
    );
  }

  Row target(ColorProvider cp) {
    String getTargetText() {
      if (progressType == ProgressType.amount) {
        return "${habit.amount} ${habit.amountLabel.isEmpty ? "times" : habit.amountLabel}";
      } else {
        final hours = habit.duration ~/ 60;
        final minutes = habit.duration % 60;

        return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Target:',
          style: TextStyle(
            color: cp.text,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SvgPicture.asset("assets/images/new-svg/clock.svg"),
            Text(
              getTargetText(),
              style: TextStyle(
                color: const Color(0xFF0B0B0B),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column titleAndDesc(ColorProvider cp) {
    final title =
        progressType == ProgressType.amount ? "Log progress" : "Log duration";
    final desc =
        progressType == ProgressType.amount
            ? "How much did you complete today?"
            : "How much time did you spend on this habit today?";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          title,
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(desc, style: TextStyle(color: cp.greyText, fontSize: 16)),
      ],
    );
  }
}

class AmountProgressInput extends StatelessWidget {
  const AmountProgressInput({
    super.key,
    required this.amount,
    required this.amountCompleted,
  });

  final int amount;
  final int amountCompleted;

  @override
  Widget build(BuildContext context) {
    return NewDefaultTextField(
      title: "Amount",
      digitsOnly: true,
      centerValue: true,
      controller: TextEditingController(),
      prefix: IconButton(
        style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory),
        onPressed: () {},
        icon: SvgPicture.asset("assets/images/new-svg/minus.svg"),
      ),
      suffix: IconButton(
        style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory),
        onPressed: () {},
        icon: SvgPicture.asset("assets/images/new-svg/plus.svg"),
      ),
    );
  }
}

class DurationProgressInput extends StatelessWidget {
  const DurationProgressInput({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
