import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// يمنح عضو الفريق صلاحية قراءة/كتابة دفتر المالك في Firestore (مع قواعد `ledger_access`).
class LedgerTeamAccess {
  LedgerTeamAccess._();

  /// يُستدعى بعد تسجيل الدخول بنجاح، قبل مزامنة الدفتر.
  static Future<void> grantForActiveMember({
    required String ownerUid,
    required String phoneDocId,
    required String role,
    List<String>? permissions,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || ownerUid.isEmpty || phoneDocId.isEmpty) return;

    final ownerRef = FirebaseFirestore.instance.collection('users').doc(ownerUid);
    final batch = FirebaseFirestore.instance.batch();

    batch.set(
      ownerRef.collection('ledger_access').doc(uid),
      {
        'active': true,
        'role': role,
        'phoneDocId': phoneDocId,
        'permissions': permissions ?? <String>[],
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      ownerRef.collection('team').doc(phoneDocId),
      {
        'memberAuthUid': uid,
        'status': 'active',
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  static Future<void> revokeMember({
    required String ownerUid,
    required String memberAuthUid,
  }) async {
    if (ownerUid.isEmpty || memberAuthUid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('ledger_access')
        .doc(memberAuthUid)
        .delete();
  }
}
