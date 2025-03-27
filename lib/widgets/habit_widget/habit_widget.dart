import 'package:flutter/material.dart';
import 'package:habitt/pages/other_pages/icons_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class HabitWidget extends StatelessWidget {
  const HabitWidget({
    super.key,
    required this.name,
    required this.desc,
    required this.amount,
    required this.duration,
    required this.amountCompleted,
    required this.durationCompleted,
    required this.streak,
    required this.completed,
    required this.editable,
    required this.iconPath,
  });

  final String name;
  final String desc;
  final String iconPath;
  final int amount;
  final int duration;
  final int amountCompleted;
  final int durationCompleted;
  final int streak;
  final bool completed;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    // Main container
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      height: 74,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorProvider.habitColor,
      ),
      // Inside of the container
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side
          Row(
            children: [
              // Icon circle container
              InkWell(
                onTap: () {
                  if (editable) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => IconsPage()),
                    );
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorProvider.iconBackgroundColor,
                  ),
                  // Icon
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder:
                        (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                    switchInCurve: Curves.decelerate,
                    switchOutCurve: Curves.decelerate,
                    child: Image.asset(
                      key: ValueKey<String>(iconPath),
                      iconPath,
                    ),
                  ),
                ),
              ),
              // Text
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SizedBox(
                  width:
                      MediaQuery.of(context).size.width -
                      32 - // 32 padding
                      100 - // 100 on the right
                      70, // 70 on the left
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorProvider.textColor,
                        ),
                      ),
                      if (desc.isNotEmpty)
                        Text(
                          desc,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorProvider.mutedTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Completion and streak
          Row(
            children: [
              if (streak > 0)
                StreakDisplay(streak: streak, colorProvider: colorProvider),
              // Completion
              CompletionDisplay(
                colorProvider: colorProvider,
                amount: amount,
                duration: duration,
                amountCompleted: amountCompleted,
                durationCompleted: durationCompleted,
                completed: completed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompletionDisplay extends StatelessWidget {
  const CompletionDisplay({
    super.key,
    required this.colorProvider,
    required this.amount,
    required this.duration,
    required this.amountCompleted,
    required this.durationCompleted,
    required this.completed,
  });

  final ColorProvider colorProvider;
  final int amount;
  final int duration;
  final int amountCompleted;
  final int durationCompleted;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    Widget centerIcon() {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder:
            (child, animation) =>
                FadeTransition(opacity: animation, child: child),
        child: Center(
          key: ValueKey<bool>(completed),
          child: Icon(
            completed ? Icons.check : Icons.close,
            color: colorProvider.backgroundColor,
          ),
        ),
      );
    }

    Widget getCompletionWidget() {
      if (amount > 0) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amountCompleted.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorProvider.backgroundColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(height: 5, thickness: 2),
            ),
            Text(
              amount.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorProvider.backgroundColor,
              ),
            ),
          ],
        );
      } else if (duration > 0) {
        final String durationCopmletedString =
            "${durationCompleted / 60}h${durationCompleted % 60}m";

        final String durationString = "${duration / 60}h${duration % 60}m";

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              durationCopmletedString,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorProvider.backgroundColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Divider(height: 5, thickness: 2),
            ),
            Text(
              durationString,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorProvider.backgroundColor,
              ),
            ),
          ],
        );
      } else {
        return Container(
          clipBehavior: Clip.hardEdge,
          height: 50,
          width: 50,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          child: Stack(
            children: [
              Positioned.fill(
                child: RotatedBox(
                  quarterTurns: -1,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(begin: 0, end: completed ? 1 : 0),
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        color: colorProvider.colorScheme.darkerStandardColor,
                        backgroundColor: colorProvider.colorScheme.strokeColor,
                      );
                    },
                  ),
                ),
              ),
              centerIcon(),
            ],
          ),
        );
      }
    }

    return Container(
      clipBehavior: Clip.hardEdge,
      height: 50,
      width: 50,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          Positioned.fill(
            child: RotatedBox(
              quarterTurns: -1,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                tween: Tween<double>(begin: 0, end: completed ? 1 : 0),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    color: colorProvider.colorScheme.darkerStandardColor,
                    backgroundColor: colorProvider.colorScheme.strokeColor,
                  );
                },
              ),
            ),
          ),
          getCompletionWidget(),
        ],
      ),
    );
  }
}

class StreakDisplay extends StatelessWidget {
  const StreakDisplay({
    super.key,
    required this.streak,
    required this.colorProvider,
  });

  final int streak;
  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 5),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          children: [
            Image.asset("assets/images/icons/streak.png"),
            Center(
              child: Transform.translate(
                offset: Offset(0, 1.5),
                child: FittedBox(
                  child: Text(
                    "$streak",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorProvider.textColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
