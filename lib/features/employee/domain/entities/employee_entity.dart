/// Employee Entity - Domain model
class EmployeeEntity {
  final String id;
  final String name;
  final String phone;

  EmployeeEntity({required this.id, required this.name, this.phone = ''});

  EmployeeEntity copyWith({String? id, String? name, String? phone}) {
    return EmployeeEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}
