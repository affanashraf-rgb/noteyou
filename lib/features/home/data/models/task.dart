class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String subject;
  final String type; // assignment, handouts, quiz, etc.
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.subject,
    required this.type,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'subject': subject,
    'type': type,
    'isCompleted': isCompleted,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? "",
    dueDate: DateTime.parse(json['dueDate']),
    subject: json['subject'],
    type: json['type'] ?? "General",
    isCompleted: json['isCompleted'],
  );
}
