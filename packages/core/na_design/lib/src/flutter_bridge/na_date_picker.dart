import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:na_design/src/flutter_bridge/na_multi_option_dialog.dart';
import 'package:na_design/src/primitives/na_dialog_surface.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';
import 'package:na_kernel/na_kernel.dart';

sealed class NaDateChoice {
  const NaDateChoice();
}

final class NaDatePicked extends NaDateChoice {
  const NaDatePicked({required this.date});

  final LocalDate date;
}

final class NaDateCancelled extends NaDateChoice {
  const NaDateCancelled();
}

@immutable
final class NaDateWheelLabels {
  const NaDateWheelLabels({
    required this.day,
    required this.month,
    required this.year,
    required this.monthNames,
  });

  final NaLabel day;
  final NaLabel month;
  final NaLabel year;
  final List<NaLabel> monthNames;
}

Future<NaDateChoice> showNaDatePicker({
  required BuildContext context,
  required LocalDate initial,
  required LocalDate first,
  required LocalDate last,
  required NaDateWheelLabels labels,
  required NaLabel cancelLabel,
  required NaLabel confirmLabel,
}) => showNaDialog<NaDateChoice>(
  context: context,
  barrierLabel: cancelLabel,
  dismissed: const NaDateCancelled(),
  builder: (dialogContext) => NaDatePicker(
    initial: initial,
    first: first,
    last: last,
    labels: labels,
    cancelLabel: cancelLabel,
    confirmLabel: confirmLabel,
    onDone: (choice) => Navigator.of(dialogContext).pop(choice),
  ),
);

enum _Wheel { day, month, year }

enum NaWheelStep { forward, back }

extension type const NaDayNumber(int value) {
  NaWheelIndex get index => NaWheelIndex(value - 1);
}

extension type const NaMonthNumber(int value) {
  NaWheelIndex get index => NaWheelIndex(value - 1);

  NaMonthNumber get next => NaMonthNumber(value % 12 + 1);

  NaMonthNumber get previous => NaMonthNumber((value + 10) % 12 + 1);
}

extension type const NaYearNumber(int value) {}

extension type const NaWheelIndex(int value) {}

final class NaDatePicker extends StatefulWidget {
  const NaDatePicker({
    required this.initial,
    required this.first,
    required this.last,
    required this.labels,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onDone,
    super.key,
  });

  static const double itemExtent = 40;
  static const double wheelHeight = itemExtent * 5;
  static const NaDayNumber longestMonth = NaDayNumber(31);

  final LocalDate initial;
  final LocalDate first;
  final LocalDate last;
  final NaDateWheelLabels labels;
  final NaLabel cancelLabel;
  final NaLabel confirmLabel;
  final ValueChanged<NaDateChoice> onDone;

  @override
  State<NaDatePicker> createState() => _NaDatePickerState();
}

final class _NaDatePickerState extends State<NaDatePicker> {
  late NaDayNumber _day = NaDayNumber(_clamped(date: widget.initial).day);
  late NaMonthNumber _month = NaMonthNumber(
    _clamped(date: widget.initial).month,
  );
  late NaYearNumber _year = NaYearNumber(_clamped(date: widget.initial).year);
  late final FixedExtentScrollController _days = FixedExtentScrollController(
    initialItem: _day.index.value,
  );
  late final FixedExtentScrollController _months = FixedExtentScrollController(
    initialItem: _month.index.value,
  );
  late final FixedExtentScrollController _years = FixedExtentScrollController(
    initialItem: _yearIndex(year: _year).value,
  );

  @override
  void dispose() {
    _days.dispose();
    _months.dispose();
    _years.dispose();
    super.dispose();
  }

  NaWheelIndex _yearIndex({required NaYearNumber year}) =>
      NaWheelIndex(year.value - widget.first.year);

  NaWheelIndex get _lastYearIndex =>
      _yearIndex(year: NaYearNumber(widget.last.year));

  LocalDate get _selected => _clamped(
    date: LocalDate(
      year: _year.value,
      month: _month.value,
      day: _day.value.clamp(
        1,
        _lastDayOf(year: _year, month: _month).value,
      ),
    ),
  );

  LocalDate _clamped({required LocalDate date}) =>
      switch (date.compareTo(other: widget.first)) {
        Comparison.before => widget.first,
        Comparison.same || Comparison.after => switch (date.compareTo(
          other: widget.last,
        )) {
          Comparison.after => widget.last,
          Comparison.before || Comparison.same => date,
        },
      };

  static NaDayNumber _lastDayOf({
    required NaYearNumber year,
    required NaMonthNumber month,
  }) => NaDayNumber(DateTime.utc(year.value, month.value + 1, 0).day);

  NaAvailability _dayAvailability({required NaDayNumber day}) =>
      day.value <= _lastDayOf(year: _year, month: _month).value
      ? _dateAvailability(
          date: LocalDate(
            year: _year.value,
            month: _month.value,
            day: day.value,
          ),
        )
      : NaAvailability.disabled;

  NaAvailability _monthAvailability({required NaMonthNumber month}) => switch ((
    _dateAvailability(
      date: LocalDate(year: _year.value, month: month.value, day: 1),
    ),
    _dateAvailability(
      date: LocalDate(
        year: _year.value,
        month: month.value,
        day: _lastDayOf(year: _year, month: month).value,
      ),
    ),
  )) {
    (NaAvailability.disabled, NaAvailability.disabled) =>
      NaAvailability.disabled,
    (NaAvailability.enabled, NaAvailability()) ||
    (NaAvailability(), NaAvailability.enabled) => NaAvailability.enabled,
  };

  NaAvailability _dateAvailability({required LocalDate date}) => switch ((
    date.compareTo(other: widget.first),
    date.compareTo(other: widget.last),
  )) {
    (Comparison.before, Comparison()) ||
    (Comparison(), Comparison.after) => NaAvailability.disabled,
    (Comparison.same || Comparison.after, Comparison.before) ||
    (
      Comparison.same || Comparison.after,
      Comparison.same,
    ) => NaAvailability.enabled,
  };

  void _settle() {
    final target = _selected;
    _animate(
      controller: _years,
      item: _yearIndex(year: NaYearNumber(target.year)),
    );
    _animate(controller: _months, item: NaMonthNumber(target.month).index);
    _animate(controller: _days, item: NaDayNumber(target.day).index);
  }

  void _animate({
    required FixedExtentScrollController controller,
    required NaWheelIndex item,
  }) {
    if (controller.hasClients && controller.selectedItem != item.value) {
      unawaited(
        controller.animateToItem(
          item.value,
          duration: NaTheme.of(context).motion.fast,
          curve: Curves.easeOut,
        ),
      );
    }
  }

  void _step({required _Wheel wheel, required NaWheelStep step}) {
    final (controller, last) = switch (wheel) {
      _Wheel.day => (_days, NaDatePicker.longestMonth.index),
      _Wheel.month => (_months, const NaMonthNumber(12).index),
      _Wheel.year => (_years, _lastYearIndex),
    };
    final next = switch (step) {
      NaWheelStep.forward => controller.selectedItem + 1,
      NaWheelStep.back => controller.selectedItem - 1,
    };
    controller.jumpToItem(next.clamp(0, last.value));
    _settle();
  }

  NaLabel _dayLabel({required NaDayNumber day}) =>
      NaLabel('${day.value}'.padLeft(2, '0'));

  NaLabel _monthLabel({required NaMonthNumber month}) =>
      widget.labels.monthNames[month.index.value];

  NaLabel _yearLabel({required NaYearNumber year}) => NaLabel('${year.value}');

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final day = NaDayNumber(selected.day);
    final month = NaMonthNumber(selected.month);
    final year = NaYearNumber(selected.year);
    final lastDay = _lastDayOf(year: year, month: month);
    return NaDialogSurface(
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: NotificationListener<ScrollEndNotification>(
            onNotification: (notification) {
              _settle();
              return false;
            },
            child: SizedBox(
              height: NaDatePicker.wheelHeight,
              child: Stack(
                children: [
                  const NaWheelBand(),
                  Row(
                    children: [
                      Expanded(
                        child: NaDateWheel(
                          key: const Key('na-date-wheel-day'),
                          label: widget.labels.day,
                          value: _dayLabel(day: day),
                          increased: _dayLabel(
                            day: NaDayNumber(day.value % lastDay.value + 1),
                          ),
                          decreased: _dayLabel(
                            day: NaDayNumber(
                              (day.value + lastDay.value - 2) % lastDay.value +
                                  1,
                            ),
                          ),
                          controller: _days,
                          items: List.generate(
                            NaDatePicker.longestMonth.value,
                            (index) => NaWheelItem(
                              label: _dayLabel(day: NaDayNumber(index + 1)),
                              availability: _dayAvailability(
                                day: NaDayNumber(index + 1),
                              ),
                            ),
                          ),
                          onSelected: (index) => setState(
                            () => _day = NaDayNumber(index.value + 1),
                          ),
                          onStep: (step) =>
                              _step(wheel: _Wheel.day, step: step),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: NaDateWheel(
                          key: const Key('na-date-wheel-month'),
                          label: widget.labels.month,
                          value: _monthLabel(month: month),
                          increased: _monthLabel(month: month.next),
                          decreased: _monthLabel(month: month.previous),
                          controller: _months,
                          items: List.generate(
                            12,
                            (index) => NaWheelItem(
                              label: _monthLabel(
                                month: NaMonthNumber(index + 1),
                              ),
                              availability: _monthAvailability(
                                month: NaMonthNumber(index + 1),
                              ),
                            ),
                          ),
                          onSelected: (index) => setState(
                            () => _month = NaMonthNumber(index.value + 1),
                          ),
                          onStep: (step) =>
                              _step(wheel: _Wheel.month, step: step),
                        ),
                      ),
                      Expanded(
                        child: NaDateWheel(
                          key: const Key('na-date-wheel-year'),
                          label: widget.labels.year,
                          value: _yearLabel(year: year),
                          increased: _yearLabel(
                            year: NaYearNumber(year.value + 1),
                          ),
                          decreased: _yearLabel(
                            year: NaYearNumber(year.value - 1),
                          ),
                          controller: _years,
                          items: List.generate(
                            _lastYearIndex.value + 1,
                            (index) => NaWheelItem(
                              label: _yearLabel(
                                year: NaYearNumber(widget.first.year + index),
                              ),
                              availability: NaAvailability.enabled,
                            ),
                          ),
                          onSelected: (index) => setState(
                            () => _year = NaYearNumber(
                              widget.first.year + index.value,
                            ),
                          ),
                          onStep: (step) =>
                              _step(wheel: _Wheel.year, step: step),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        NaDialogActions(
          children: [
            NaDialogTextButton(
              key: const Key('na-dialog-cancel'),
              label: widget.cancelLabel,
              availability: NaAvailability.enabled,
              onTap: () => widget.onDone(const NaDateCancelled()),
            ),
            NaDialogTextButton(
              key: const Key('na-dialog-confirm'),
              label: widget.confirmLabel,
              availability: NaAvailability.enabled,
              onTap: () => widget.onDone(NaDatePicked(date: _selected)),
            ),
          ],
        ),
      ],
    );
  }
}

final class NaWheelBand extends StatelessWidget {
  const NaWheelBand({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      height: NaDatePicker.itemExtent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: NaTheme.of(context).colors.background,
          borderRadius: BorderRadius.circular(Radius.button),
        ),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

@immutable
final class NaWheelItem {
  const NaWheelItem({required this.label, required this.availability});

  final NaLabel label;
  final NaAvailability availability;
}

final class NaDateWheel extends StatelessWidget {
  const NaDateWheel({
    required this.label,
    required this.value,
    required this.increased,
    required this.decreased,
    required this.controller,
    required this.items,
    required this.onSelected,
    required this.onStep,
    super.key,
  });

  final NaLabel label;
  final NaLabel value;
  final NaLabel increased;
  final NaLabel decreased;
  final FixedExtentScrollController controller;
  final List<NaWheelItem> items;
  final ValueChanged<NaWheelIndex> onSelected;
  final ValueChanged<NaWheelStep> onStep;

  @override
  Widget build(BuildContext context) {
    final typography = NaTheme.of(context).typography;
    final colors = NaTheme.of(context).colors;
    return Semantics(
      label: label.value,
      value: value.value,
      increasedValue: increased.value,
      decreasedValue: decreased.value,
      onIncrease: () => onStep(NaWheelStep.forward),
      onDecrease: () => onStep(NaWheelStep.back),
      child: ExcludeSemantics(
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: NaDatePicker.itemExtent,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 1.6,
          onSelectedItemChanged: (index) => onSelected(NaWheelIndex(index)),
          childDelegate: ListWheelChildListDelegate(
            children: List.unmodifiable(
              items.map(
                (item) => Center(
                  child: Text(
                    item.label.value,
                    style: switch (item.availability) {
                      NaAvailability.enabled => typography.body.copyWith(
                        color: colors.ink,
                      ),
                      NaAvailability.disabled => typography.body.copyWith(
                        color: colors.inkMuted.withValues(alpha: 0.4),
                      ),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
