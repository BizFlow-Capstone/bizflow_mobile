/// Employee Entity - Domain model
class EmployeeEntity {
  final String id;
  final String name;

  EmployeeEntity({
    required this.id,
    required this.name,
  });

  EmployeeEntity copyWith({
    String? id,
    String? name,
  }) {
    return EmployeeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
