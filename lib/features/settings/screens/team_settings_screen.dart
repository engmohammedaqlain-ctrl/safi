import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/phone_e164.dart';
import '../../../core/auth/firestore_registered_phone_auth.dart';
import '../../../core/bootstrap/prefs_keys.dart';
import '../../../core/services/ledger_team_access.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vault_subpage_scaffold.dart';
import '../models/team_member.dart';
import '../providers/team_provider.dart';

class TeamSettingsScreen extends ConsumerWidget {
  const TeamSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamMembersProvider);
    final canManageAsync = ref.watch(canManageTeamProvider);

    return VaultSubpageScaffold(
      title: 'الفريق والصلاحيات',
      body: canManageAsync.when(
        data: (canManage) {
          if (!canManage) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'هذه الصفحة مخصّصة لمالك المتجر فقط. أنت تعمل حالياً على دفتر متجر آخر بصلاحية محدودة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, height: 1.4),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'أعضاء الفريق',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildTeamMember(
                name: 'أنت (المالك)',
                role: 'مالك المتجر - كافة الصلاحيات',
                icon: LucideIcons.userCheck,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              
              teamAsync.when(
                data: (members) {
                  return Column(
                    children: members.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTeamMember(
                        name: m.phone,
                        role: m.role == 'cashier' ? 'كاشير' : 'مشاهد',
                        icon: LucideIcons.user,
                        color: Colors.grey.shade600,
                        status: m.status,
                        phoneDocId: m.phoneDocId,
                        memberAuthUid: m.memberAuthUid,
                        ref: ref,
                      ),
                    )).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('حدث خطأ في تحميل الفريق'),
              ),

              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => _showAddMemberSheet(context, ref),
                icon: const Icon(LucideIcons.userPlus, size: 20),
                label: const Text('إضافة عضو جديد', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox(),
      ),
    );
  }

  Widget _buildTeamMember({
    required String name,
    required String role,
    required IconData icon,
    required Color color,
    String? status,
    String? phoneDocId,
    String? memberAuthUid,
    WidgetRef? ref,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'active' ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status == 'active' ? 'نشط' : 'في الانتظار',
                          style: TextStyle(
                            fontSize: 10,
                            color: status == 'active' ? Colors.green : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (phoneDocId != null && ref != null)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
              onPressed: () => _removeMember(
                ref.context,
                phoneDocId,
                memberAuthUid: memberAuthUid,
              ),
            )
          else
            const Icon(LucideIcons.chevronLeft, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    String phoneDocId, {
    String? memberAuthUid,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف العضو'),
          content: const Text('هل أنت متأكد من حذف هذا العضو من الفريق؟ لن يتمكن من الوصول إلى متجرك بعد الآن.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        if (memberAuthUid != null && memberAuthUid.isNotEmpty) {
          await LedgerTeamAccess.revokeMember(
            ownerUid: uid,
            memberAuthUid: memberAuthUid,
          );
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('team')
            .doc(phoneDocId)
            .delete();

        await FirebaseFirestore.instance
            .collection('team_invites')
            .doc(phoneDocId)
            .delete();

        await FirebaseFirestore.instance
            .collection('user_sessions')
            .doc(phoneDocId)
            .set({'kicked': true, 'kickedAt': FieldValue.serverTimestamp()});
      }
    }
  }

  void _showAddMemberSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _AddMemberSheet(),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet();

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _phoneController = TextEditingController();
  String _selectedRole = 'cashier'; // 'cashier', 'viewer'
  bool _canAddDebt = true;
  bool _canRecordPayment = true;
  bool _canViewStats = false;
  bool _canDelete = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رقم هاتف صحيح')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final e164 = phoneDigitsToE164(rawPhone);
      final phoneDocId = FirestoreRegisteredPhoneAuth.documentIdFromE164(e164);
      
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final prefs = await SharedPreferences.getInstance();
      final storeName = prefs.getString(PrefsKeys.userName) ?? 'متجر صافي';

      List<String> perms = [];
      if (_canAddDebt) perms.add('add_debt');
      if (_canRecordPayment) perms.add('record_payment');
      if (_canViewStats) perms.add('view_statistics');
      if (_canDelete) perms.add('delete_records');

      final member = TeamMember(
        phoneDocId: phoneDocId,
        phone: e164,
        role: _selectedRole,
        permissions: perms,
        status: 'pending',
        addedAt: DateTime.now(),
      );

      // 1. Save to owner's team subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('team')
          .doc(phoneDocId)
          .set(member.toMap());

      // 2. Save to global invites collection
      await FirebaseFirestore.instance
          .collection('team_invites')
          .doc(phoneDocId)
          .set({
        'ownerUid': uid,
        'storeName': storeName,
        'role': _selectedRole,
        'permissions': perms,
        'status': 'pending',
        'invitedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمت دعوة $e164 بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.85;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إضافة عضو جديد',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم هاتف العضو',
                hintText: 'مثال: 599123456',
                prefixIcon: const Icon(LucideIcons.smartphone, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الدور',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('كاشير'),
                    value: 'cashier',
                    groupValue: _selectedRole,
                    onChanged: (v) {
                      setState(() {
                        _selectedRole = v!;
                        _canAddDebt = true;
                        _canRecordPayment = true;
                        _canViewStats = false;
                        _canDelete = false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('مشاهد'),
                    value: 'viewer',
                    groupValue: _selectedRole,
                    onChanged: (v) {
                      setState(() {
                        _selectedRole = v!;
                        _canAddDebt = false;
                        _canRecordPayment = false;
                        _canViewStats = true;
                        _canDelete = false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'الصلاحيات المخصصة',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            CheckboxListTile(
              title: const Text('إضافة ديون جديدة'),
              value: _canAddDebt,
              onChanged: (v) => setState(() => _canAddDebt = v ?? false),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('تسجيل دفعات'),
              value: _canRecordPayment,
              onChanged: (v) => setState(() => _canRecordPayment = v ?? false),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('رؤية الإحصائيات والتقارير'),
              value: _canViewStats,
              onChanged: (v) => setState(() => _canViewStats = v ?? false),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('حذف السجلات'),
              value: _canDelete,
              onChanged: (v) => setState(() => _canDelete = v ?? false),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addMember,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('إرسال دعوة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
