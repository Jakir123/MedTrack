class Medicine {
  final String id;
  final String name;
  final String companyId;
  final String? companyName;
  final String? representativeId;
  final String? representativeName;
  final int? quantityInStock;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.companyId,
    this.companyName,
    this.representativeId,
    this.representativeName,
    this.quantityInStock,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Medicine.fromMap(Map<String, dynamic> data, String id) {
    return Medicine(
      id: id,
      name: data['name'] ?? '',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'],
      representativeId: data['representativeId'],
      representativeName: data['representativeName'],
      quantityInStock: data['quantityInStock']?.toInt(),
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    final data = {
      'name': name,
      'companyId': companyId,
      'companyName': companyName,
      'representativeId': representativeId,
      'representativeName': representativeName,
      'quantityInStock': quantityInStock,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
    
    // Remove null values to avoid Firestore errors
    data.removeWhere((key, value) => value == null);
    return data;
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? companyId,
    String? companyName,
    String? representativeId,
    String? representativeName,
    int? quantityInStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      representativeId: representativeId ?? this.representativeId,
      representativeName: representativeName ?? this.representativeName,
      quantityInStock: quantityInStock ?? this.quantityInStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
