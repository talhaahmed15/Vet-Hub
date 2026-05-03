class Pet {
  final String id;
  final String clientId;
  final String name;
  final String species;
  final String breed;

  const Pet({
    required this.id,
    required this.clientId,
    required this.name,
    required this.species,
    required this.breed,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      species: map['species']?.toString() ?? '',
      breed: map['breed']?.toString() ?? '',
    );
  }
}
