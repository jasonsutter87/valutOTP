import 'package:uuid/uuid.dart';

enum Algorithm { sha1, sha256, sha512 }

class Account {
  final String id;
  final String name;
  final String? issuer;
  final String secret;
  final String? folderId;
  final int digits;
  final int period;
  final Algorithm algorithm;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    this.issuer,
    required this.secret,
    this.folderId,
    this.digits = 6,
    this.period = 30,
    this.algorithm = Algorithm.sha1,
    required this.createdAt,
  });

  factory Account.create({
    required String name,
    String? issuer,
    required String secret,
    String? folderId,
    int digits = 6,
    int period = 30,
    Algorithm algorithm = Algorithm.sha1,
  }) {
    return Account(
      id: const Uuid().v4(),
      name: name,
      issuer: issuer,
      secret: secret.replaceAll(' ', '').toUpperCase(),
      folderId: folderId,
      digits: digits,
      period: period,
      algorithm: algorithm,
      createdAt: DateTime.now(),
    );
  }

  Account copyWith({
    String? id,
    String? name,
    String? issuer,
    String? secret,
    String? folderId,
    int? digits,
    int? period,
    Algorithm? algorithm,
    DateTime? createdAt,
    bool clearFolderId = false,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      secret: secret ?? this.secret,
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      digits: digits ?? this.digits,
      period: period ?? this.period,
      algorithm: algorithm ?? this.algorithm,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Display name - shows issuer if available, otherwise just name
  String get displayName => issuer != null ? '$issuer ($name)' : name;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuer': issuer,
      'secret': secret,
      'folderId': folderId,
      'digits': digits,
      'period': period,
      'algorithm': algorithm.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      issuer: json['issuer'] as String?,
      secret: json['secret'] as String,
      folderId: json['folderId'] as String?,
      digits: json['digits'] as int? ?? 6,
      period: json['period'] as int? ?? 30,
      algorithm: Algorithm.values.firstWhere(
        (a) => a.name == json['algorithm'],
        orElse: () => Algorithm.sha1,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
