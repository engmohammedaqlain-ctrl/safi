import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/resolve_firebase_user.dart';
import '../../../core/bootstrap/app_session.dart';
import '../../../core/bootstrap/prefs_keys.dart';
import '../../../core/sync/firebase_sync_status.dart';
import '../../../core/sync/ledger_firestore_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/reports_style_shell.dart';
import '../../../core/router/app_page_route.dart';
import '../../../core/router/main_shell.dart';
import '../../sales/providers/unified_ledger_provider.dart';
import 'store_settings_screen.dart';
import 'team_settings_screen.dart';
import 'smart_features_screen.dart';
import '../providers/team_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTeamSettings = ref.watch(canManageTeamProvider).value == true;
    return ReportsStylePage(
      title: 'الإعدادات',
      subtitle: 'الحساب، المتجر، المزامنة والجلسة',
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── بطاقة المتجر ──
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                AppPageRoute(builder: (_) => const StoreSettingsScreen()),
              ).then((_) => ref.invalidate(storeCardDisplayProvider));
            },
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.store,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ref.watch(storeCardDisplayProvider).when(
                          data: (card) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                card.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          loading: () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 14,
                                width: 160,
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 12,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          error: (_, __) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إعدادات المتجر',
                                style: AppTextStyles.titleSmall,
                              ),
                              Text(
                                'اضغط للتعديل',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                  const Icon(
                    LucideIcons.chevronLeft,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _SectionLabel('الصافي والعرض'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              secondary: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.wallet, color: AppColors.primary, size: 20),
              ),
              title: Text(
                'دمج حركات الديون في الصافي',
                style: AppTextStyles.titleSmall,
              ),
              subtitle: Text(
                'عند الإيقاف: الصندوق وحده في «الصافي»، والديون في الأرشيف فقط. '
                'عند التفعيل (الوضع الافتراضي): نفس قائمة الأرشيف — صندوق + ديون مع بطاقة الصافي الموحّدة.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              value: ref.watch(mergeDebtsIntoSafiProvider),
              onChanged: (v) =>
                  ref.read(mergeDebtsIntoSafiProvider.notifier).setMerged(v),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── إعدادات الحساب ──
          _SectionLabel('إعدادات الحساب'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (showTeamSettings) ...[
                  _SettingsTile(
                    icon: LucideIcons.users,
                    title: 'الفريق والصلاحيات',
                    subtitle: 'المالك، كاشير، مشرف',
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(builder: (_) => const TeamSettingsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 52),
                ],
                _SettingsTile(
                  icon: LucideIcons.cloud,
                  title: 'المزامنة',
                  subtitle: ref.watch(firebaseSyncStatusSubtitleProvider),
                  statusDotColor: ref.watch(ledgerSyncDotColorProvider),
                  onTap: () async {
                    if (!context.mounted) return;

                    void closeLoading() {
                      if (!context.mounted) return;
                      final nav = Navigator.of(context, rootNavigator: true);
                      if (nav.canPop()) nav.pop();
                    }

                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => PopScope(
                        canPop: false,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Center(
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'جاري المزامنة مع السحابة…',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    try {
                      final user = await resolveFirebaseUserForAction(ref);
                      if (!context.mounted) {
                        closeLoading();
                        return;
                      }
                      if (user == null) {
                        closeLoading();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تعذّر المزامنة: لا توجد جلسة Firebase نشطة. أعد تسجيل الدخول من الشاشة الرئيسية.',
                            ),
                          ),
                        );
                        return;
                      }
                      final prefs = await SharedPreferences.getInstance();
                      final ledgerUid =
                          prefs.getString(PrefsKeys.ledgerOwnerUid) ?? user.uid;
                      final ok = await ref
                          .read(ledgerFirestoreSyncProvider)
                          .pushNow(ledgerUid);
                      if (context.mounted) {
                        closeLoading();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'تمت مزامنة النسخة الحالية مع السحابة بنجاح.'
                                  : (ref.read(ledgerSyncUiProvider).lastPushError ??
                                      'تعذّرت المزامنة.'),
                            ),
                            backgroundColor:
                                ok ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        closeLoading();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تعذّرت المزامنة: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 52),
                _SettingsTile(
                  icon: LucideIcons.sparkles,
                  title: 'الميزات الذكية',
                  subtitle: 'مفعّل',
                  onTap: () {
                    Navigator.push(
                      context,
                      AppPageRoute(builder: (_) => const SmartFeaturesScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── تسجيل الخروج ──
          _SectionLabel('الجلسة'),
          GlassCard(
            padding: EdgeInsets.zero,
            child: _SettingsTile(
              icon: LucideIcons.logOut,
              title: 'تسجيل الخروج',
              subtitle: 'العودة لشاشة تسجيل الدخول',
              iconColor: AppColors.error,
              onTap: () async {
                final go = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تسجيل الخروج؟'),
                    content: const Text('ستحتاج لإدخال رقم الهاتف مرة أخرى.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('تسجيل خروج'),
                      ),
                    ],
                  ),
                );
                if (go == true) {
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  await ref.read(appSessionProvider.notifier).logout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor,
    this.statusDotColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  /// نقطة صغيرة (مثلاً حالة المزامنة): أخضر / أحمر / برتقالي
  final Color? statusDotColor;

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppColors.primary;
    final leading = statusDotColor != null
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c, size: 20),
              ),
              Positioned(
                left: -2,
                top: -2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: statusDotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          )
        : Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: c, size: 20),
          );
    return ListTile(
      onTap: onTap,
      leading: leading,
      title: Text(title, style: AppTextStyles.titleSmall),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      trailing: onTap != null
          ? Icon(
              LucideIcons.chevronLeft,
              color: iconColor != null
                  ? iconColor!.withValues(alpha: 0.6)
                  : AppColors.textMuted,
              size: 18,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      dense: true,
      minVerticalPadding: 8,
    );
  }
}
