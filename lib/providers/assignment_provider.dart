import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_assignment.dart';
import '../services/harvest_service.dart';

class AssignmentProvider extends ChangeNotifier {
  final HarvestService _service;

  AssignmentProvider(this._service);

  List<HarvestProject> projects = [];
  bool isLoading = false;
  String? error;

  HarvestProject? selectedProject;
  HarvestTask? selectedTask;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      projects = await _service.fetchProjectAssignments();
      if (projects.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final defaultId = prefs.getInt('default_project_id');
        final defaultProject = defaultId != null
            ? projects.firstWhere((p) => p.id == defaultId,
                orElse: () => projects.first)
            : projects.first;
        selectedProject = defaultProject;
        final defaultTaskId = prefs.getInt('default_task_id');
        selectedTask = defaultTaskId != null
            ? defaultProject.tasks.firstWhere((t) => t.id == defaultTaskId,
                orElse: () => defaultProject.tasks.isNotEmpty
                    ? defaultProject.tasks.first
                    : defaultProject.tasks.first)
            : defaultProject.tasks.isNotEmpty
                ? defaultProject.tasks.first
                : null;
      }
    } on HarvestApiException catch (e) {
      error = '${e.statusCode}: ${e.message}';
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectProject(HarvestProject project) {
    selectedProject = project;
    selectedTask =
        project.tasks.isNotEmpty ? project.tasks.first : null;
    notifyListeners();
  }

  void selectTask(HarvestTask task) {
    selectedTask = task;
    notifyListeners();
  }
}
