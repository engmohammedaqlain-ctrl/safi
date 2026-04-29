import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  /// مُعرّف مستند الفريق في Firestore (= معرّف رقم الهاتف الموحّد)
  final String phoneDocId;
  final String phone;
  final String role; // 'cashier', 'viewer'
  final List<String> permissions;
  final String status; // 'active', 'pending'
  final DateTime addedAt;

  /// معرّف Firebase لعضو الفريق بعد قبول الدعوة (لإلغاء ledger_access عند الطرد)
  final String? memberAuthUid;

  TeamMember({
    required this.phoneDocId,
    required this.phone,
    required this.role,
    required this.permissions,
    required this.status,
    required this.addedAt,
    this.memberAuthUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'role': role,
      'permissions': permissions,
      'status': status,
      'addedAt': Timestamp.fromDate(addedAt),
      if (memberAuthUid != null) 'memberAuthUid': memberAuthUid,
    };
  }

  factory TeamMember.fromFirestoreDoc(
    String docId,
    Map<String, dynamic> map,
  ) {
    return TeamMember(
      phoneDocId: docId,
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'viewer',
      permissions: List<String>.from(map['permissions'] ?? []),
      status: map['status'] ?? 'pending',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberAuthUid: map['memberAuthUid'] as String?,
    );
  }
}
