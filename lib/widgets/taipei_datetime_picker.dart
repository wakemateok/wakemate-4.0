import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/utils/review_text.dart';

Future<DateTime?> showTaipeiDateTimePicker(
  BuildContext context, {
  required DateTime initial,
}) {
  FocusScope.of(context).unfocus();
  var selected = DateTime(
    initial.year.clamp(2020, 2100),
    initial.month,
    initial.day,
    initial.hour,
    initial.minute,
  );
  var timeMode = true;
  final language = Localizations.localeOf(context).languageCode;
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<DateTime>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder:
        (sheetContext) => StatefulBuilder(
          builder:
              (context, update) => SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.chooseDateTime,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('yyyy/MM/dd HH:mm').format(selected),
                          key: const ValueKey('picker-selection'),
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(reviewText('date', language)),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.schedule),
                              label: Text(reviewText('timeTab', language)),
                            ),
                          ],
                          selected: {timeMode},
                          onSelectionChanged:
                              (values) =>
                                  update(() => timeMode = values.single),
                        ),
                        const SizedBox(height: 12),
                        Text(reviewText('time', language)),
                        SizedBox(
                          height: 216,
                          child: MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(textScaler: TextScaler.noScaling),
                            child: CupertinoDatePicker(
                              key: ValueKey(timeMode),
                              mode:
                                  timeMode
                                      ? CupertinoDatePickerMode.time
                                      : CupertinoDatePickerMode.date,
                              initialDateTime: selected,
                              minimumYear: 2020,
                              maximumYear: 2100,
                              use24hFormat: true,
                              onDateTimeChanged:
                                  (value) => update(() {
                                    selected =
                                        timeMode
                                            ? DateTime(
                                              selected.year,
                                              selected.month,
                                              selected.day,
                                              value.hour,
                                              value.minute,
                                            )
                                            : DateTime(
                                              value.year,
                                              value.month,
                                              value.day,
                                              selected.hour,
                                              selected.minute,
                                            );
                                  }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton.icon(
                              key: const ValueKey('picker-done'),
                              onPressed:
                                  () => Navigator.pop(sheetContext, selected),
                              icon: const Icon(Icons.check),
                              label: Text(reviewText('done', language)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ),
  );
}
