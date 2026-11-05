class SubtaskItem {
  final String id;
  final String title;
  final bool isCompleted;

  const SubtaskItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubtaskItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubtaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory SubtaskItem.fromJson(Map<String, dynamic> json) => SubtaskItem(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}
