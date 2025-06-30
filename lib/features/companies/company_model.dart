class Company {
  final String id;
  final String name;
  final String? logoUrl;
  final String? description;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Company.fromMap(Map<String, dynamic> data, String id) {
    return Company(
      id: id,
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'],
      description: data['description'],
      createdAt: data['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'description': description,
      'createdAt': createdAt,
    };
  }
}
