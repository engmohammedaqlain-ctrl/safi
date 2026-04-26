import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/metric_stat_card.dart';

final homeMetricsProvider = Provider<List<MetricStatData>>((ref) {
  return const [
    MetricStatData(
      title: 'مبيعات اليوم',
      value: '₪ 18,420',
      delta: '+12.4٪',
      deltaColor: AppColors.flowIn,
      icon: LucideIcons.trendingUp,
    ),
    MetricStatData(
      title: 'إجمالي الديون',
      value: '₪ 7,910',
      delta: '3 متأخر',
      deltaColor: AppColors.flowOut,
      icon: LucideIcons.alertCircle,
    ),
    MetricStatData(
      title: 'التدفق النقدي',
      value: '₪ 10,510',
      delta: '+₪ 2,240',
      deltaColor: AppColors.violet,
      icon: LucideIcons.wallet,
    ),
  ];
});

final homeInsightProvider = Provider<String>(
  (ref) =>
      'اتصل بـ 3 مدينين متأخرين — متوقع تحصيل حوالي ₪ 2,150 اليوم إذا تُرسلت رسائل قبل الظهر.',
);
