// DayBook Full Schema Definitions (Part 0 specification).
// Clean data models reflecting all 37 relational tables and single-event-log architecture.

class TableSchemaDefinition {
  final String tableName;
  final List<String> columns;
  final List<String> primaryKeys;
  final List<String> indexes;

  const TableSchemaDefinition({
    required this.tableName,
    required this.columns,
    required this.primaryKeys,
    this.indexes = const [],
  });
}

class DayBookSchemaRegistry {
  static const List<TableSchemaDefinition> allTables = [
    // 1. Single Event Log
    TableSchemaDefinition(
      tableName: 'entries',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'type TEXT NOT NULL', // task_done, habit_tick, alarm_dismiss, expense, mood, note, etc.
        'ts INTEGER NOT NULL', // Unix timestamp in ms
        'payload_json TEXT NOT NULL',
        'mood INTEGER', // 1 to 5
        'energy INTEGER', // 1 to 5
        'sky_code INTEGER', // WMO weather sky code
        'source TEXT NOT NULL', // manual, automated, ai_tool, quick_capture
        'day_key TEXT NOT NULL', // YYYY-MM-DD
      ],
      primaryKeys: ['id'],
      indexes: ['CREATE INDEX idx_entries_day_key ON entries(day_key)', 'CREATE INDEX idx_entries_ts ON entries(ts)'],
    ),

    // 2. Tasks & Projects
    TableSchemaDefinition(
      tableName: 'tasks',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'title TEXT NOT NULL',
        'notes TEXT',
        'priority INTEGER NOT NULL', // 1=UrgentImportant, 2=ImportantNotUrgent, etc.
        'status INTEGER NOT NULL', // 0=pending, 1=in_progress, 2=completed, 3=cancelled
        'due_at INTEGER',
        'estimated_minutes INTEGER NOT NULL DEFAULT 30',
        'category TEXT NOT NULL DEFAULT "Work"',
        'recurrence_rule TEXT',
        'reminder_offsets TEXT', // JSON array of offsets in minutes
        'is_frog INTEGER NOT NULL DEFAULT 0', // Eat the frog designation
        'created_at INTEGER NOT NULL',
        'completed_at INTEGER',
      ],
      primaryKeys: ['id'],
      indexes: ['CREATE INDEX idx_tasks_due_at ON tasks(due_at)', 'CREATE INDEX idx_tasks_status ON tasks(status)'],
    ),
    TableSchemaDefinition(
      tableName: 'subtasks',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE',
        'title TEXT NOT NULL',
        'is_completed INTEGER NOT NULL DEFAULT 0',
        'sort_order INTEGER NOT NULL DEFAULT 0',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'projects',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'name TEXT NOT NULL',
        'description TEXT',
        'color TEXT',
        'target_date INTEGER',
        'is_archived INTEGER NOT NULL DEFAULT 0',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'goals',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'title TEXT NOT NULL',
        'category TEXT NOT NULL',
        'target_date INTEGER',
        'progress_percent REAL NOT NULL DEFAULT 0.0',
        'status TEXT NOT NULL DEFAULT "active"',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'milestones',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'goal_id TEXT NOT NULL REFERENCES goals(id) ON DELETE CASCADE',
        'title TEXT NOT NULL',
        'target_date INTEGER',
        'is_completed INTEGER NOT NULL DEFAULT 0',
      ],
      primaryKeys: ['id'],
    ),

    // 3. Routines & Daily Planning
    TableSchemaDefinition(
      tableName: 'routines',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'name TEXT NOT NULL',
        'time_window TEXT NOT NULL', // e.g. morning, study, evening
        'repeat_days TEXT NOT NULL', // JSON array [1,2,3,4,5]
        'is_active INTEGER NOT NULL DEFAULT 1',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'daily_plans',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'day_key TEXT NOT NULL UNIQUE',
        'wake_time INTEGER NOT NULL',
        'sleep_time INTEGER NOT NULL',
        'total_focus_minutes INTEGER NOT NULL DEFAULT 0',
        'generated_by TEXT NOT NULL DEFAULT "user"',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'plan_blocks',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'plan_id TEXT NOT NULL REFERENCES daily_plans(id) ON DELETE CASCADE',
        'task_id TEXT REFERENCES tasks(id) ON DELETE SET NULL',
        'title TEXT NOT NULL',
        'category TEXT NOT NULL',
        'start_min INTEGER NOT NULL', // Minutes from midnight
        'end_min INTEGER NOT NULL',
        'is_completed INTEGER NOT NULL DEFAULT 0',
        'energy_level INTEGER DEFAULT 3',
      ],
      primaryKeys: ['id'],
    ),

    // 4. Wake Quest & Alarms
    TableSchemaDefinition(
      tableName: 'alarms',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'hour INTEGER NOT NULL',
        'minute INTEGER NOT NULL',
        'label TEXT NOT NULL',
        'repeat_days TEXT NOT NULL', // JSON array
        'is_enabled INTEGER NOT NULL DEFAULT 1',
        'challenge_type TEXT NOT NULL', // math, memory_sequence, movement, qr_scan, ai_scan
        'difficulty TEXT NOT NULL', // easy, medium, hard
        'ringtone TEXT NOT NULL',
        'vibrate INTEGER NOT NULL DEFAULT 1',
        'snooze_policy TEXT NOT NULL',
        'qr_value_hash TEXT',
        'scan_target_label TEXT',
        'ramp_volume INTEGER NOT NULL DEFAULT 1',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'alarm_events',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'alarm_id TEXT NOT NULL REFERENCES alarms(id) ON DELETE CASCADE',
        'fired_at INTEGER NOT NULL',
        'dismissed_at INTEGER',
        'challenge_result TEXT',
        'attempt_count INTEGER NOT NULL DEFAULT 1',
        'wake_score INTEGER',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'sleep_logs',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'day_key TEXT NOT NULL UNIQUE',
        'bedtime INTEGER NOT NULL',
        'wake_time INTEGER NOT NULL',
        'quality_score INTEGER NOT NULL', // 1 to 5
        'sleep_debt_mins INTEGER NOT NULL DEFAULT 0',
        'notes TEXT',
      ],
      primaryKeys: ['id'],
    ),

    // 5. Habits & Focus
    TableSchemaDefinition(
      tableName: 'habits',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'title TEXT NOT NULL',
        'category TEXT NOT NULL',
        'cadence TEXT NOT NULL', // daily, weekly, x_per_week
        'target_days_json TEXT',
        'streak_count INTEGER NOT NULL DEFAULT 0',
        'best_streak INTEGER NOT NULL DEFAULT 0',
        'freeze_tokens INTEGER NOT NULL DEFAULT 2',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'habit_logs',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE',
        'day_key TEXT NOT NULL',
        'status TEXT NOT NULL', // completed, skipped, frozen
        'logged_at INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
      indexes: ['CREATE UNIQUE INDEX idx_habit_day ON habit_logs(habit_id, day_key)'],
    ),
    TableSchemaDefinition(
      tableName: 'focus_sessions',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'task_id TEXT REFERENCES tasks(id) ON DELETE SET NULL',
        'duration_minutes INTEGER NOT NULL',
        'completed_at INTEGER NOT NULL',
        'ambient_sound TEXT',
        'flip_phone_detected INTEGER NOT NULL DEFAULT 0',
      ],
      primaryKeys: ['id'],
    ),

    // 6. Notes, Captures & Attachments
    TableSchemaDefinition(
      tableName: 'notes',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'title TEXT NOT NULL',
        'body TEXT NOT NULL',
        'pinned INTEGER NOT NULL DEFAULT 0',
        'day_key TEXT NOT NULL',
        'created_at INTEGER NOT NULL',
        'updated_at INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'captures',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'raw_text TEXT NOT NULL',
        'source TEXT NOT NULL', // share_intent, quick_tile, push_to_talk
        'processed_into_type TEXT',
        'processed_id TEXT',
        'created_at INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'attachments',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'entry_id TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE',
        'mime_type TEXT NOT NULL',
        'file_path TEXT NOT NULL',
        'file_size_bytes INTEGER NOT NULL',
        'thumbnail_path TEXT',
      ],
      primaryKeys: ['id'],
    ),

    // 7. Money & People
    TableSchemaDefinition(
      tableName: 'expenses',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'amount_paisa INTEGER NOT NULL', // Stored in paisa (1 BDT = 100 paisa)
        'type TEXT NOT NULL', // expense, income
        'category TEXT NOT NULL',
        'account_id TEXT REFERENCES accounts(id)',
        'day_key TEXT NOT NULL',
        'notes TEXT',
        'logged_at INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'budgets',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'category TEXT NOT NULL',
        'monthly_limit_paisa INTEGER NOT NULL',
        'month_key TEXT NOT NULL', // YYYY-MM
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'accounts',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'name TEXT NOT NULL',
        'type TEXT NOT NULL', // cash, bkash, nagad, bank
        'current_balance_paisa INTEGER NOT NULL DEFAULT 0',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'debts',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'person_id TEXT NOT NULL REFERENCES people(id)',
        'amount_paisa INTEGER NOT NULL',
        'is_i_owe INTEGER NOT NULL', // 1=I owe them, 0=They owe me
        'due_date INTEGER',
        'status TEXT NOT NULL DEFAULT "active"', // active, settled
        'notes TEXT',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'people',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'name TEXT NOT NULL',
        'relation TEXT',
        'phone TEXT',
        'birthday TEXT',
        'cadence_days INTEGER',
        'last_contacted_at INTEGER',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'person_links',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'person_id TEXT NOT NULL REFERENCES people(id) ON DELETE CASCADE',
        'entry_id TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE',
        'relationship_note TEXT',
      ],
      primaryKeys: ['id'],
    ),

    // 8. Student Mode (Courses, Exams, Spaced Repetition)
    TableSchemaDefinition(
      tableName: 'courses',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'code TEXT NOT NULL',
        'name TEXT NOT NULL',
        'semester TEXT NOT NULL',
        'instructor TEXT',
        'target_grade REAL',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'assignments',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'course_id TEXT NOT NULL REFERENCES courses(id) ON DELETE CASCADE',
        'title TEXT NOT NULL',
        'due_date INTEGER NOT NULL',
        'weightage REAL',
        'is_completed INTEGER NOT NULL DEFAULT 0',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'exams',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'course_id TEXT NOT NULL REFERENCES courses(id) ON DELETE CASCADE',
        'title TEXT NOT NULL',
        'exam_date INTEGER NOT NULL',
        'room TEXT',
        'syllabus_notes TEXT',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'decks',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'course_id TEXT REFERENCES courses(id) ON DELETE CASCADE',
        'name TEXT NOT NULL',
        'card_count INTEGER NOT NULL DEFAULT 0',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'cards',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'deck_id TEXT NOT NULL REFERENCES decks(id) ON DELETE CASCADE',
        'front TEXT NOT NULL',
        'back TEXT NOT NULL',
        'repetitions INTEGER NOT NULL DEFAULT 0',
        'interval_days INTEGER NOT NULL DEFAULT 1',
        'ease_factor REAL NOT NULL DEFAULT 2.5', // SM-2 standard ease factor
        'next_due_at INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
    ),

    // 9. Memory & AI Tool Logs
    TableSchemaDefinition(
      tableName: 'memories',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'kind TEXT NOT NULL', // fact, preference, episodic_summary
        'memory_key TEXT NOT NULL',
        'memory_value TEXT NOT NULL',
        'is_pinned INTEGER NOT NULL DEFAULT 0',
        'source TEXT NOT NULL',
        'created_at INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'chat_messages',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'role TEXT NOT NULL', // user, assistant, system
        'content TEXT NOT NULL',
        'tool_invocation_json TEXT',
        'created_at INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'tool_call_log',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'tool_name TEXT NOT NULL',
        'parameters_json TEXT NOT NULL',
        'result_json TEXT NOT NULL',
        'is_undone INTEGER NOT NULL DEFAULT 0',
        'created_at INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
    ),

    // 10. Time Capsules, Day Scores, Badges, Settings & Sync
    TableSchemaDefinition(
      tableName: 'time_capsules',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'title TEXT NOT NULL',
        'message TEXT NOT NULL',
        'unlock_date INTEGER NOT NULL',
        'is_unlocked INTEGER NOT NULL DEFAULT 0',
        'created_at INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'day_scores',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'day_key TEXT NOT NULL UNIQUE',
        'score_total INTEGER NOT NULL',
        'tasks_score INTEGER NOT NULL',
        'habits_score INTEGER NOT NULL',
        'focus_score INTEGER NOT NULL',
        'sleep_score INTEGER NOT NULL',
        'wellness_score INTEGER NOT NULL',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'badges',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'badge_code TEXT NOT NULL UNIQUE',
        'name TEXT NOT NULL',
        'tier TEXT NOT NULL',
        'unlocked_at INTEGER',
      ],
      primaryKeys: ['id'],
    ),
    TableSchemaDefinition(
      tableName: 'settings',
      columns: [
        'key TEXT NOT NULL PRIMARY KEY',
        'value TEXT NOT NULL',
      ],
      primaryKeys: ['key'],
    ),
    TableSchemaDefinition(
      tableName: 'sync_log',
      columns: [
        'id TEXT NOT NULL PRIMARY KEY',
        'entity_type TEXT NOT NULL',
        'entity_id TEXT NOT NULL',
        'hlc_timestamp TEXT NOT NULL', // Hybrid Logical Clock string
        'operation TEXT NOT NULL', // INSERT, UPDATE, DELETE
        'is_synced INTEGER NOT NULL DEFAULT 0',
      ],
      primaryKeys: ['id'],
    ),
  ];
}
