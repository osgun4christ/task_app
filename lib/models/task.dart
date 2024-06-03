class AppTask {
   int? id;
   String title;
   DateTime deadline;
   bool isCompleted;

  AppTask({
    this.id,
    required this.title,
    required this.deadline,
    this.isCompleted = false,
  });

  AppTask copyWith({
    int? id,
    String? title,
    DateTime? deadline,
    bool? isCompleted,
  }) {
    return AppTask(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory AppTask.fromJson(Map<String, dynamic> json) {
    return AppTask(
      id: json['id'] as int?,
      title: json['title'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      isCompleted: json['isCompleted'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'deadline': deadline.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }




  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'title': title,
      'deadline': deadline.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory AppTask.fromMap(Map<String, dynamic> map) {
    return AppTask(
      id: map['id'],
      title: map['title'],
      deadline: DateTime.parse(map['deadline']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}

