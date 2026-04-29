import 'package:flutter/material.dart';

import '../router/app_page_route.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static final WidgetStateProperty<OutlinedBorder?> _calendarDayShape =
      WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(
      borderRadius: AppRadius.rmd,
      side: BorderSide(
        color: AppColors.outlineSoft.withValues(alpha: 0.95),
      ),
    ),
  );

  static final WidgetStateProperty<OutlinedBorder?> _calendarYearShape =
      WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(
      borderRadius: AppRadius.rmd,
      side: BorderSide(
        color: AppColors.outlineSoft.withValues(alpha: 0.9),
      ),
    ),
  );

  static final TextStyle _calendarToggleTextStyle = TextStyle(
    fontFamily: AppFonts.family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// ثيم موحّد لـ [CalendarDatePicker] وحوار اختيار التاريخ.
  static ThemeData calendarPickerOverlay(BuildContext context) {
    final t = Theme.of(context);
    return t.copyWith(
      colorScheme: t.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.textSecondary,
      ),
      datePickerTheme: t.datePickerTheme.copyWith(
        dayShape: _calendarDayShape,
        yearShape: _calendarYearShape,
        toggleButtonTextStyle: _calendarToggleTextStyle,
        subHeaderForegroundColor: AppColors.primary,
      ),
    );
  }

  /// حوار اختيار التاريخ بنفس مظهر التقويم المستعمل في الشيتات.
  static Future<DateTime?> showAppDatePicker({
    required BuildContext context,
    DateTime? initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? currentDate,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
    SelectableDayPredicate? selectableDayPredicate,
    String? helpText,
    String? cancelText,
    String? confirmText,
    Locale? locale,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    TextDirection? textDirection,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
    String? errorFormatText,
    String? errorInvalidText,
    String? fieldHintText,
    String? fieldLabelText,
    TextInputType? keyboardType,
    Offset? anchorPoint,
    ValueChanged<DatePickerEntryMode>? onDatePickerModeChange,
    Icon? switchToInputEntryModeIcon,
    Icon? switchToCalendarEntryModeIcon,
    CalendarDelegate<DateTime> calendarDelegate = const GregorianCalendarDelegate(),
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: currentDate,
      initialEntryMode: initialEntryMode,
      selectableDayPredicate: selectableDayPredicate,
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      locale: locale,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      textDirection: textDirection,
      initialDatePickerMode: initialDatePickerMode,
      errorFormatText: errorFormatText,
      errorInvalidText: errorInvalidText,
      fieldHintText: fieldHintText,
      fieldLabelText: fieldLabelText,
      keyboardType: keyboardType,
      anchorPoint: anchorPoint,
      onDatePickerModeChange: onDatePickerModeChange,
      switchToInputEntryModeIcon: switchToInputEntryModeIcon,
      switchToCalendarEntryModeIcon: switchToCalendarEntryModeIcon,
      calendarDelegate: calendarDelegate,
      builder: (BuildContext _, Widget? child) {
        return Theme(
          data: calendarPickerOverlay(context),
          child: child!,
        );
      },
    );
  }

  /// شيت سفلي بتقويم داخلي — نفس الشكل في صندوق الدين/الدفعة (بدون تكرار الويدجت).
  static Future<DateTime?> showAppCalendarPickerSheet({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? currentDate,
    double height = 360,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Theme(
                    data: calendarPickerOverlay(context),
                    child: CalendarDatePicker(
                      initialDate: initialDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      currentDate: currentDate,
                      onDateChanged: (d) => Navigator.pop(sheetContext, d),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static DatePickerThemeData get _datePickerTheme {
    final baseDayStyle = TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
    return DatePickerThemeData(
      backgroundColor: AppColors.background,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rlg),
      headerBackgroundColor: AppColors.surfaceVariant,
      headerForegroundColor: AppColors.textSecondary,
      headerHeadlineStyle: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 22,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: AppColors.textSecondary,
      ),
      headerHelpStyle: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      weekdayStyle: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
      dayStyle: baseDayStyle,
      dayShape: _calendarDayShape,
      yearStyle: TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      yearShape: _calendarYearShape,
      toggleButtonTextStyle: _calendarToggleTextStyle,
      subHeaderForegroundColor: AppColors.primary,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.textDisabled;
        }
        if (states.contains(WidgetState.selected)) {
          return AppColors.onPrimary;
        }
        return AppColors.textSecondary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.onPrimary;
        }
        return AppColors.primary;
      }),
      todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
      todayBorder: BorderSide(
        color: AppColors.primary.withValues(alpha: 0.35),
      ),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        textStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// الثيم الافتراضي — فاتح، هوية PRD (أرجواني)
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppFonts.family,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.surfaceVariant,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.aiPurple,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineSoft,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.primary,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
        foregroundColor: AppColors.textPrimary,
        // فاصل سفلي رفيع تحت كل AppBar في التطبيق
        shape: Border(
          bottom: BorderSide(
            color: AppColors.outlineSoft,
            width: 1,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelLarge: AppTextStyles.labelLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.outlineSoft),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 56,
        labelTextStyle: WidgetStatePropertyAll(AppTextStyles.labelSmall),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.rmd,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rmd,
          borderSide: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rmd,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: AppTextStyles.bodySmall,
      ),
      dividerColor: AppColors.divider,
      // عائم حتى لا يُضغط جسم الصفحة وزر أسفل الشاشة عند ظهور رسائل التحقق والتنبيهات.
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
      ),
      datePickerTheme: _datePickerTheme,
      // ─── انتقال بنكي ناعم على كل route في التطبيق ───
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS:     AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
        },
      ),
    );
  }
}
