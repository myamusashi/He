class TransactionModel {
  final int? id;
  final double amount;
  final String type; // 'income' atau 'expense'
  final int? categoryId;
  final String date;
  final String? note;
  final String? emotionType; // dari EmotionType.name

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.date,
    this.note,
    this.emotionType,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'type': type,
    'category_id': categoryId,
    'date': date,
    'note': note,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        id: map['id'],
        amount: map['amount'],
        type: map['type'],
        categoryId: map['category_id'],
        date: map['date'],
        note: map['note'],
      );
}
