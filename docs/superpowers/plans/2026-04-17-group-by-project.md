# Group by Project Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a session-only "Group by project" FilterChip to the Recent Entries screen that groups today's entries by project ID under redesigned headers showing a colour dot, project name, client name, entry count, and total hours.

**Architecture:** Four small model additions (two nullable fields) plus a full rewrite of the grouping widget in `recent_entries_screen.dart`. The `_ProjectGroupHeader` is replaced with a dot-based design; the `_buildGroupedList` method is rewritten using `groupBy` from `package:collection`. SharedPreferences persistence for the toggle is removed entirely.

**Tech Stack:** Flutter/Dart, `package:collection` (groupBy, firstWhereOrNull), `HarvestTokens` colour tokens.

---

## File Map

| File | Change |
|---|---|
| `pubspec.yaml` | Add `collection: ^1.18.0` |
| `lib/models/time_entry.dart` | Add `createdAt` (String?) |
| `lib/models/project_assignment.dart` | Add `clientName` (String?) to `HarvestProject` |
| `lib/screens/recent_entries_screen.dart` | Remove SharedPreferences toggle, replace IconButton with FilterChip, rewrite `_buildGroupedList` + `_ProjectGroupHeader`, sort flat list by `createdAt` |

---

## Task 1: Add `collection` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, add `collection` under `dependencies` (after `web:`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  collection: ^1.18.0
  http: ^1.2.1
  intl: ^0.19.0
  provider: ^6.1.2
  shared_preferences: ^2.3.2
  web: ^1.1.0
```

- [ ] **Step 2: Fetch packages**

```bash
flutter pub get
```

Expected: resolves without error, `collection` appears in `.dart_tool/package_config.json`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add collection dependency"
```

---

## Task 2: Add `createdAt` to `TimeEntry`

**Files:**
- Modify: `lib/models/time_entry.dart`

- [ ] **Step 1: Add the field and update the constructor**

Replace the `TimeEntry` class (lines 67–115) with:

```dart
class TimeEntry {
  final int id;
  final String spentDate;
  final double hours;
  final String? notes;
  final int projectId;
  final String projectName;
  final int taskId;
  final String taskName;
  final String? userName;
  final ExternalReference? externalReference;
  final String? createdAt;

  const TimeEntry({
    required this.id,
    required this.spentDate,
    required this.hours,
    this.notes,
    required this.projectId,
    required this.projectName,
    required this.taskId,
    required this.taskName,
    this.userName,
    this.externalReference,
    this.createdAt,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    final ext = json['external_reference'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    final project = json['project'] as Map<String, dynamic>;
    final task = json['task'] as Map<String, dynamic>;
    return TimeEntry(
      id: json['id'] as int,
      spentDate: json['spent_date'] as String,
      hours: (json['hours'] as num).toDouble(),
      notes: json['notes'] as String?,
      projectId: project['id'] as int,
      projectName: project['name'] as String,
      taskId: task['id'] as int,
      taskName: task['name'] as String,
      userName: user?['name'] as String?,
      externalReference: ext == null
          ? null
          : ExternalReference(
              id: ext['id'] as String,
              permalink: ext['permalink'] as String?,
            ),
      createdAt: json['created_at'] as String?,
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/models/time_entry.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/models/time_entry.dart
git commit -m "feat: add createdAt field to TimeEntry"
```

---

## Task 3: Add `clientName` to `HarvestProject`

**Files:**
- Modify: `lib/models/project_assignment.dart`

- [ ] **Step 1: Add the field and update the constructor and factory**

Replace the `HarvestProject` class (lines 19–52) with:

```dart
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
```

- [ ] **Step 2: Verify no analysis errors**

```bash
flutter analyze lib/models/project_assignment.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/models/project_assignment.dart
git commit -m "feat: add clientName field to HarvestProject"
```

---

## Task 4: Simplify group toggle state and replace IconButton with FilterChip

**Files:**
- Modify: `lib/screens/recent_entries_screen.dart`

- [ ] **Step 1: Remove SharedPreferences import and persistence methods**

Remove line 4 (`import 'package:shared_preferences/shared_preferences.dart';`).

Replace lines 25–49 (state field + initState + `_loadGroupPref` + `_toggleGrouping`) with:

```dart
  bool _groupByProject = false;

  @override
  void initState() {
    super.initState();
  }
```

- [ ] **Step 2: Replace the toolbar IconButton with a FilterChip**

Replace lines 186–206 (the `Padding` block containing the `Tooltip`/`IconButton`) with:

```dart
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilterChip(
                avatar: Icon(
                  _groupByProject
                      ? Icons.folder_open
                      : Icons.folder_outlined,
                  size: 16,
                ),
                label: Text(
                  _groupByProject ? 'Grouped by project' : 'Group by project',
                ),
                selected: _groupByProject,
                onSelected: (v) => setState(() => _groupByProject = v),
              ),
            ],
          ),
        ),
```

- [ ] **Step 3: Verify no analysis errors**

```bash
flutter analyze lib/screens/recent_entries_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/recent_entries_screen.dart
git commit -m "feat: replace group toggle IconButton with session-only FilterChip"
```

---

## Task 5: Rewrite grouping logic and ProjectGroupHeader

**Files:**
- Modify: `lib/screens/recent_entries_screen.dart`

- [ ] **Step 1: Add the collection import**

At line 1, add after the existing imports:

```dart
import 'package:collection/collection.dart';
```

Also add after the existing `dart:` imports (or at the top of the import block):

```dart
import 'dart:ui' show FontFeature;
```

- [ ] **Step 2: Sort entries in the build method and pass to both list modes**

In the `build` method, immediately after `final isToday = ...` (around line 181), add:

```dart
    final sortedEntries = [...provider.entries]
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
```

Then update the flat `SliverList` (around line 305) to use `sortedEntries`:

```dart
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) =>
                                TimeEntryCard(entry: sortedEntries[i]),
                            childCount: sortedEntries.length,
                          ),
                        ),
```

And update the grouped branch (around line 300) to pass `sortedEntries`:

```dart
                      else if (_groupByProject)
                        SliverToBoxAdapter(
                            child: _buildGroupedList(
                                context, sortedEntries))
```

- [ ] **Step 3: Rewrite `_buildGroupedList`**

Replace the entire `_buildGroupedList` method (lines 99–174) with:

```dart
  Widget _buildGroupedList(BuildContext context, List<TimeEntry> entries) {
    final catProvider = context.watch<ProjectCategoryProvider>();
    final projects = context.watch<AssignmentProvider>().projects;

    final grouped = groupBy<TimeEntry, int>(entries, (e) => e.projectId);

    for (final es in grouped.values) {
      es.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    }

    final groupList = grouped.entries.toList()
      ..sort((a, b) => (b.value.first.createdAt ?? '')
          .compareTo(a.value.first.createdAt ?? ''));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < groupList.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildProjectGroup(context, groupList[i], catProvider, projects),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectGroup(
    BuildContext context,
    MapEntry<int, List<TimeEntry>> group,
    ProjectCategoryProvider catProvider,
    List<HarvestProject> projects,
  ) {
    final pid = group.key;
    final groupEntries = group.value;
    final proj = projects.firstWhereOrNull((p) => p.id == pid);
    final name = proj?.name ?? groupEntries.first.projectName;
    final clientName = proj?.clientName;
    final fallbackCode = (proj != null && proj.code.isNotEmpty)
        ? proj.code
        : name
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(3)
            .map((w) => w[0].toUpperCase())
            .join();
    final cat = catProvider.categoryFor(pid, fallbackCode: fallbackCode);
    final total = groupEntries.fold<double>(0, (s, e) => s + e.hours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectGroupHeader(
          projectName: name,
          clientName: clientName,
          color: cat.color,
          entryCount: groupEntries.length,
          totalHours: total,
        ),
        const SizedBox(height: 8),
        ...groupEntries.map((e) => TimeEntryCard(entry: e)),
      ],
    );
  }
```

- [ ] **Step 4: Remove the `_GroupedListRow` helper class**

Delete lines 322–326 (the `_GroupedListRow` class):

```dart
class _GroupedListRow {
  const _GroupedListRow({required this.builder});

  final WidgetBuilder builder;
}
```

- [ ] **Step 5: Replace `_ProjectGroupHeader` with the new dot-based design**

Replace the entire `_ProjectGroupHeader` class (lines 690–766) with:

```dart
class _ProjectGroupHeader extends StatelessWidget {
  final String projectName;
  final String? clientName;
  final Color color;
  final int entryCount;
  final double totalHours;

  const _ProjectGroupHeader({
    required this.projectName,
    this.clientName,
    required this.color,
    required this.entryCount,
    required this.totalHours,
  });

  String _fmt(double hours) {
    final total = (hours * 60).round();
    final h = total ~/ 60;
    final m = total % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HarvestTokens.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 7),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                projectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HarvestTokens.text,
                ),
              ),
            ),
            if (clientName != null) ...[
              const SizedBox(width: 6),
              const Text(
                '·',
                style: TextStyle(color: HarvestTokens.text4, fontSize: 11),
              ),
              const SizedBox(width: 6),
              Flexible(
                flex: 2,
                child: Text(
                  clientName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: HarvestTokens.text3,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: HarvestTokens.text3,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _fmt(totalHours),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Verify no analysis errors**

```bash
flutter analyze lib/screens/recent_entries_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 7: Full project analysis**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/screens/recent_entries_screen.dart
git commit -m "feat: implement group-by-project with dot headers and createdAt sort"
```
