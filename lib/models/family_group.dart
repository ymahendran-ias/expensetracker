import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroup {
  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final List<String> expenseCategories;
  final List<String> incomeSources;
  final List<String> investmentTypes;
  final List<String> fullAccessMembers;
  final DateTime createdAt;

  FamilyGroup({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.memberIds,
    required this.memberNames,
    this.expenseCategories = const [],
    this.incomeSources = const [],
    this.investmentTypes = const [],
    this.fullAccessMembers = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool hasFullAccess(String userId) =>
      userId == ownerId || fullAccessMembers.contains(userId);

  factory FamilyGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyGroup(
      id: doc.id,
      name: data['name'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberNames: Map<String, String>.from(data['memberNames'] ?? {}),
      expenseCategories:
          List<String>.from(data['expenseCategories'] ?? []),
      incomeSources: List<String>.from(data['incomeSources'] ?? []),
      investmentTypes:
          List<String>.from(data['investmentTypes'] ?? []),
      fullAccessMembers:
          List<String>.from(data['fullAccessMembers'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'expenseCategories': expenseCategories,
      'incomeSources': incomeSources,
      'investmentTypes': investmentTypes,
      'fullAccessMembers': fullAccessMembers,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
