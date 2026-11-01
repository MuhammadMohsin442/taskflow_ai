class TaskModel {
  final int id;
  final String title;
  final String description;
  final int? projectId;
  final String projectName;
  final String dueDate;
  final String priority;
  final bool isCompleted;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.projectId,
    required this.projectName,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
  });

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    int? projectId,
    String? projectName,
    String? dueDate,
    String? priority,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      projectId: (map['projectId'] as num?)?.toInt(),
      projectName: map['projectName'] as String? ?? '',
      dueDate: map['dueDate'] as String? ?? '',
      priority: map['priority'] as String? ?? 'Medium',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'projectId': projectId,
      'projectName': projectName,
      'dueDate': dueDate,
      'priority': priority,
      'isCompleted': isCompleted,
    };
  }
}
