import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/bootstrap/app_session.dart';
import '../../../core/router/app_page_route.dart';
import '../../../core/services/ledger_team_access.dart';
import '../../../core/sync/post_login_loading.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/reports_style_shell.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../../debts/screens/customer_detail_screen.dart';
import '../../settings/providers/team_provider.dart';

/// صفحة الإشعارات المربوطة بالديون
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtors = ref.watch(debtorsUiProvider);
    final invitesAsync = ref.watch(pendingInvitesProvider);
    final isOwner = ref.watch(userRoleProvider).value == 'owner';

    final now = DateTime.now();
    final overdueDebts = isOwner
        ? debtors.where((d) {
            if (d.dueDate == null) return false;
            final amt =
                double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
            return amt > 0 && d.dueDate!.isBefore(now);
          }).toList()
        : <DebtorUi>[];

    final upcomingDebts = isOwner
        ? debtors.where((d) {
            if (d.dueDate == null) return false;
            final amt =
                double.tryParse(d.amount.replaceAll('₪', '').trim()) ?? 0;
            return amt > 0 &&
                d.dueDate!.isAfter(now) &&
                d.dueDate!.difference(now).inDays <= 3;
          }).toList()
        : <DebtorUi>[];

    return ReportsStylePage(
      title: 'الإشعارات',
      subtitle: 'تذكيرات الديون ومواعيد السداد',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          invitesAsync.when(
            data: (invites) {
              if (invites.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دعوات الانضمام',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final invite in invites)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () =>
                            _handleNotificationInviteTap(context, ref, invite),
                        child: _NotifTile(
                          icon: LucideIcons.store,
                          color: AppColors.primary,
                          title: 'دعوة انضمام لمتجر ${invite.storeName}',
                          subtitle:
                              'الصلاحية: ${invite.role == 'cashier' ? 'كاشير' : 'مشاهد'}',
                          time: 'اضغط للقبول أو الرفض',
                          unread: true,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          if (overdueDebts.isEmpty &&
              upcomingDebts.isEmpty &&
              (invitesAsync.value?.isEmpty ?? true))
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'لا توجد إشعارات حالياً',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),

          if (overdueDebts.isNotEmpty) ...[
            Text(
              'ديون متأخرة',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            for (final d in overdueDebts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      AppPageRoute<void>(
                        builder: (_) => CustomerDetailScreen(debtor: d),
                      ),
                    );
                  },
                  child: _NotifTile(
                    icon: LucideIcons.alertCircle,
                    color: AppColors.error,
                    title: 'دين متأخر على ${d.name}',
                    subtitle: 'القيمة: ${d.amount} شيكل',
                    time: now.difference(d.dueDate!).inDays == 0
                        ? 'اليوم'
                        : 'تأخر منذ ${now.difference(d.dueDate!).inDays} يوم',
                    unread: true,
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],

          if (upcomingDebts.isNotEmpty) ...[
            Text(
              'ديون قادمة قريباً',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            for (final d in upcomingDebts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      AppPageRoute<void>(
                        builder: (_) => CustomerDetailScreen(debtor: d),
                      ),
                    );
                  },
                  child: _NotifTile(
                    icon: LucideIcons.calendarClock,
                    color: AppColors.warning,
                    title: 'موعد سداد قريب لـ ${d.name}',
                    subtitle: 'القيمة: ${d.amount} شيكل',
                    time: d.dueDate!.difference(now).inDays == 0
                        ? 'اليوم'
                        : 'متبقي ${d.dueDate!.difference(now).inDays} يوم',
                    unread: true,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

Future<void> _handleNotificationInviteTap(
  BuildContext context,
  WidgetRef ref,
  TeamInvite invite,
) async {
  final accept = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('دعوة انضمام لفريق'),
        content: Text(
          'تمت دعوتك للانضمام إلى متجر "${invite.storeName}" بصلاحية "${invite.role == 'cashier' ? 'كاشير' : 'مشاهد'}". هل تقبل الدعوة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رفض'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('قبول'),
          ),
        ],
      ),
    ),
  );

  if (accept == null) return;

  if (accept) {
    ref
        .read(userRoleNotifierProvider.notifier)
        .setRole(invite.role, invite.permissions);
  }

  ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(accept);

  try {
    if (accept) {
      await FirebaseFirestore.instance
          .collection('team_invites')
          .doc(invite.id)
          .update({'status': 'active'});

      await LedgerTeamAccess.grantForActiveMember(
        ownerUid: invite.ownerUid,
        phoneDocId: invite.id,
        role: invite.role,
        permissions: invite.permissions,
      );

      await ref.read(appSessionProvider.notifier).onLoginSuccess(
            phoneDocId: invite.id,
            ownerUidOverride: invite.ownerUid,
            role: invite.role,
            permissions: invite.permissions,
          );

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'مرحباً! انضممت إلى متجر "${invite.storeName}" بصلاحية '
              '${invite.role == 'cashier' ? 'كاشير' : 'مشاهد'}',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      if (authUid != null) {
        await LedgerTeamAccess.revokeMember(
          ownerUid: invite.ownerUid,
          memberAuthUid: authUid,
        );
      }
      await FirebaseFirestore.instance
          .collection('team_invites')
          .doc(invite.id)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(invite.ownerUid)
          .collection('team')
          .doc(invite.id)
          .delete();
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  } finally {
    ref.read(postLoginLedgerLoadingProvider.notifier).setLoading(false);
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.time,
    required this.unread,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.rmd,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
