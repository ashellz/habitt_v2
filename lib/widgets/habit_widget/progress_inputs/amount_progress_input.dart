import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/increment_decrement_text_field.dart';
import 'package:provider/provider.dart';

class AmountProgressInput extends StatefulWidget {
  const AmountProgressInput({
    super.key,
    required this.amount,
    this.amountCompleted,
    this.minValue = 0,
  });

  final int amount;
  final int? amountCompleted;
  final int minValue;

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
    return IncrementDecrementTextField(
      fontWeight: FontWeight.w500,
      title: "Amount",
      controller: controller,
      minValue: 2,
      maxValue: 9999,
      onValueChanged: (value) {
        stateProvider.habitAmount = value;
      },
      onDecrement: () {
        onDecrement();
      },
      onIncrement: () {
        onIncrement();
      },
      onIncrementLongPressStart: (_) {
        _startIncrementing();
      },
      onIncrementLongPressEnd: (_) {
        _stopIncrementing();
      },
      onIncrementLongPressCancel: () {
        _stopIncrementing();
      },
    );
  }
}
