import 'package:equatable/equatable.dart';

/// Entidad que representa una sesión de chat
class ChatSession extends Equatable {
  /// Identificador único de la sesión
  final String id;
  
  /// ID del usuario propietario de la sesión
  final String userId;
  
  /// Título de la conversación
  final String title;
  
  /// Fecha de creación de la sesión
  final DateTime createdAt;
  
  /// Fecha de última actualización
  final DateTime updatedAt;
  
  /// Indica si la sesión está activa
  final bool isActive;

  const ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  /// Crea una copia de la sesión con algunos campos modificados
  ChatSession copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convierte la entidad a un mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Crea una entidad desde un mapa (deserialización)
  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? 'Nueva conversación',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isActive: map['is_active'] ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        createdAt,
        updatedAt,
        isActive,
      ];

  @override
  String toString() {
    return 'ChatSession(id: $id, userId: $userId, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive)';
  }
}