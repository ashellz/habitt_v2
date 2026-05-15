import 'dart:async';
import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
import 'package:habitt/util/show_delete_habit_flow.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/habit_details/habit_primary_action_button.dart';
import 'package:habitt/widgets/habit_details/strength_ring.dart';
import 'package:habitt/widgets/habit_details/new/habit_detail_stats_sections.dart';
import 'package:habitt/widgets/stats/consistency_calendar.dart';
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
  HabitProvider? _habitProvider;

  Timer? _notesDebounce;
  String? _pendingNotes;
  bool _isApplyingExternalNotes = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _notesFocusNode = FocusNode();
    _notesController.addListener(_onNotesChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<StateProvider>();
      final habitProvider = context.read<HabitProvider>();
      if (sp.shouldUpdateStreaks) {
        habitProvider.assignStreaks(widget.habitId);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _habitProvider ??= context.read<HabitProvider>();
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

    // Keep a copy of the latest text so we can persist it immediately
    // for example on dispose without relying on the debounce timer.
    _pendingNotes = _notesController.text;

    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 500), () {
      _persistNotesIfNeeded();
    });
  }

  void _persistNotesIfNeeded({bool allowWhenUnmounted = false}) {
    if (!allowWhenUnmounted && !mounted) {
      return;
    }

    final habitProvider = _habitProvider;
    if (habitProvider == null) {
      return;
    }

    final habit = _findHabit(habitProvider);
    if (habit == null) {
      return;
    }

    // Prefer the pending notes buffer if present — this captures the
    // very latest edit even if the debounce timer didn't fire yet.
    final newNotes = _pendingNotes ?? _notesController.text;
    _pendingNotes = null;
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
      barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (context) => HabitSheet(habit: habit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final habit = _findHabit(habitProvider);
    final loc = AppLocalizations.of(context)!;

    if (habit == null) {
      return Scaffold(
        backgroundColor: cp.habitBg,
        body: Center(
          child: Text(
            loc.habitNotFound,
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

    final stats = context.watch<HabitStatsProvider>().statsForHabit(
      habit,
      locale: Localizations.localeOf(context),
    );

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
              color: cp.habitBg,
              child: Column(
                children: [
                  _topBar(cp, habit),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        _summaryCard(cp, habit, stats),
                        const SizedBox(height: 18),
                        _notesSection(cp),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
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
                  ConsistencyCalendar(habitStats: stats),
                  const SizedBox(height: 24),
                  NewDefaultButton(
                    height: 40,
                    color: cp.fail,
                    onPressed: () => showDeleteHabitFlow(habit, context),
                    child: Text(loc.deleteHabit),
                  ),
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
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.only(left: 16),
              color: Colors.transparent,
              height: 36,
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  "assets/images/new-svg/back.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                loc.habitDetails,
                style: TextStyle(
                  color: cp.text,
                  fontSize: 34 / 1.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: NewCircleButton(
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
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(ColorProvider cp, Habit habit, HabitStatsData stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: cp.isDark ? cp.field : cp.bg,
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
                HabitPrimaryActionButton(habit: habit),
              ],
            ),
          ),
          StrengthRing(strength: stats.currentStrength),
        ],
      ),
    );
  }

  Widget _summaryMeta(ColorProvider cp, Habit habit) {
    final hasAmount = habit.tracksAmount;
    final hasDuration = habit.tracksDuration;

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
            style: TextStyle(color: cp.lightGreyText, fontSize: 13),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }

  String _amountLine(Habit habit) {
    final baseLabel =
        habit.amountLabel.trim().isEmpty
            ? AmountLabelPreset.times.plural
            : habit.amountLabel;
    final loc = AppLocalizations.of(context)!;
    final label = resolveAmountLabelForValue(
      baseLabel,
      habit.completed
          ? habit.amountCompleted
          : habit.amountCompleted > 0
          ? habit.amount
          : habit.amount,
      loc,
    );
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
    final loc = AppLocalizations.of(context)!;

    return NewDefaultTextField(
      title: loc.notes,
      color: cp.isDark ? cp.field : cp.bg,
      titleFontSize: 16,
      focusNode: _notesFocusNode,
      controller: _notesController,
      minLines: 3,
      maxLines: 5,
    );
  }
}

