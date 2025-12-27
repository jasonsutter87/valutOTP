import 'package:uuid/uuid.dart';

class Folder {
  final String id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;
  final String? parentId; // null = root folder

  Folder({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    this.parentId,
  });

  bool get isRoot => parentId == null;
  bool get isSubfolder => parentId != null;

  factory Folder.create({
    required String name,
    int sortOrder = 0,
    String? parentId,
  }) {
    return Folder(
      id: const Uuid().v4(),
      name: name,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      parentId: parentId,
    );
  }

  Folder copyWith({
    String? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
    String? parentId,
    bool clearParentId = false,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      parentId: json['parentId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Folder && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
