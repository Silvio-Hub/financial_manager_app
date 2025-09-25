import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? profileImageUrl;
  final DateTime? birthDate;
  final String? occupation;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profileImageUrl,
    this.birthDate,
    this.occupation,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  // Construtor para criar um usuário vazio/padrão
  User.empty()
      : id = '',
        email = '',
        name = '',
        phone = null,
        profileImageUrl = null,
        birthDate = null,
        occupation = null,
        bio = null,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  // Converter de Map para User (Firestore)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      profileImageUrl: map['profileImageUrl'],
      birthDate: map['birthDate'] != null 
          ? (map['birthDate'] as Timestamp).toDate()
          : null,
      occupation: map['occupation'],
      bio: map['bio'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Converter de Map para User (JSON/Local Storage)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate'])
          : null,
      occupation: json['occupation'],
      bio: json['bio'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // Converter de User para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'occupation': occupation,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Converter de User para JSON (Local Storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'birthDate': birthDate?.toIso8601String(),
      'occupation': occupation,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Criar uma cópia do usuário com campos atualizados
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImageUrl,
    DateTime? birthDate,
    String? occupation,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      birthDate: birthDate ?? this.birthDate,
      occupation: occupation ?? this.occupation,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Verificar se o usuário está vazio
  bool get isEmpty => id.isEmpty && email.isEmpty && name.isEmpty;

  // Obter iniciais do nome para avatar
  String get initials {
    if (name.isEmpty) return '';
    final names = name.split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    }
    return '${names[0].substring(0, 1)}${names[1].substring(0, 1)}'.toUpperCase();
  }

  // Obter idade baseada na data de nascimento
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}