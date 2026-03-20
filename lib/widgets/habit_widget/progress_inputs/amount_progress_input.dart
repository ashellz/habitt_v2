import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

class AmountProgressInput extends StatefulWidget {
  const AmountProgressInput({
    super.key,
    required this.amount,
    this.amountCompleted,
  });

  final int amount;
  final int? amountCompleted;

  @override
  State<AmountProgressInput> createState() => _AmountProgressInputState();
}

class _AmountProgressInputState extends State<AmountProgressInput> {
  late TextEditingController controller;
  late final StateProvider stateProvider = context.read<StateProvider>();
  Timer? _incrementTimer;

  @override
  void initState() {
    super.initState();
    if (widget.amountCompleted != null) {
      controller = TextEditingController(
        text: widget.amountCompleted.toString(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stateProvider.habitAmount = widget.amountCompleted ?? 0;
      });
    } else {
      controller = TextEditingController(text: widget.amount.toString());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stateProvider.habitAmount = widget.amount;
      });
    }
  }

  void onIncrement() {
    setState(() {
      stateProvider.habitAmount++;
      controller.text = stateProvider.habitAmount.toString();
    });
    HapticFeedback.selectionClick();
  }

  void onDecrement() {
    if (stateProvider.habitAmount > 2) {
      setState(() {
        stateProvider.habitAmount--;
        controller.text = stateProvider.habitAmount.toString();
      });
      HapticFeedback.selectionClick();
    }
  }

  void _startIncrementing() {
    _incrementTimer?.cancel();
    _incrementTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      onIncrement();
      HapticFeedback.selectionClick();
    });
  }

  void _stopIncrementing() {
    _incrementTimer?.cancel();
    _incrementTimer = null;
  }

  @override
  void dispose() {
    _stopIncrementing();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return NewDefaultTextField(
      fontWeight: FontWeight.w500,
      title: "Amount",
      digitsOnly: true,
      centerValue: true,
      controller: controller,
      prefix: GestureDetector(
        onTap: () {
          onDecrement();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12.0),
          child: SvgPicture.asset(
            "assets/images/new-svg/minus.svg",
            colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
          ),
        ),
      ),
      suffix: GestureDetector(
        onTap: () {
          onIncrement();
        },
        onLongPressStart: (_) {
          _startIncrementing();
        },
        onLongPressEnd: (_) {
          _stopIncrementing();
        },
        onLongPressCancel: () {
          _stopIncrementing();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12.0),
          child: SvgPicture.asset(
            "assets/images/new-svg/plus.svg",
            colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
