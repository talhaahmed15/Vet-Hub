class Client {
  final String id;
  final String fullName;
  final String? phone;

  const Client({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      phone: map['phone']?.toString(),
    );
  }
}
