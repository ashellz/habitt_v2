import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/pages/other_pages/edit_habit_page.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/default_button.dart';
import 'package:habitt/widgets/default_dialog.dart';
import 'package:provider/provider.dart';

class DeleteHabitDialog extends StatelessWidget {
  const DeleteHabitDialog({super.key, required this.widget});

  final EditHabitPage widget;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return DefaultDialog(
      danger: true,
      title: "Delete '${widget.habit.name}'?",
      desc: "Are you sure you want to delete this habit?",
      leftButtonOutlined: true,
      leftButtonText: localizations.cancel,
      rightButtonText: "Delete",
      rightButtonCallback: () {
        context.read<HabitProvider>().removeHabit(widget.habit);
        Navigator.pop(context);
        Navigator.pop(context);
        Future.delayed(Duration(milliseconds: 150)).then((value) {
          if (!context.mounted) {
            debugPrint("context not mounted");
            return;
          }
          showGeneralDialog(
            context: context,
            pageBuilder: (context, animation, secondaryAnimation) {
              return const SizedBox.shrink(); // Content handled by transitionBuilder
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: DefaultDialog(
                        title: "Success!",
                        desc: "Habit has been deleted successfully.",
                        content: DefaultButton(
                          onPressed: () => Navigator.pop(context),
                          label: "Close",
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fade(
                    begin: 0.0,
                    end: 1.0,
                    curve: Curves.easeOut,
                    duration: 300.ms,
                  )
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.easeOutBack,
                    duration: 300.ms,
                  );
            },
            transitionDuration: const Duration(milliseconds: 300),
            barrierDismissible: true,
            barrierLabel:
                MaterialLocalizations.of(context).modalBarrierDismissLabel,
            barrierColor: Colors.black54,
          );
        });
      },
    );
  }
}
