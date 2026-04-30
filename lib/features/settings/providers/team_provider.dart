import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/bootstrap/prefs_keys.dart';
import '../../../core/bootstrap/startup_ledger_data.dart';
import '../models/team_member.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserRoleState + UserRoleNotifier
// يحمل الدور والصلاحيات في الذاكرة ويُحدَّث فوراً عند تغيير الجلسة.
// ─────────────────────────────────────────────────────────────────────────────

class UserRoleState {
  final String role;
  final List<String> permissions;

  const UserRoleState({required this.role, required this.permissions});

  bool get isOwner => role == 'owner';
  bool hasPermission(String perm) => isOwner || permissions.contains(perm);
}

class UserRoleNotifier extends Notifier<UserRoleState> {
  @override
  UserRoleState build() {
    // يقرأ من StartupLedgerData المحمّلة قبل runApp — sync بلا await
    return UserRoleState(
      role: StartupLedgerData.bootstrapUserRole,
      permissions: List<String>.from(
        StartupLedgerData.bootstrapUserPermissions,
      ),
    );
  }

  Future<void> reload() async {
    final p = await SharedPreferences.getInstance();
    final role = p.getString(PrefsKeys.userRole) ?? 'owner';
    final perms = p.getStringList(PrefsKeys.userPermissions) ?? [];
    state = UserRoleState(role: role, permissions: perms);
  }

  /// ضبط مباشر للتحديث الفوري للواجهة (بدون انتظار Prefs)
  void setRole(String role, List<String> permissions) {
    state = UserRoleState(role: role, permissions: permissions);
  }
}

final userRoleNotifierProvider =
    NotifierProvider<UserRoleNotifier, UserRoleState>(UserRoleNotifier.new);

/// للتوافق مع الكود القديم — يعيد AsyncValue<String> مباشرة من الـ state
final userRoleProvider = Provider<AsyncValue<String>>((ref) {
  final roleState = ref.watch(userRoleNotifierProvider);
  return AsyncValue.data(roleState.role);
});

/// للتوافق مع الكود القديم — يعيد AsyncValue<List<String>>
final userPermissionsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final roleState = ref.watch(userRoleNotifierProvider);
  return AsyncValue.data(roleState.permissions);
});

// ─────────────────────────────────────────────────────────────────────────────
// canManageTeam: المالك الحقيقي = uid الحالي في Firebase Auth == ledgerOwnerUid
// ─────────────────────────────────────────────────────────────────────────────

final canManageTeamProvider = FutureProvider<bool>((ref) async {
  // نراقب الـ roleNotifier ليُعاد حسابه عند تغيير الدور
  ref.watch(userRoleNotifierProvider);
  final p = await SharedPreferences.getInstance();
  final ledger = p.getString(PrefsKeys.ledgerOwnerUid);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  return uid != null && ledger != null && uid == ledger;
});

// ─────────────────────────────────────────────────────────────────────────────
// TeamMembers
// ─────────────────────────────────────────────────────────────────────────────

final teamMembersProvider = StreamProvider<List<TeamMember>>((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final uid =
      prefs.getString(PrefsKeys.ledgerOwnerUid) ??
      FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    yield [];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('team')
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => TeamMember.fromFirestoreDoc(doc.id, doc.data()))
            .toList(),
      );
});

// ─────────────────────────────────────────────────────────────────────────────
// PendingInvites
// ─────────────────────────────────────────────────────────────────────────────

final pendingInvitesProvider = StreamProvider<List<TeamInvite>>((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final phoneDocId = prefs.getString(PrefsKeys.phoneDocId);

  if (phoneDocId == null || phoneDocId.isEmpty) {
    yield [];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('team_invites')
      .where(FieldPath.documentId, isEqualTo: phoneDocId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => TeamInvite.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

// ─────────────────────────────────────────────────────────────────────────────
// TeamInvite model
// ─────────────────────────────────────────────────────────────────────────────

class TeamInvite {
  final String id;
  final String ownerUid;
  final String storeName;
  final String role;
  final List<String> permissions;
  final String status;
  final DateTime invitedAt;

  TeamInvite({
    required this.id,
    required this.ownerUid,
    required this.storeName,
    required this.role,
    required this.permissions,
    required this.status,
    required this.invitedAt,
  });

  factory TeamInvite.fromMap(String id, Map<String, dynamic> map) {
    return TeamInvite(
      id: id,
      ownerUid: map['ownerUid'] ?? '',
      storeName: map['storeName'] ?? 'متجر',
      role: map['role'] ?? 'viewer',
      permissions: List<String>.from(map['permissions'] ?? []),
      status: map['status'] ?? 'pending',
      invitedAt: (map['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
