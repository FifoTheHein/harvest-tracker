class HarvestTask {
  final int id;
  final String name;

  const HarvestTask({required this.id, required this.name});

  factory HarvestTask.fromJson(Map<String, dynamic> json) => HarvestTask(
        id: json['id'] as int,
        name: json['name'] as String,
      );

  @override
  bool operator ==(Object other) => other is HarvestTask && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class HarvestProject {
  final int id;
  final String name;
  final String code;
  final List<HarvestTask> tasks;
  final String? clientName;

  const HarvestProject({
    required this.id,
    required this.name,
    required this.code,
    required this.tasks,
    this.clientName,
  });

  factory HarvestProject.fromAssignment(Map<String, dynamic> assignment) {
    final project = assignment['project'] as Map<String, dynamic>;
    final client = assignment['client'] as Map<String, dynamic>?;
    final taskAssignments =
        (assignment['task_assignments'] as List<dynamic>? ?? []);
    return HarvestProject(
      id: project['id'] as int,
      name: project['name'] as String,
      code: (project['code'] as String?) ?? '',
      tasks: taskAssignments
          .map((ta) =>
              HarvestTask.fromJson(ta['task'] as Map<String, dynamic>))
          .toList(),
      clientName: client?['name'] as String?,
    );
  }

  @override
  bool operator ==(Object other) => other is HarvestProject && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
