import 'package:uuid/uuid.dart';

class Folder {
  final String id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });

  factory Folder.create({required String name, int sortOrder = 0}) {
    return Folder(
      id: const Uuid().v4(),
      name: name,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
  }

  Folder copyWith({
    String? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Folder && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
