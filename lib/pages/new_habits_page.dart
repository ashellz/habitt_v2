import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';

class NewHabitsPage extends StatelessWidget {
  const NewHabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: cp.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [HabitsPageTopSection()]),
        ),
      ),
    );
  }
}

class HabitsPageTopSection extends StatelessWidget {
  const HabitsPageTopSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text("Good morning,"), Text("Shellz")],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
