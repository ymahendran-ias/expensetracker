import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> defaultExpenseCategories = [
  'Food & Dining',
  'Transportation',
  'Housing & Rent',
  'Utilities',
  'Entertainment',
  'Healthcare',
  'Shopping',
  'Education',
  'Personal Care',
  'Insurance',
  'Other',
];

class Expense {
  final String id;
  final String date;
  final String category;
  final double amount;
  final String notes;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.notes = '',
    required this.createdBy,
    required this.createdByName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      date: data['date'] ?? '',
      category: data['category'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      notes: data['notes'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'category': category,
      'amount': amount,
      'notes': notes,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
