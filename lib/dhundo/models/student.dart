class Student {
  final int id;
  final String email;
  final String name;
  final String rollNo;
  final String branch;
  final String phone;

  Student({
    required this.id,
    required this.email,
    required this.name,
    required this.rollNo,
    required this.branch,
    required this.phone,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? 0,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      rollNo: map['rollNo'] ?? '',
      branch: map['branch'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}
