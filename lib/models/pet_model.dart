class Pet {
  final String id;
  final String name;
  final String species;
  final int age;
  final String description;
  final String? imageUrl;
  final String status;
  final String? shelterId;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.age,
    required this.description,
    this.imageUrl,
    this.status = 'disponible',
    this.shelterId,
  });

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        id: json['id'],
        name: json['name'] ?? '',
        species: json['species'] ?? '',
        age: json['age'] ?? 0,
        description: json['description'] ?? '',
        imageUrl: json['image_url'],
        status: json['status'] ?? 'disponible',
        shelterId: json['shelter_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'age': age,
        'description': description,
        'image_url': imageUrl,
        'status': status,
        'shelter_id': shelterId,
      };
}