import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/habits/new_habits.dart';
import 'package:habitt/widgets/main_page/main_page_top_section.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final ConfettiController _confettiController;
  bool _wasAllCompleted = false;
  bool _initializedCompletionState = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const bottomNavBar = 86;

    final habits = context.watch<HabitProvider>().todaysHabits;

    final bool allCompleted =
        habits.isNotEmpty && habits.every((habit) => habit.completed);
    if (!_initializedCompletionState) {
      _wasAllCompleted = allCompleted;
      _initializedCompletionState = true;
    } else {
      if (allCompleted && !_wasAllCompleted) {
        _confettiController.play();
      } else if (!allCompleted && _wasAllCompleted) {
        _confettiController.stop();
      }
      _wasAllCompleted = allCompleted;
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 2, child: Container(color: cp.bg)),
              Expanded(child: Container(color: cp.habitBg)),
            ],
          ),
          ListView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            physics: const ClampingScrollPhysics(),
            children: [
              MainPageTopSection(),
              SizedBox(height: 20),
              Container(
                color: cp.habitBg,
                child: Column(
                  children: [
                    NewCategoriesList(),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: NewHabits(),
                    ),
                    SizedBox(height: bottomPadding + bottomNavBar),
                  ],
                ),
              ),
            ],
          ),

          // Confetti celebration when all habits are completed
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                minimumSize: const Size(10, 5),
                maximumSize: const Size(20, 10),
                emissionFrequency: 0.08,
                numberOfParticles: 24,
                maxBlastForce: 20,
                minBlastForce: 5,
                gravity: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
