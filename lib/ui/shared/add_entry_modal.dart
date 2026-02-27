import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/revenue_entry.dart';
import '../../data/repositories/revenue_repository.dart';
import '../../data/repositories/source_repository.dart';
import '../../utils/dates.dart';

/// Modal to add or edit a revenue entry. Amount, source, month/year/day, optional note.
/// Default month/year = dashboard's selected month. Pass [existingEntry] to edit.
class AddEntryModal extends StatefulWidget {
  const AddEntryModal({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onSaved,
    this.existingEntry,
  });

  final int selectedYear;
  final int selectedMonth;
  final VoidCallback? onSaved;
  /// When set, modal is in edit mode: prefilled and calls updateEntry.
  final RevenueEntry? existingEntry;

  @override
  State<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends State<AddEntryModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _amountError;
  List<String> _sourceNames = [];
  String? _selectedSource;
  late int _selectedYear;
  late int _selectedMonth;
  int _selectedDay = 1;
  bool _loadingSources = true;
  bool _saving = false;

  int get _daysInMonth => daysInMonth(_selectedYear, _selectedMonth);

  bool get _isEdit => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEntry;
    if (existing != null) {
      _selectedYear = existing.date.year;
      _selectedMonth = existing.date.month;
      _selectedDay = existing.date.day.clamp(1, daysInMonth(_selectedYear, _selectedMonth));
      _amountController.text = existing.amount.toString().replaceFirst('.', ',');
      _noteController.text = existing.note ?? '';
      _selectedSource = existing.source;
    } else {
      _selectedYear = widget.selectedYear;
      _selectedMonth = widget.selectedMonth;
      final now = DateTime.now();
      final isCurrentMonth =
          _selectedYear == now.year && _selectedMonth == now.month;
      _selectedDay = isCurrentMonth
          ? now.day.clamp(1, _daysInMonth)
          : 1;
    }
    _loadSources();
  }

  void _onMonthOrYearChanged() {
    _selectedDay = _selectedDay.clamp(1, _daysInMonth);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSources() async {
    setState(() => _loadingSources = true);
    try {
      final list = await SourceRepository.instance.listSources();
      if (mounted) {
        setState(() {
          _sourceNames = list.map((s) => s.name).toList();
          if (!_isEdit) _selectedSource ??= _sourceNames.isNotEmpty ? _sourceNames.first : null;
          _loadingSources = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSources = false);
    }
  }

  Future<void> _addNewSource() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New source'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Client X',
            ),
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim().isEmpty ? null : v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final v = controller.text.trim();
                Navigator.of(ctx).pop(v.isEmpty ? null : v);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    try {
      await SourceRepository.instance.addSource(name);
      await _loadSources();
      if (mounted) setState(() => _selectedSource = name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add source: $name')),
        );
      }
    }
  }

  Future<void> _save() async {
    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      setState(() => _amountError = 'Amount is required');
      return;
    }
    final amount = double.tryParse(amountStr.replaceFirst(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Amount must be greater than 0');
      return;
    }
    if (_selectedSource == null || _selectedSource!.isEmpty) {
      setState(() => _amountError = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source')),
      );
      return;
    }
    setState(() {
      _amountError = null;
      _saving = true;
    });
    try {
      final timestamp = DateTime(
        _selectedYear,
        _selectedMonth,
        _selectedDay,
        12,
        0,
        0,
      ).millisecondsSinceEpoch;
      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
      if (_isEdit) {
        final entry = RevenueEntry(
          id: widget.existingEntry!.id,
          amount: amount,
          source: _selectedSource!,
          note: note,
          timestamp: timestamp,
        );
        await RevenueRepository.instance.updateEntry(entry);
      } else {
        final entry = RevenueEntry(
          id: 0,
          amount: amount,
          source: _selectedSource!,
          note: note,
          timestamp: timestamp,
        );
        await RevenueRepository.instance.addEntry(entry);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit revenue' : 'Add revenue'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '€ 0.00',
                  prefixText: '€ ',
                  errorText: _amountError,
                ),
                onChanged: (_) => setState(() => _amountError = null),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSource,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                      ),
                      items: _sourceNames
                          .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                          .toList(),
                      onChanged: _loadingSources
                          ? null
                          : (v) => setState(() => _selectedSource = v),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _loadingSources ? null : _addNewSource,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add new source'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                      ),
                      items: List.generate(
                        5,
                        (i) {
                          final y = DateTime.now().year - 2 + i;
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        },
                      ),
                      onChanged: (v) => setState(() {
                        _selectedYear = v ?? _selectedYear;
                        _onMonthOrYearChanged();
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                      ),
                      items: List.generate(
                        12,
                        (i) {
                          final m = i + 1;
                          return DropdownMenuItem<int>(
                            value: m,
                            child: Text(formatMonthLabel(_selectedYear, m)),
                          );
                        },
                      ),
                      onChanged: (v) => setState(() {
                        _selectedMonth = v ?? _selectedMonth;
                        _onMonthOrYearChanged();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedDay.clamp(1, _daysInMonth),
                decoration: const InputDecoration(
                  labelText: 'Day of month',
                ),
                items: List.generate(
                  _daysInMonth,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                ),
                onChanged: (v) => setState(() => _selectedDay = v ?? 1),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Optional note',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
