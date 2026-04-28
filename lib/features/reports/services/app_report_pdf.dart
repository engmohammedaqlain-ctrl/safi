import 'package:characters/characters.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../debts/providers/debts_ui_provider.dart';
import '../../sales/models/cashbook_entry.dart';
import '../../sales/providers/unified_ledger_math.dart';

// ignore_for_file: cascade_invocations

/// تصفية المعاملات الدينية ضمن نطاق زمني وحسب العملاء أو الموردين أو الكل.
enum AppReportDebtFilter { unifiedAll, customersOnly, suppliersOnly }

// ─── Palette ──────────────────────────────────────────────────────────────────
final _cPurple = PdfColor(106, 27, 154); // #6A1B9A
final _cPurpleDark = PdfColor(74, 20, 140); // #4A148C
final _cPurpleMid = PdfColor(142, 36, 170); // #8E24AA
final _cPurplePale = PdfColor(243, 238, 248); // #F3EEF8
final _cPurpleBdr = PdfColor(206, 184, 223); // border
final _cGreen = PdfColor(46, 125, 50); // #2E7D32
final _cGreenPale = PdfColor(232, 245, 233); // #E8F5E9
final _cGreenBdr = PdfColor(165, 214, 167);
final _cRed = PdfColor(183, 28, 28); // #B71C1C
final _cRedPale = PdfColor(255, 235, 238); // #FFEBEE
final _cRedBdr = PdfColor(239, 154, 154);
final _cText = PdfColor(26, 26, 46); // #1A1A2E
final _cMuted = PdfColor(123, 120, 144); // #7B7890
final _cWhite = PdfColor(255, 255, 255);
final _cRowEven = PdfColor(255, 255, 255);
final _cRowOdd = PdfColor(250, 248, 253); // subtle lavender tint
// ─── Helpers ──────────────────────────────────────────────────────────────────

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _inRange(DateTime ev, DateTime from, DateTime to) {
  final e = _dayOnly(ev), a = _dayOnly(from), b = _dayOnly(to);
  return !e.isBefore(a) && !e.isAfter(b);
}

String _amt(double v) =>
    v == v.roundToDouble() ? '${v.toStringAsFixed(0)}.0' : v.toStringAsFixed(1);

String _date(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

final _ctrlRx = RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFFFE\uFFFF]');

String _clean(String raw) {
  bool ok(int r) {
    if (r >= 0xD800 && r <= 0xDFFF) return false;
    if (r < 0x20 && r != 0x09 && r != 0x0A && r != 0x0D) return false;
    if (r >= 0x200B && r <= 0x200F) return false;
    if (r >= 0x202A && r <= 0x202E) return false;
    if (r >= 0x2066 && r <= 0x2069) return false;
    if (r >= 0xFE00 && r <= 0xFE0F) return false;
    if (r == 0xFEFF || r == 0x20AA) return false;
    return true;
  }

  final b = StringBuffer();
  for (final r in raw.runes) {
    if (ok(r)) b.writeCharCode(r);
  }
  return b
      .toString()
      .replaceAll('\u2014', '-')
      .replaceAll('\u2013', '-')
      .replaceAll(RegExp(r'[₪\u20AA]'), '');
}

String _safe(String? raw, {int max = 800}) {
  if (raw == null || raw.isEmpty) return '-';
  try {
    final s = _clean(raw.replaceAll(_ctrlRx, '')).trim();
    if (s.isEmpty) return '-';
    final ch = Characters(s);
    return ch.length <= max ? s : '${ch.take(max).join()}...';
  } catch (_) {
    return '-';
  }
}

// ─── Format objects ───────────────────────────────────────────────────────────

PdfStringFormat _fmt({
  PdfTextAlignment align = PdfTextAlignment.right,
  PdfTextDirection dir = PdfTextDirection.rightToLeft,
  double lineSpacing = 1.0,
}) => PdfStringFormat(
  textDirection: dir,
  alignment: align,
  lineSpacing: lineSpacing,
);

final _fmtR = _fmt();
final _fmtC = _fmt(align: PdfTextAlignment.center);
final _fmtL = _fmt(
  align: PdfTextAlignment.left,
  dir: PdfTextDirection.leftToRight,
);

// ─── PDF Builder ──────────────────────────────────────────────────────────────

class AppReportPdfBuilder {
  AppReportPdfBuilder._();

  static List<int>? _fontReg, _fontBold;

  static Future<List<int>> _loadAsset(String path) async {
    final bd = await rootBundle.load(path);
    if (bd.lengthInBytes < 500) throw StateError('خط صغير جداً: $path');
    return bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes).toList();
  }

  static Future<void> _fonts() async {
    _fontReg ??= await _loadAsset('assets/fonts/Amiri-Regular.ttf');
    _fontBold ??= await _loadAsset('assets/fonts/Amiri-Bold.ttf');
  }

  static PdfFont _r(double sz) => PdfTrueTypeFont(_fontReg!, sz);
  static PdfFont _b(double sz) => PdfTrueTypeFont(_fontBold!, sz);

  // ── Drawing primitives ────────────────────────────────────────────────────

  /// Filled + optionally bordered rounded-corner rectangle (using lines since
  /// Syncfusion PDF doesn't have a native rounded-rect primitive).
  static void _rect(PdfGraphics g, Rect b, {PdfBrush? fill, PdfPen? border}) {
    if (fill != null) g.drawRectangle(brush: fill, bounds: b);
    if (border != null) g.drawRectangle(pen: border, bounds: b);
  }

  static void _txt(
    PdfGraphics g,
    String text,
    PdfFont font,
    PdfColor color,
    Rect bounds, {
    PdfStringFormat? fmt,
  }) {
    g.drawString(
      text,
      font,
      brush: PdfSolidBrush(color),
      bounds: bounds,
      format: fmt ?? _fmtR,
    );
  }

  // ── Header (full-width purple band) ──────────────────────────────────────

  static const double _hdrH = 90.0;

  static void _drawHeader(
    PdfPage page,
    double W,
    String title,
    String subtitle,
    String dateRange,
    PdfFont titleFont,
    PdfFont subFont,
    PdfFont smallFont,
  ) {
    final g = page.graphics;

    // Base purple band
    _rect(g, Rect.fromLTWH(0, 0, W, _hdrH), fill: PdfSolidBrush(_cPurple));

    // Dark top stripe (3px)
    _rect(g, Rect.fromLTWH(0, 0, W, 3), fill: PdfSolidBrush(_cPurpleDark));

    // Bottom fade strip
    _rect(
      g,
      Rect.fromLTWH(0, _hdrH - 6, W, 6),
      fill: PdfSolidBrush(_cPurpleMid),
    );

    // Decorative circle shapes (semi-transparent effect via lighter color)
    _rect(
      g,
      Rect.fromLTWH(W - 60, -20, 80, 80),
      fill: PdfSolidBrush(PdfColor(123, 50, 170)),
    );
    _rect(
      g,
      Rect.fromLTWH(W - 20, 40, 50, 50),
      fill: PdfSolidBrush(PdfColor(90, 20, 140)),
    );

    // App name badge (top-left)
    _rect(
      g,
      Rect.fromLTWH(8, 8, 42, 18),
      fill: PdfSolidBrush(PdfColor(255, 255, 255, 40)),
    );
    _txt(g, 'صافي', _r(8), _cWhite, Rect.fromLTWH(8, 9, 42, 16), fmt: _fmtC);

    // Title
    _txt(
      g,
      title,
      titleFont,
      _cWhite,
      Rect.fromLTWH(8, 22, W - 80, 32),
      fmt: _fmtR,
    );

    // Subtitle + date on same line
    _txt(
      g,
      subtitle,
      subFont,
      PdfColor(220, 200, 235),
      Rect.fromLTWH(8, 58, W - 80, 18),
      fmt: _fmtR,
    );
    _txt(
      g,
      dateRange,
      smallFont,
      PdfColor(200, 180, 220),
      Rect.fromLTWH(8, 72, W - 80, 14),
      fmt: _fmtR,
    );
  }

  // ── KPI Cards (3-up row) ──────────────────────────────────────────────────

  static const double _kpiH = 72.0;
  static const double _kpiGap = 6.0;

  static void _drawKpiRow(
    PdfPage page,
    double Y,
    double W,
    double totalIn,
    double totalOut,
    double net,
    PdfFont labelFont,
    PdfFont valFont,
    PdfFont unitFont,
  ) {
    final g = page.graphics;
    final cardW = (W - _kpiGap * 2) / 3;

    // In RTL layout: positions from right → وارد | صادر | صافي
    // But PDF coordinates are always LTR (left=0), so:
    //   rightmost card (وارد)  = x: W - cardW
    //   middle card   (صادر)  = x: (W - cardW)/2 ... actually:
    // Let's just do 3 equal columns:
    final boxes = [
      // [x, value, label, bg, bdr, textColor, sign]
      [W - cardW, totalIn, 'وارد', _cGreenPale, _cGreenBdr, _cGreen, '+'],
      [cardW + _kpiGap, totalOut, 'صادر', _cRedPale, _cRedBdr, _cRed, '-'],
      [
        0.0,
        net,
        'الصافي',
        net >= 0 ? _cGreenPale : _cRedPale,
        net >= 0 ? _cGreenBdr : _cRedBdr,
        net >= 0 ? _cGreen : _cRed,
        net >= 0 ? '+' : '',
      ],
    ];

    for (final b in boxes) {
      final x = b[0] as double;
      final value = b[1] as double;
      final label = b[2] as String;
      final bg = b[3] as PdfColor;
      final bdr = b[4] as PdfColor;
      final color = b[5] as PdfColor;
      final sign = b[6] as String;

      // Card background + border
      _rect(
        g,
        Rect.fromLTWH(x, Y, cardW, _kpiH),
        fill: PdfSolidBrush(bg),
        border: PdfPen(bdr, width: 1.2),
      );

      // Top accent stripe
      _rect(g, Rect.fromLTWH(x, Y, cardW, 3), fill: PdfSolidBrush(color));

      // Label
      _txt(
        g,
        label,
        labelFont,
        color,
        Rect.fromLTWH(x + 4, Y + 8, cardW - 8, 16),
        fmt: _fmtC,
      );

      // Value
      final valStr = '$sign${_amt(value)} ش';
      _txt(
        g,
        valStr,
        valFont,
        color,
        Rect.fromLTWH(x + 4, Y + 28, cardW - 8, 26),
        fmt: _fmtC,
      );

      // Thin divider between label and value
      g.drawLine(
        PdfPen(bdr, width: 0.5),
        Offset(x + 8, Y + 26),
        Offset(x + cardW - 8, Y + 26),
      );
    }
  }

  // ── Section heading bar ────────────────────────────────────────────────────

  static const double _secH = 30.0;

  /// Returns the new Y after drawing the section title.
  static double _sectionBar(
    PdfPage page,
    double Y,
    double W,
    String title,
    PdfFont font,
  ) {
    final g = page.graphics;
    // Full-width bar in lavender
    _rect(
      g,
      Rect.fromLTWH(0, Y, W, _secH),
      fill: PdfSolidBrush(_cPurplePale),
      border: PdfPen(_cPurpleBdr, width: 0.6),
    );

    // Right accent bar (RTL indicator)
    _rect(g, Rect.fromLTWH(W - 5, Y, 5, _secH), fill: PdfSolidBrush(_cPurple));

    _txt(
      g,
      title,
      font,
      _cPurpleDark,
      Rect.fromLTWH(8, Y + 6, W - 20, _secH - 8),
      fmt: _fmtR,
    );
    return Y + _secH + 5;
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  static void _footer(PdfPage page, double W, double pageH, PdfFont font) {
    final g = page.graphics;
    const fH = 24.0;
    final y = pageH - fH;

    _rect(g, Rect.fromLTWH(0, y, W, fH), fill: PdfSolidBrush(_cPurplePale));
    g.drawLine(PdfPen(_cPurpleBdr, width: 0.8), Offset(0, y), Offset(W, y));

    // Left: app name
    _txt(
      g,
      'تطبيق صافي',
      font,
      _cPurple,
      Rect.fromLTWH(0, y + 5, W / 2, 16),
      fmt: _fmt(
        align: PdfTextAlignment.left,
        dir: PdfTextDirection.rightToLeft,
      ),
    );

    // Right: date
    _txt(
      g,
      _date(DateTime.now()),
      font,
      _cMuted,
      Rect.fromLTWH(W / 2, y + 5, W / 2, 16),
      fmt: _fmt(
        align: PdfTextAlignment.right,
        dir: PdfTextDirection.leftToRight,
      ),
    );
  }

  // ── Info row (for client card) ─────────────────────────────────────────────

  static double _infoLine(
    PdfGraphics g,
    double Y,
    double W,
    String label,
    String value,
    PdfFont labelFont,
    PdfFont valueFont, {
    PdfColor? valueColor,
  }) {
    _txt(
      g,
      '$label:',
      labelFont,
      _cMuted,
      Rect.fromLTWH(0, Y, W * 0.38, 16),
      fmt: _fmtL,
    );
    _txt(
      g,
      value,
      valueFont,
      valueColor ?? _cText,
      Rect.fromLTWH(W * 0.38, Y, W * 0.62, 16),
      fmt: _fmtR,
    );
    return Y + 20;
  }

  // ── Grid builder (shared) ─────────────────────────────────────────────────

  static void _applyGridStyle(
    PdfGrid grid,
    PdfFont headerFont,
    PdfFont cellFont,
  ) {
    // Header styling
    final hr = grid.headers[0];
    hr.style.backgroundBrush = PdfSolidBrush(_cPurple);
    hr.style.textBrush = PdfSolidBrush(_cWhite);
    hr.style.font = headerFont;

    // Grid-level defaults
    grid.style = PdfGridStyle(
      font: cellFont,
      textBrush: PdfSolidBrush(_cText),
      cellPadding: PdfPaddings(left: 6, right: 6, top: 6, bottom: 6),
    );

    // Defaults to drawing borders around cells since cellPadding is set.

    // Alternating row fills
    for (var r = 0; r < grid.rows.count; r++) {
      grid.rows[r].style.backgroundBrush = PdfSolidBrush(
        r.isEven ? _cRowEven : _cRowOdd,
      );
    }

    // RTL format on all cells
    final fmt = _fmtR;
    for (var r = 0; r < grid.headers.count; r++) {
      for (var c = 0; c < grid.headers[r].cells.count; c++) {
        grid.headers[r].cells[c].stringFormat = fmt;
      }
    }
    for (var r = 0; r < grid.rows.count; r++) {
      for (var c = 0; c < grid.rows[r].cells.count; c++) {
        grid.rows[r].cells[c].stringFormat = fmt;
      }
    }
  }

  // ── Cash Table ───────────────────────────────────────────────────────────

  static PdfGrid _cashGrid(
    List<CashbookEntry> rows,
    PdfFont hFont,
    PdfFont cFont,
  ) {
    final g = PdfGrid();
    g.columns.add(count: 4);
    g.headers.add(1);
    g.repeatHeader = true;
    g.columns[0].width = 75; // date
    g.columns[1].width = 55; // type
    g.columns[2].width = -1; // description (auto)
    g.columns[3].width = 72; // amount

    final h = g.headers[0];
    h.cells[0].value = 'التاريخ';
    h.cells[1].value = 'النوع';
    h.cells[2].value = 'البيان';
    h.cells[3].value = 'المبلغ (ش)';

    if (rows.isEmpty) {
      final row = g.rows.add();
      row.cells[0].value = '(لا توجد حركات في هذه الفترة)';
      row.cells[0].columnSpan = 4;
    } else {
      for (final e in rows) {
        final isIn = e.isIncome;
        final row = g.rows.add();
        row.cells[0].value = _date(e.date);
        row.cells[1].value = isIn ? 'وارد' : 'صادر';
        row.cells[1].style.textBrush = PdfSolidBrush(isIn ? _cGreen : _cRed);
        row.cells[2].value = _safe(e.title, max: 80);
        row.cells[3].value = '${isIn ? '+' : '-'}${_amt(e.amount)}';
        row.cells[3].style.textBrush = PdfSolidBrush(isIn ? _cGreen : _cRed);
      }
    }
    _applyGridStyle(g, hFont, cFont);
    return g;
  }

  // ── Multi-client Debt Table ──────────────────────────────────────────────

  static PdfGrid _debtGrid(
    List<TransactionUi> rows,
    List<DebtorUi> debtors,
    PdfFont hFont,
    PdfFont cFont,
  ) {
    final g = PdfGrid();
    g.columns.add(count: 5);
    g.headers.add(1);
    g.repeatHeader = true;
    g.columns[0].width = 70;
    g.columns[1].width = 72;
    g.columns[2].width = -1;
    g.columns[3].width = 48;
    g.columns[4].width = 62;

    final h = g.headers[0];
    h.cells[0].value = 'التاريخ';
    h.cells[1].value = 'الجهة';
    h.cells[2].value = 'البيان';
    h.cells[3].value = 'النوع';
    h.cells[4].value = 'المبلغ (ش)';

    if (rows.isEmpty) {
      final row = g.rows.add();
      row.cells[0].value = '(لا توجد معاملات في هذه الفترة)';
      row.cells[0].columnSpan = 5;
    } else {
      for (final t in rows) {
        final isGave = t.type == TransactionType.gave;
        final row = g.rows.add();
        row.cells[0].value = _date(t.date);
        row.cells[1].value = _safe(
          UnifiedLedgerMath.debtName(debtors, t.customerId),
          max: 30,
        );
        row.cells[2].value = _safe(t.note, max: 45);
        row.cells[3].value = isGave ? 'أعطيت' : 'أخذت';
        row.cells[3].style.textBrush = PdfSolidBrush(isGave ? _cRed : _cGreen);
        row.cells[4].value = '${isGave ? '-' : '+'}${_amt(t.amount)}';
        row.cells[4].style.textBrush = PdfSolidBrush(isGave ? _cRed : _cGreen);
      }
    }
    _applyGridStyle(g, hFont, cFont);
    return g;
  }

  // ── Single-client Transaction Table ─────────────────────────────────────

  static PdfGrid _clientGrid(
    List<TransactionUi> rows,
    PdfFont hFont,
    PdfFont cFont,
  ) {
    final g = PdfGrid();
    g.columns.add(count: 4);
    g.headers.add(1);
    g.repeatHeader = true;
    g.columns[0].width = 75;
    g.columns[1].width = -1;
    g.columns[2].width = 55;
    g.columns[3].width = 72;

    final h = g.headers[0];
    h.cells[0].value = 'التاريخ';
    h.cells[1].value = 'البيان';
    h.cells[2].value = 'النوع';
    h.cells[3].value = 'المبلغ (ش)';

    if (rows.isEmpty) {
      final row = g.rows.add();
      row.cells[0].value = '(لا توجد معاملات في هذه الفترة)';
      row.cells[0].columnSpan = 4;
    } else {
      for (final t in rows) {
        final isGave = t.type == TransactionType.gave;
        final row = g.rows.add();
        row.cells[0].value = _date(t.date);
        row.cells[1].value = _safe(t.note, max: 60);
        row.cells[2].value = isGave ? 'أعطيت' : 'أخذت';
        row.cells[2].style.textBrush = PdfSolidBrush(isGave ? _cRed : _cGreen);
        row.cells[3].value = '${isGave ? '-' : '+'}${_amt(t.amount)}';
        row.cells[3].style.textBrush = PdfSolidBrush(isGave ? _cRed : _cGreen);
      }
    }
    _applyGridStyle(g, hFont, cFont);
    return g;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: General report  (cash + debts)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Uint8List> build({
    required DateTime fromInclusive,
    required DateTime toInclusive,
    required AppReportDebtFilter filter,
    required List<CashbookEntry> cash,
    required List<TransactionUi> txs,
    required List<DebtorUi> debtors,
    String? storeName,
  }) async {
    await _fonts();
    final fR8 = _r(8);
    final fR9 = _r(9);
    final fR7 = _r(7);
    final fB9 = _b(9);
    final fB11 = _b(11);
    final fB17 = _b(17);
    final fB10 = _b(10);

    // ── Filter ──────────────────────────────────
    final cashF = [
      for (final e in cash)
        if (_inRange(e.date, fromInclusive, toInclusive)) e,
    ];

    final allowedIds = <String>{};
    for (final d in debtors) {
      switch (filter) {
        case AppReportDebtFilter.unifiedAll:
          allowedIds.add(d.id);
          break;
        case AppReportDebtFilter.customersOnly:
          if (!d.isSupplier) allowedIds.add(d.id);
          break;
        case AppReportDebtFilter.suppliersOnly:
          if (d.isSupplier) allowedIds.add(d.id);
          break;
      }
    }
    final txRange = [
      for (final t in txs)
        if (_inRange(t.date, fromInclusive, toInclusive)) t,
    ];
    final txsF = switch (filter) {
      AppReportDebtFilter.unifiedAll => txRange,
      _ => [
        for (final t in txRange)
          if (allowedIds.contains(t.customerId)) t,
      ],
    };

    var cashIn = 0.0, cashOut = 0.0;
    for (final e in cashF) {
      if (e.isIncome) {
        cashIn += e.amount;
      } else {
        cashOut += e.amount;
      }
    }
    var gave = 0.0, recv = 0.0;
    for (final t in txsF) {
      if (t.type == TransactionType.gave) {
        gave += t.amount;
      } else {
        recv += t.amount;
      }
    }

    final inclCash = filter == AppReportDebtFilter.unifiedAll;
    final totalIn = (inclCash ? cashIn : 0) + recv;
    final totalOut = (inclCash ? cashOut : 0) + gave;
    final net = totalIn - totalOut;

    final filterLbl = switch (filter) {
      AppReportDebtFilter.unifiedAll => 'صندوق + ديون',
      AppReportDebtFilter.customersOnly => 'ديون العملاء',
      AppReportDebtFilter.suppliersOnly => 'ديون الموردين',
    };

    final cashSorted = [...cashF]..sort((a, b) => b.date.compareTo(a.date));
    final txSorted = [...txsF]..sort((a, b) => b.date.compareTo(a.date));

    // ── Document ─────────────────────────────────
    final doc = PdfDocument();
    doc.pageSettings
      ..margins.all = 32
      ..size = PdfPageSize.a4;

    var page = doc.pages.add();
    final W = page.getClientSize().width;
    final H = page.getClientSize().height;

    // Header
    _drawHeader(
      page,
      W,
      (storeName != null && storeName.trim().isNotEmpty)
          ? _safe(storeName, max: 50)
          : 'تقرير صافي',
      filterLbl,
      'من ${_date(fromInclusive)}  إلى  ${_date(toInclusive)}',
      fB17,
      fB10,
      fR8,
    );

    // KPI row
    final kpiY = _hdrH + 12;
    _drawKpiRow(page, kpiY, W, totalIn, totalOut, net, fR8, fB11, fR8);

    double y = kpiY + _kpiH + 16;

    // Cash section
    if (inclCash) {
      y = _sectionBar(
        page,
        y,
        W,
        'حركات الصندوق  (${cashSorted.length} حركة)',
        fB9,
      );
      final cg = _cashGrid(cashSorted, fB9, fR9);
      final g1 =
          cg.draw(page: page, bounds: Rect.fromLTWH(0, y, W, 0)) ??
          (throw StateError('تعذّر رسم جدول الصندوق.'));
      y = g1.bounds.bottom + 18;
      page = g1.page;
    }

    // Debt section
    y = _sectionBar(
      page,
      y,
      W,
      'حركات الديون  (${txSorted.length} معاملة)',
      fB9,
    );
    final dg = _debtGrid(txSorted, debtors, fB9, fR9);
    final g2 =
        dg.draw(page: page, bounds: Rect.fromLTWH(0, y, W, 0)) ??
        (throw StateError('تعذّر رسم جدول الديون.'));

    _footer(g2.page, W, H, fR7);

    final bytes = await doc.save();
    doc.dispose();
    return Uint8List.fromList(bytes);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: Per-client report
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Uint8List> buildClientReport({
    required DebtorUi client,
    required DateTime fromInclusive,
    required DateTime toInclusive,
    required List<TransactionUi> allTxs,
    String? storeName,
  }) async {
    await _fonts();
    final fR7 = _r(7);
    final fR8 = _r(8);
    final fR9 = _r(9);
    final fB9 = _b(9);
    final fB11 = _b(11);
    final fB17 = _b(17);

    // Filter
    final txs = [
      for (final t in allTxs)
        if (t.customerId == client.id &&
            _inRange(t.date, fromInclusive, toInclusive))
          t,
    ]..sort((a, b) => b.date.compareTo(a.date));

    var gave = 0.0, recv = 0.0;
    for (final t in txs) {
      if (t.type == TransactionType.gave) {
        gave += t.amount;
      } else {
        recv += t.amount;
      }
    }
    final net = recv - gave; // positive = client owes us

    final balance =
        double.tryParse(client.amount.replaceAll('₪', '').trim()) ?? 0.0;
    final clientType = client.isSupplier ? 'مورد' : 'عميل';
    final clientName = _safe(client.name, max: 50);
    final balColor = balance >= 0 ? _cRed : _cGreen;
    final balLabel = balance > 0
        ? 'يدين لك  ${_amt(balance.abs())} ش'
        : balance < 0
        ? 'أنت مدين  ${_amt(balance.abs())} ش'
        : 'لا رصيد';

    // Document
    final doc = PdfDocument();
    doc.pageSettings
      ..margins.all = 32
      ..size = PdfPageSize.a4;

    var page = doc.pages.add();
    final W = page.getClientSize().width;
    final H = page.getClientSize().height;

    // ── Header ──────────────────────────────────────────────────────────────
    _drawHeader(
      page,
      W,
      'كشف حساب $clientType',
      clientName,
      'من ${_date(fromInclusive)}  إلى  ${_date(toInclusive)}',
      fB17,
      fB11,
      fR8,
    );

    // ── Client info card ────────────────────────────────────────────────────
    double y = _hdrH + 12;
    const cardH = 68.0;
    final g = page.graphics;

    _rect(
      g,
      Rect.fromLTWH(0, y, W, cardH),
      fill: PdfSolidBrush(_cWhite),
      border: PdfPen(_cPurpleBdr, width: 1.0),
    );

    // Left accent bar
    _rect(g, Rect.fromLTWH(W - 4, y, 4, cardH), fill: PdfSolidBrush(_cPurple));

    // Top accent line
    _rect(g, Rect.fromLTWH(0, y, W, 2), fill: PdfSolidBrush(_cPurplePale));

    double iy = y + 8;
    iy = _infoLine(g, iy, W - 16, 'الاسم', clientName, fR8, fB9);
    if (client.phone.trim().isNotEmpty) {
      iy = _infoLine(g, iy, W - 16, 'الهاتف', client.phone.trim(), fR8, fR9);
    }
    iy = _infoLine(
      g,
      iy,
      W - 16,
      'الرصيد الحالي',
      balLabel,
      fR8,
      fB9,
      valueColor: balColor,
    );

    y = y + cardH + 12;

    // ── KPI row ─────────────────────────────────────────────────────────────
    _drawKpiRow(page, y, W, recv, gave, net, fR8, fB11, fR8);
    y += _kpiH + 16;

    // ── Transactions ─────────────────────────────────────────────────────────
    y = _sectionBar(page, y, W, 'سجل المعاملات  (${txs.length} حركة)', fB9);
    final tg = _clientGrid(txs, fB9, fR9);
    final g2 =
        tg.draw(page: page, bounds: Rect.fromLTWH(0, y, W, 0)) ??
        (throw StateError('تعذّر رسم الجدول.'));

    _footer(g2.page, W, H, fR7);

    final bytes = await doc.save();
    doc.dispose();
    return Uint8List.fromList(bytes);
  }
}
