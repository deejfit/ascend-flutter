import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/revenue_entry.dart';
import '../../../data/repositories/revenue_repository.dart';
import '../../../utils/formatters.dart';
import '../../shared/add_entry_modal.dart';
import '../../shared/spacing.dart';

/// Lijst van alle entries van de geselecteerde maand, chronologisch, met datum en knop om te bewerken.
class MonthEntriesList extends StatelessWidget {
  const MonthEntriesList({
    super.key,
    required this.entries,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onReload,
  });

  final List<RevenueEntry> entries;
  final int selectedYear;
  final int selectedMonth;
  final VoidCallback onReload;

  static final _dateFormat = DateFormat('d MMM yyyy', 'nl_NL');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final sorted = List<RevenueEntry>.from(entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Entries deze maand', style: theme.headlineMedium),
        Spacing.gap16,
        if (sorted.isEmpty)
          Text('Geen entries in deze maand.', style: theme.bodyLarge)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.xs),
            itemBuilder: (context, index) {
              final e = sorted[index];
              final datum = _dateFormat.format(e.date);
              // Amount incl. VAT per entry
              final isFreelance = e.source == 'Freelance';
              final amountIncl = isFreelance ? e.amount * 1.21 : e.amount;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatCurrencyTwoDecimals(amountIncl),
                        style: theme.titleMedium,
                      ),
                    ),
                    Text(e.source, style: theme.bodyMedium),
                  ],
                ),
                subtitle: e.note != null && e.note!.isNotEmpty
                    ? Text('$datum · ${e.note!}', style: theme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : Text(datum, style: theme.bodySmall),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (ctx) => AddEntryModal(
                          selectedYear: selectedYear,
                          selectedMonth: selectedMonth,
                          existingEntry: e,
                          onSaved: onReload,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.bodySmall?.color),
                      onPressed: () async {
                        final bevestig = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Entry verwijderen?'),
                            content: Text(
                              '${formatCurrencyTwoDecimals(e.amount)} – ${e.source}\n\nWeet je zeker dat je dit bedrag wilt verwijderen?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Annuleren'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(ctx).colorScheme.error,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Verwijderen'),
                              ),
                            ],
                          ),
                        );
                        if (bevestig == true) {
                          try {
                            await RevenueRepository.instance.deleteEntry(e.id);
                            if (context.mounted) onReload();
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Verwijderen mislukt')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
