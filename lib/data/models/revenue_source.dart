/// A custom revenue source (name only; schema: custom_sources).
class RevenueSource {
  const RevenueSource({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
      };

  static RevenueSource fromMap(Map<String, Object?> map) {
    return RevenueSource(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}
