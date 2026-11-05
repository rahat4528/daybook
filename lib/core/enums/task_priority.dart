enum TaskPriority {
  urgentImportant,
  importantNotUrgent,
  urgentNotImportant,
  neither;

  static const TaskPriority p1 = TaskPriority.urgentImportant;
  static const TaskPriority p2 = TaskPriority.importantNotUrgent;
  static const TaskPriority p3 = TaskPriority.urgentNotImportant;
  static const TaskPriority p4 = TaskPriority.neither;

  String get label {
    switch (this) {
      case TaskPriority.urgentImportant:
        return 'P1: Urgent & Important';
      case TaskPriority.importantNotUrgent:
        return 'P2: Important, Not Urgent';
      case TaskPriority.urgentNotImportant:
        return 'P3: Urgent, Not Important';
      case TaskPriority.neither:
        return 'P4: Low Priority';
    }
  }

  int get baseScore {
    switch (this) {
      case TaskPriority.urgentImportant:
        return 100;
      case TaskPriority.importantNotUrgent:
        return 75;
      case TaskPriority.urgentNotImportant:
        return 50;
      case TaskPriority.neither:
        return 25;
    }
  }
}

