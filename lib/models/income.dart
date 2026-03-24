import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> defaultIncomeSources = [
  'Salary',
  'Freelance',
  'Business',
  'Dividends',
  'Rental Income',
  'Interest',
  'Other',
];

class Income {
  final String id;
  final String date;
  final String source;
  final double amount;
  final String notes;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;

  Income({
    required this.id,
    required this.date,
    required this.source,
    required this.amount,
    this.notes = '',
    required this.createdBy,
    required this.createdByName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Income.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Income(
      id: doc.id,
      date: data['date'] ?? '',
      source: data['source'] ?? '',
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
      'source': source,
      'amount': amount,
      'notes': notes,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
