import 'package:uuid/uuid.dart';

/// Универсальная задача. Модель намеренно не зависит от Hive и UI,
/// чтобы позже её можно было перенести в единую базу без переписывания.
class Task {
  const Task({
    required this.id,
    required this.subject,
    required this.description,
    required this.deadline,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String subject;
  final String description;
  final DateTime deadline;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;

  /// Свободное место для будущей интеграции (заметки, контакты, вложения).
  final Map<String, dynamic> metadata;

  factory Task.create({
    required String subject,
    required String description,
    required DateTime deadline,
    DateTime? createdAt,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return Task(
      id: const Uuid().v4(),
      subject: subject,
      description: description,
      deadline: deadline,
      createdAt: createdAt ?? DateTime.now(),
      metadata: metadata,
    );
  }

  Task copyWith({
    String? subject,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    Map<String, dynamic>? metadata,
  }) {
    return Task(
      id: id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'subject': subject,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Task.fromMap(Map<dynamic, dynamic> map) {
    final rawMetadata = map['metadata'];
    return Task(
      id: map['id']?.toString() ?? const Uuid().v4(),
      subject: map['subject']?.toString() ?? 'Разное',
      description: map['description']?.toString() ?? '',
      deadline: DateTime.tryParse(map['deadline']?.toString() ?? '') ??
          DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isCompleted: map['isCompleted'] == true,
      completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? ''),
      metadata: rawMetadata is Map
          ? rawMetadata.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value),
            )
          : const <String, dynamic>{},
    );
  }
}
