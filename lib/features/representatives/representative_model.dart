class Representative {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String companyId;
  final String? photoUrl;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  Representative({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.companyId,
    this.photoUrl,
    this.address,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Representative.fromMap(Map<String, dynamic> data, String id) {
    return Representative(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      companyId: data['companyId'] ?? '',
      photoUrl: data['photoUrl'],
      address: data['address'],
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'companyId': companyId,
      'photoUrl': photoUrl,
      'address': address,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Representative copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? companyId,
    String? photoUrl,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Representative(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      companyId: companyId ?? this.companyId,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
