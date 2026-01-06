class AdoptionRequest {
  final String id;
  final String petId;
  final String adopterId;
  final String shelterId;
  final String status;
  final String? message;
  final DateTime createdAt;

  AdoptionRequest({
    required this.id,
    required this.petId,
    required this.adopterId,
    required this.shelterId,
    required this.status,
    this.message,
    required this.createdAt,
  });

  factory AdoptionRequest.fromJson(Map<String, dynamic> json) => AdoptionRequest(
        id: json['id'],
        petId: json['pet_id'],
        adopterId: json['adopter_id'],
        shelterId: json['shelter_id'],
        status: json['status'] ?? 'pendiente',
        message: json['message'],
        createdAt: DateTime.parse(json['created_at']),
      );
}