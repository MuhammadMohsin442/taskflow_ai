class ProjectModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final String startDate;
  final String deadline;

  const ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.startDate,
    required this.deadline,
  });

  ProjectModel copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    String? startDate,
    String? deadline,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
    );
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'Active',
      startDate: map['startDate'] as String? ?? 'Not set',
      deadline: map['deadline'] as String? ?? 'Not set',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'startDate': startDate,
      'deadline': deadline,
    };
  }
}
