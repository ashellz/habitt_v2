import 'dart:async';
import 'dart:math' as math;

import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:habitt/widgets/habit_details/new/habit_detail_stats_sections.dart';
import 'package:habitt/widgets/habit_details/new/habit_details_calendar.dart';
import 'package:habitt/widgets/habit_widget/new_habit_icon.dart';
import 'package:habitt/widgets/sheets/habit_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class HabitDetailsPage extends StatefulWidget {
  const HabitDetailsPage({super.key, required this.habitId});

  final int habitId;

  @override
  State<HabitDetailsPage> createState() => _HabitDetailsPageState();
}

class _HabitDetailsPageState extends State<HabitDetailsPage> {
  late final TextEditingController _notesController;
  late final FocusNode _notesFocusNode;

  Timer? _notesDebounce;
  bool _isApplyingExternalNotes = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _notesFocusNode = FocusNode();
    _notesController.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    _persistNotesIfNeeded(allowWhenUnmounted: true);

    _notesController.removeListener(_onNotesChanged);
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    if (_isApplyingExternalNotes) {
      return;
    }

    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 500), () {
      _persistNotesIfNeeded();
    });
  }

  void _persistNotesIfNeeded({bool allowWhenUnmounted = false}) {
    if (!allowWhenUnmounted && !mounted) {
      return;
    }

    final habitProvider = context.read<HabitProvider>();
    final habit = _findHabit(habitProvider);
    if (habit == null) {
      return;
    }

    final newNotes = _notesController.text;
    if (newNotes == habit.description) {
      return;
    }

    final updated = habit.copy()..description = newNotes;
    habitProvider.updateHabit(updated);
  }

  Habit? _findHabit(HabitProvider provider) {
    for (final habit in provider.habits) {
      if (habit.id == widget.habitId) {
        return habit;
      }
    }
    return null;
  }

  void _syncNotesFromHabit(Habit habit) {
    if (_notesFocusNode.hasFocus) {
      return;
    }

    final text = habit.description;
    if (_notesController.text == text) {
      return;
    }

    _isApplyingExternalNotes = true;
    _notesController.text = text;
    _notesController.selection = TextSelection.collapsed(offset: text.length);
    _isApplyingExternalNotes = false;
  }

  Future<void> _openEditSheet(Habit habit) async {
    final cp = context.read<ColorProvider>();

    await showModalBottomSheet(
      context: context,
      backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
      barrierColor: cp.greyText.darken().withOpacity(0.3),
      isScrollControlled: true,
      builder: (context) => HabitSheet(habit: habit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final habit = _findHabit(habitProvider);

    if (habit == null) {
      return Scaffold(
        backgroundColor: cp.habitBg,
        body: Center(
          child: Text(
            'Habit not found',
            style: TextStyle(
              color: cp.text,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    _syncNotesFromHabit(habit);

    final stats = context.watch<HabitStatsProvider>().statsForHabit(habit);

    return Scaffold(
      backgroundColor: cp.habitBg,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            0,
            MediaQuery.of(context).padding.top,
            0,
            0,
          ),
          physics: const ClampingScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: cp.habitBg,
              child: Column(
                children: [
                  _topBar(cp, habit),
                  const SizedBox(height: 14),
                  _summaryCard(cp, habit),
                  const SizedBox(height: 18),
                  _notesSection(cp),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Container(
              color: cp.bg,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(height: 24),
                  HabitDetailStatsSections(habit: habit, stats: stats),
                  SizedBox(height: 24),
                  HabitDetailsCalendar(stats: stats),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(ColorProvider cp, Habit habit) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/new-svg/back.svg',
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Habit details',
                style: TextStyle(
                  color: cp.text,
                  fontSize: 34 / 1.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          NewCircleButton(
            svgPath: 'assets/images/new-svg/edit.svg',
            cnIcon: CNSymbol('pencil.line', size: 14),
            width: 44,
            height: 44,
            color: cp.bg,
            padding: const EdgeInsets.all(13),
            onPressed: () async {
              await _openEditSheet(habit);
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(ColorProvider cp, Habit habit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: cp.field,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: cp.border),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 16,
                  children: [
                    NewHabitIcon(
                      forceColor: cp.border,
                      iconPath: habit.iconPath,
                      isCompleted: habit.completed,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            color: cp.text,
                            fontSize: 19 / 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _summaryMeta(cp, habit),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _HabitPrimaryActionButton(habit: habit),
              ],
            ),
          ),
          _StrengthRing(),
        ],
      ),
    );
  }

  Widget _summaryMeta(ColorProvider cp, Habit habit) {
    final hasAmount = habit.amount > 0;
    final hasDuration = habit.duration > 0;

    if (hasAmount || hasDuration) {
      return Row(
        children: [
          hasAmount
              ? Icon(Icons.repeat, size: 14, color: cp.lightGreyText)
              : SvgPicture.asset(
                'assets/images/new-svg/clock.svg',
                width: 14,
                height: 14,
              ),
          const SizedBox(width: 6),
          Text(
            hasAmount ? _amountLine(habit) : _durationLine(habit),
            style: TextStyle(
              color: cp.lightGreyText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (habit.description.trim().isEmpty) {
      return Text(
        'No notes yet',
        style: TextStyle(
          color: cp.lightGreyText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      habit.description,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: cp.lightGreyText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _amountLine(Habit habit) {
    final label =
        habit.amountLabel.trim().isEmpty ? 'times' : habit.amountLabel;
    if (habit.completed) {
      return '${habit.amountCompleted} $label';
    }
    if (habit.amountCompleted > 0) {
      return '${habit.amountCompleted} / ${habit.amount} $label';
    }
    return '${habit.amount} $label';
  }

  String _durationLine(Habit habit) {
    if (habit.completed) {
      return getDurationString(habit.durationCompleted);
    }
    if (habit.durationCompleted > 0) {
      return '${getDurationString(habit.durationCompleted)} / ${getDurationString(habit.duration)}';
    }
    return getDurationString(habit.duration);
  }

  Widget _notesSection(ColorProvider cp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: TextStyle(color: cp.lightGreyText, fontSize: 16)),
        const SizedBox(height: 8),
        NewDefaultTextField(
          focusNode: _notesFocusNode,
          controller: _notesController,
          minLines: 3,
          maxLines: 5,
          showBorder: true,
          textStyle: TextStyle(
            color: cp.text,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StrengthRing extends StatelessWidget {
  const _StrengthRing();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 78,
            height: 82,
            child: CircularProgressIndicator(
              value: 0.79,
              strokeWidth: 6,
              backgroundColor: cp.border,
              valueColor: AlwaysStoppedAnimation<Color>(cp.text),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '79%',
                style: TextStyle(
                  color: cp.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Strength',
                style: TextStyle(color: cp.lightGreyText, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HabitPrimaryActionButton extends StatefulWidget {
  const _HabitPrimaryActionButton({required this.habit});

  final Habit habit;

  @override
  State<_HabitPrimaryActionButton> createState() =>
      _HabitPrimaryActionButtonState();
}

class _HabitPrimaryActionButtonState extends State<_HabitPrimaryActionButton> {
  double _progressValue() {
    if (widget.habit.completed || widget.habit.skipped) {
      return 1;
    }

    if (widget.habit.amount > 0) {
      return (widget.habit.amountCompleted / widget.habit.amount).clamp(
        0.0,
        1.0,
      );
    }

    if (widget.habit.duration > 0) {
      return (widget.habit.durationCompleted / widget.habit.duration).clamp(
        0.0,
        1.0,
      );
    }

    return 0;
  }

  String _label() {
    debugPrint('Completed: ${widget.habit.completed}');
    if (widget.habit.completed) {
      return 'Completed';
    }
    if (widget.habit.amount > 0 || widget.habit.duration > 0) {
      return 'Log progress';
    }
    return 'Mark as complete';
  }

  Future<void> _onMainTap() async {
    final habitProvider = context.read<HabitProvider>();
    final stateProvider = context.read<StateProvider>();
    final dayOverride = DateTime.now();

    if (widget.habit.amount == 0 && widget.habit.duration == 0) {
      habitProvider.completeHabit(
        widget.habit.id,
        context,
        stateProvider,
        dayOverride: dayOverride,
      );
      return;
    }

    await showDialogSheet(
      context: context,
      builder: (context) {
        return LogProgressDialog(
          progressType:
              widget.habit.amount > 0
                  ? ProgressType.amount
                  : ProgressType.duration,
          habit: widget.habit,
          dayOverride: dayOverride,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return GestureDetector(
      onTap: _onMainTap,

      onLongPress: () {
        final habitProvider = context.read<HabitProvider>();
        final stateProvider = context.read<StateProvider>();
        habitProvider.completeHabit(
          widget.habit.id,
          context,
          stateProvider,
          dayOverride: DateTime.now(),
        );
      },
      child: NewDefaultButton(
        color: widget.habit.completed ? cp.habitBg : cp.main,
        height: 41,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        onPressed: () => _onMainTap(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IgnorePointer(
              child: _ActionProgressIcon(
                progress: _progressValue(),
                completed: widget.habit.completed,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _label(),
              style: TextStyle(
                color: widget.habit.completed ? cp.lightGreyText : cp.bg,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionProgressIcon extends StatelessWidget {
  const _ActionProgressIcon({required this.progress, required this.completed});

  final double progress;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    if (progress > 0 && progress < 1) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(
          painter: _MiniCircularProgressPainter(
            progress: progress,
            color: cp.bg,
          ),
        ),
      );
    }

    final svgPath =
        'assets/images/new-svg/check-${completed ? 'off' : 'on'}-inverted-${cp.isDark ? 'dark' : 'light'}.svg';

    return SvgPicture.asset(svgPath, width: 18, height: 18);
  }
}

class _MiniCircularProgressPainter extends CustomPainter {
  const _MiniCircularProgressPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final progressPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = color;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      true,
      progressPaint,
    );

    final borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color.withValues(alpha: 0.4);

    canvas.drawCircle(center, radius - 1, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
