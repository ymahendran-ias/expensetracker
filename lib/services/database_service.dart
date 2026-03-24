import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import '../models/income.dart';
import '../models/investment.dart';
import '../models/app_user.dart';
import '../models/family_group.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──── User Operations ────

  Future<void> createUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(
          user.toMap(),
          SetOptions(merge: true),
        );
  }

  Stream<AppUser?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  // ──── Family Operations ────

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<String> createFamily(
      String name, String userId, String userName) async {
    final inviteCode = _generateInviteCode();
    final familyRef = await _db.collection('families').add({
      'name': name,
      'inviteCode': inviteCode,
      'ownerId': userId,
      'memberIds': [userId],
      'memberNames': {userId: userName},
      'expenseCategories': defaultExpenseCategories,
      'incomeSources': defaultIncomeSources,
      'investmentTypes': defaultInvestmentTypes,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db
        .collection('users')
        .doc(userId)
        .update({'familyId': familyRef.id});
    return familyRef.id;
  }

  Future<FamilyGroup?> joinFamily(
      String inviteCode, String userId, String userName) async {
    final query = await _db
        .collection('families')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;

    final familyDoc = query.docs.first;
    await familyDoc.reference.update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberNames.$userId': userName,
    });
    await _db
        .collection('users')
        .doc(userId)
        .update({'familyId': familyDoc.id});
    return FamilyGroup.fromFirestore(familyDoc);
  }

  Stream<FamilyGroup?> familyStream(String familyId) {
    return _db.collection('families').doc(familyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return FamilyGroup.fromFirestore(doc);
    });
  }

  Future<void> leaveFamily(String familyId, String userId) async {
    await _db.collection('families').doc(familyId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'memberNames.$userId': FieldValue.delete(),
    });
    await _db.collection('users').doc(userId).update({'familyId': null});
  }

  // ──── Category Operations ────

  Future<void> updateCategories(String familyId, {
    List<String>? expenseCategories,
    List<String>? incomeSources,
    List<String>? investmentTypes,
  }) async {
    final data = <String, dynamic>{};
    if (expenseCategories != null) data['expenseCategories'] = expenseCategories;
    if (incomeSources != null) data['incomeSources'] = incomeSources;
    if (investmentTypes != null) data['investmentTypes'] = investmentTypes;
    if (data.isNotEmpty) {
      await _db.collection('families').doc(familyId).update(data);
    }
  }

  // ──── Expense Operations ────

  Future<void> addExpense(String familyId, Expense expense) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('expenses')
        .add(expense.toMap());
  }

  Future<void> updateExpense(
      String familyId, String expenseId, Map<String, dynamic> data) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('expenses')
        .doc(expenseId)
        .update(data);
  }

  Future<void> deleteExpense(String familyId, String expenseId) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  Stream<List<Expense>> expensesStream(String familyId, String yearMonth) {
    final nextMonth = _nextMonth(yearMonth);
    return _db
        .collection('families')
        .doc(familyId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: yearMonth)
        .where('date', isLessThan: nextMonth)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  /// Fetches expenses across multiple months for trend analysis.
  Stream<List<Expense>> expensesRangeStream(
      String familyId, String startYearMonth, String endYearMonth) {
    final afterEnd = _nextMonth(endYearMonth);
    return _db
        .collection('families')
        .doc(familyId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startYearMonth)
        .where('date', isLessThan: afterEnd)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  // ──── Income Operations ────

  Future<void> addIncome(String familyId, Income income) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('income')
        .add(income.toMap());
  }

  Future<void> updateIncome(
      String familyId, String incomeId, Map<String, dynamic> data) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('income')
        .doc(incomeId)
        .update(data);
  }

  Future<void> deleteIncome(String familyId, String incomeId) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('income')
        .doc(incomeId)
        .delete();
  }

  Stream<List<Income>> incomeStream(String familyId, String yearMonth) {
    final nextMonth = _nextMonth(yearMonth);
    return _db
        .collection('families')
        .doc(familyId)
        .collection('income')
        .where('date', isGreaterThanOrEqualTo: yearMonth)
        .where('date', isLessThan: nextMonth)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Income.fromFirestore(doc)).toList());
  }

  // ──── Investment Operations ────

  Future<void> addInvestment(String familyId, Investment investment) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('investments')
        .add(investment.toMap());
  }

  Future<void> updateInvestment(
      String familyId, String investmentId, Map<String, dynamic> data) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('investments')
        .doc(investmentId)
        .update(data);
  }

  Future<void> deleteInvestment(String familyId, String investmentId) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('investments')
        .doc(investmentId)
        .delete();
  }

  Stream<List<Investment>> investmentsStream(
      String familyId, String yearMonth) {
    final nextMonth = _nextMonth(yearMonth);
    return _db
        .collection('families')
        .doc(familyId)
        .collection('investments')
        .where('date', isGreaterThanOrEqualTo: yearMonth)
        .where('date', isLessThan: nextMonth)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Investment.fromFirestore(doc)).toList());
  }

  // ──── Account Deletion ────

  Future<void> deleteUserData(String userId, String? familyId) async {
    if (familyId != null) {
      final familyDoc = await _db.collection('families').doc(familyId).get();
      if (familyDoc.exists) {
        final memberIds =
            List<String>.from(familyDoc.data()?['memberIds'] ?? []);
        if (memberIds.length <= 1) {
          await _deleteFamilyAndData(familyId);
        } else {
          await leaveFamily(familyId, userId);
        }
      }
    }
    await _db.collection('users').doc(userId).delete();
  }

  Future<void> _deleteFamilyAndData(String familyId) async {
    final familyRef = _db.collection('families').doc(familyId);
    for (final subcollection in ['expenses', 'income', 'investments']) {
      final docs = await familyRef.collection(subcollection).get();
      final batch = _db.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await familyRef.delete();
  }

  // ──── Helpers ────

  String _nextMonth(String yearMonth) {
    final parts = yearMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    if (month == 12) {
      return '${year + 1}-01';
    }
    return '$year-${(month + 1).toString().padLeft(2, '0')}';
  }
}
