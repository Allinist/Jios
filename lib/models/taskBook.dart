class TaskBook {

  int? id;
  String name;
  String? description;
  String? color;
  int createdAt;

  TaskBook({
    this.id,
    required this.name,
    this.description,
    this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'created_at': createdAt,
    };
  }

  factory TaskBook.fromMap(Map<String, dynamic> map) {
    return TaskBook(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color: map['color'],
      createdAt: map['created_at'],
    );
  }
}