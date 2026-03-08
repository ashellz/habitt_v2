import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

class AmountProgressInput extends StatefulWidget {
  const AmountProgressInput({
    super.key,
    required this.amount,
    required this.amountCompleted,
  });

  final int amount;
  final int amountCompleted;

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
    controller = TextEditingController(text: widget.amountCompleted.toString());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stateProvider.habitAmount = widget.amountCompleted;
    });
  }

  void onIncrement() {
    setState(() {
      stateProvider.habitAmount++;
      controller.text = stateProvider.habitAmount.toString();
    });
  }

  void onDecrement() {
    if (stateProvider.habitAmount > 0) {
      setState(() {
        stateProvider.habitAmount--;
        controller.text = stateProvider.habitAmount.toString();
      });
    }
  }

  void _startIncrementing() {
    _incrementTimer?.cancel();
    _incrementTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      onIncrement();
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
    return NewDefaultTextField(
      title: "Amount",
      digitsOnly: true,
      centerValue: true,
      controller: controller,
      prefix: GestureDetector(
        onTap: () {
          onDecrement();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SvgPicture.asset("assets/images/new-svg/minus.svg"),
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
          padding: const EdgeInsets.all(16),
          child: SvgPicture.asset("assets/images/new-svg/plus.svg"),
        ),
      ),
    );
  }
}
