class CardItem {
  int? id;
  String title;
  String description;
  DateTime date;
  bool isUntilDate;
  bool isDeleted;
  bool isCompleted;
  String? firebaseId;

  CardItem(
      {this.id,
      required this.title,
      required this.description,
      required this.date,
      required this.isUntilDate,
      this.isDeleted = false,
      this.isCompleted = false,
      this.firebaseId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'isUntilDate': isUntilDate ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory CardItem.fromMap(Map<String, dynamic> map) {
    return CardItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      isUntilDate: map['isUntilDate'] == 1,
      isDeleted: map['isDeleted'] == 1,
      isCompleted: map['isCompleted'] == 1,
    );
  }
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'isUntilDate': isUntilDate,
      'isDeleted': isDeleted,
      'isCompleted': isCompleted,
    };
  }

  factory CardItem.fromFirestoreMap(
      Map<String, dynamic> map, String documentId) {
    return CardItem(
      firebaseId: documentId,
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      isUntilDate: map['isUntilDate'],
      isDeleted: map['isDeleted'],
      isCompleted: map['isCompleted'],
    );
  }
}
