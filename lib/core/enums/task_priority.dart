enum TaskPriority {
  urgentImportant,
  importantNotUrgent,
  urgentNotImportant,
  neither;

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
