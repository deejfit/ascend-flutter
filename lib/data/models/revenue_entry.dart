/// A single revenue entry: amount, source name, optional note, timestamp.
class RevenueEntry {
  const RevenueEntry({
    required this.id,
    required this.amount,
    required this.source,
    this.note,
    required this.timestamp,
  });

  final int id;
  final double amount;
  final String source;
  final String? note;
  /// Epoch milliseconds.
  final int timestamp;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

  Map<String, Object?> toMap() => {
        'id': id,
        'amount': amount,
        'source': source,
        'note': note,
        'timestamp': timestamp,
      };

  static RevenueEntry fromMap(Map<String, Object?> map) {
    return RevenueEntry(
      id: map['id'] as int,
      amount: (map['amount'] as num).toDouble(),
      source: map['source'] as String,
      note: map['note'] as String?,
      timestamp: map['timestamp'] as int,
    );
  }

  RevenueEntry copyWith({
    int? id,
    double? amount,
    String? source,
    String? note,
    int? timestamp,
  }) {
    return RevenueEntry(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
