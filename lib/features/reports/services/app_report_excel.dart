import 'dart:typed_data';

import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../../cash_flow/data/financial_account_model.dart';
import '../../debts/providers/debts_ui_provider.dart';
import '../../sales/models/cashbook_entry.dart';
import '../../sales/providers/unified_ledger_math.dart';

// ignore_for_file: cascade_invocations

/// بناء ملفات Excel لتقارير المحافظ والتقارير الشاملة.
class AppReportExcelBuilder {
  AppReportExcelBuilder._();

  // ── Helpers ──────────────────────────────────────────────────────────────

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _inRange(DateTime ev, DateTime from, DateTime to) {
    final e = _dayOnly(ev), a = _dayOnly(from), b = _dayOnly(to);
    return !e.isBefore(a) && !e.isAfter(b);
  }

  static String _amt(double v) => v == v.roundToDouble()
      ? '${v.toStringAsFixed(0)}.0'
      : v.toStringAsFixed(1);

  static String _date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  // ── Styling ─────────────────────────────────────────────────────────────

  static void _applyHeaderStyle(Style style) {
    style.backColor = '#6A1B9A';
    style.fontColor = '#FFFFFF';
    style.bold = true;
    style.fontSize = 11;
    style.hAlign = HAlignType.center;
    style.vAlign = VAlignType.center;
  }

  static void _applyTitleStyle(Style style) {
    style.backColor = '#4A148C';
    style.fontColor = '#FFFFFF';
    style.bold = true;
    style.fontSize = 14;
    style.hAlign = HAlignType.center;
    style.vAlign = VAlignType.center;
  }

  static void _applyInfoLabelStyle(Style style) {
    style.backColor = '#F3EEF8';
    style.fontColor = '#4A4560';
    style.bold = true;
    style.fontSize = 11;
    style.hAlign = HAlignType.right;
  }

  static void _applyInfoValueStyle(Style style) {
    style.fontColor = '#1A1A2E';
    style.fontSize = 11;
    style.hAlign = HAlignType.right;
  }

  static void _applySectionStyle(Style style) {
    style.backColor = '#F3EEF8';
    style.fontColor = '#6A1B9A';
    style.bold = true;
    style.fontSize = 12;
    style.hAlign = HAlignType.right;
  }

  static void _applyGreenStyle(Style style) {
    style.fontColor = '#2E7D32';
    style.bold = true;
  }

  static void _applyRedStyle(Style style) {
    style.fontColor = '#B71C1C';
    style.bold = true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: Per-wallet Excel report
  // ─────────────────────────────────────────────────────────────────────────

  static Uint8List buildWalletReport({
    required FinancialAccount account,
    required DateTime fromInclusive,
    required DateTime toInclusive,
    required List<CashbookEntry> cashEntries,
    required List<TransactionUi> debtTxs,
    required List<DebtorUi> debtors,
    required double effectiveBalance,
    String? storeName,
  }) {
    final workbook = Workbook();

    // ── Sheet 1: ملخص المحفظة ──
    final summary = workbook.worksheets[0];
    summary.name = 'ملخص المحفظة';
    summary.enableSheetCalculations();
    summary.isRightToLeft = true;

    // Column widths
    summary.getRangeByIndex(1, 1).columnWidth = 25;
    summary.getRangeByIndex(1, 2).columnWidth = 30;
    summary.getRangeByIndex(1, 3).columnWidth = 20;
    summary.getRangeByIndex(1, 4).columnWidth = 20;

    // Title row
    final titleRange = summary.getRangeByName('A1:D1');
    titleRange.merge();
    titleRange.setText('تقرير محفظة: ${account.name}');
    _applyTitleStyle(titleRange.cellStyle);
    summary.getRangeByIndex(1, 1).rowHeight = 35;

    // Store name
    final storeRange = summary.getRangeByName('A2:D2');
    storeRange.merge();
    storeRange.setText(storeName ?? 'تطبيق الصافي');
    storeRange.cellStyle.hAlign = HAlignType.center;
    storeRange.cellStyle.fontSize = 11;
    storeRange.cellStyle.fontColor = '#7B7890';

    // Date range
    final dateRange = summary.getRangeByName('A3:D3');
    dateRange.merge();
    dateRange.setText(
        'من ${_date(fromInclusive)}  إلى  ${_date(toInclusive)}');
    dateRange.cellStyle.hAlign = HAlignType.center;
    dateRange.cellStyle.fontSize = 11;
    dateRange.cellStyle.fontColor = '#7B7890';

    // Spacer
    var row = 5;

    // Wallet info section
    final infoTitle = summary.getRangeByName('A$row:D$row');
    infoTitle.merge();
    infoTitle.setText('معلومات المحفظة');
    _applySectionStyle(infoTitle.cellStyle);
    row++;

    void addInfoRow(String label, String value) {
      final lbl = summary.getRangeByIndex(row, 1);
      lbl.setText(label);
      _applyInfoLabelStyle(lbl.cellStyle);
      final val = summary.getRangeByName('B$row:D$row');
      val.merge();
      val.setText(value);
      _applyInfoValueStyle(val.cellStyle);
      row++;
    }

    final typeLbl = switch (account.type) {
      AccountType.cash => 'كاش',
      AccountType.bank => 'بنك',
      AccountType.wallet => 'محفظة إلكترونية',
    };

    addInfoRow('اسم المحفظة', account.name);
    addInfoRow('النوع', typeLbl);
    addInfoRow('الرصيد الابتدائي', '${_amt(account.balance)} ش');
    addInfoRow('الرصيد الفعلي', '${_amt(effectiveBalance)} ش');
    if (account.accountOwner != null && account.accountOwner!.isNotEmpty) {
      addInfoRow('صاحب الحساب', account.accountOwner!);
    }
    if (account.accountNumber != null && account.accountNumber!.isNotEmpty) {
      addInfoRow('رقم الحساب', account.accountNumber!);
    }

    row++;

    // Filter entries by date range
    final cashF = [
      for (final e in cashEntries)
        if (!e.isDeleted && _inRange(e.date, fromInclusive, toInclusive)) e,
    ]..sort((a, b) => b.date.compareTo(a.date));

    final debtF = [
      for (final t in debtTxs)
        if (!t.isDeleted && _inRange(t.date, fromInclusive, toInclusive)) t,
    ]..sort((a, b) => b.date.compareTo(a.date));

    // KPI summary
    var cashIn = 0.0, cashOut = 0.0;
    for (final e in cashF) {
      if (e.isIncome) {
        cashIn += e.amount;
      } else {
        cashOut += e.amount;
      }
    }
    var debtIn = 0.0, debtOut = 0.0;
    for (final t in debtF) {
      if (t.type == TransactionType.received) {
        debtIn += t.amount;
      } else {
        debtOut += t.amount;
      }
    }
    final totalIn = cashIn + debtIn;
    final totalOut = cashOut + debtOut;
    final net = totalIn - totalOut;

    final kpiTitle = summary.getRangeByName('A$row:D$row');
    kpiTitle.merge();
    kpiTitle.setText('ملخص الحركات في الفترة');
    _applySectionStyle(kpiTitle.cellStyle);
    row++;

    addInfoRow('إجمالي الوارد', '+${_amt(totalIn)} ش');
    summary.getRangeByName('B${row - 1}:D${row - 1}').cellStyle.fontColor =
        '#2E7D32';
    addInfoRow('إجمالي الصادر', '-${_amt(totalOut)} ش');
    summary.getRangeByName('B${row - 1}:D${row - 1}').cellStyle.fontColor =
        '#B71C1C';
    addInfoRow('الصافي', '${net >= 0 ? '+' : ''}${_amt(net)} ش');
    summary.getRangeByName('B${row - 1}:D${row - 1}').cellStyle.fontColor =
        net >= 0 ? '#2E7D32' : '#B71C1C';
    addInfoRow('عدد حركات الصندوق', '${cashF.length}');
    addInfoRow('عدد حركات الديون', '${debtF.length}');

    // ── Sheet 2: حركات الصندوق ──
    final cashSheet = workbook.worksheets.addWithName('حركات الصندوق');
    cashSheet.isRightToLeft = true;
    cashSheet.getRangeByIndex(1, 1).columnWidth = 18;
    cashSheet.getRangeByIndex(1, 2).columnWidth = 12;
    cashSheet.getRangeByIndex(1, 3).columnWidth = 35;
    cashSheet.getRangeByIndex(1, 4).columnWidth = 18;

    // Cash title
    final cashTitle = cashSheet.getRangeByName('A1:D1');
    cashTitle.merge();
    cashTitle.setText('حركات الصندوق — ${account.name}');
    _applyTitleStyle(cashTitle.cellStyle);
    cashSheet.getRangeByIndex(1, 1).rowHeight = 30;

    // Cash headers
    final cashHeaders = ['التاريخ', 'النوع', 'البيان', 'المبلغ (ش)'];
    for (var c = 0; c < cashHeaders.length; c++) {
      final cell = cashSheet.getRangeByIndex(3, c + 1);
      cell.setText(cashHeaders[c]);
      _applyHeaderStyle(cell.cellStyle);
    }

    // Cash data
    var cashRow = 4;
    if (cashF.isEmpty) {
      final emptyRange = cashSheet.getRangeByName('A$cashRow:D$cashRow');
      emptyRange.merge();
      emptyRange.setText('لا توجد حركات في هذه الفترة');
      emptyRange.cellStyle.hAlign = HAlignType.center;
      emptyRange.cellStyle.fontColor = '#7B7890';
    } else {
      for (final e in cashF) {
        final isIn = e.isIncome;
        cashSheet.getRangeByIndex(cashRow, 1).setText(_date(e.date));
        final typeCell = cashSheet.getRangeByIndex(cashRow, 2);
        typeCell.setText(isIn ? 'وارد' : 'صادر');
        if (isIn) {
          _applyGreenStyle(typeCell.cellStyle);
        } else {
          _applyRedStyle(typeCell.cellStyle);
        }
        cashSheet.getRangeByIndex(cashRow, 3).setText(e.title);
        final amtCell = cashSheet.getRangeByIndex(cashRow, 4);
        amtCell.setText('${isIn ? '+' : '-'}${_amt(e.amount)}');
        if (isIn) {
          _applyGreenStyle(amtCell.cellStyle);
        } else {
          _applyRedStyle(amtCell.cellStyle);
        }

        // Alternate row color
        if (cashRow.isOdd) {
          for (var c = 1; c <= 4; c++) {
            cashSheet.getRangeByIndex(cashRow, c).cellStyle.backColor =
                '#FAF8FD';
          }
        }
        cashRow++;
      }
    }

    // ── Sheet 3: حركات الديون ──
    final debtSheet = workbook.worksheets.addWithName('حركات الديون');
    debtSheet.isRightToLeft = true;
    debtSheet.getRangeByIndex(1, 1).columnWidth = 18;
    debtSheet.getRangeByIndex(1, 2).columnWidth = 20;
    debtSheet.getRangeByIndex(1, 3).columnWidth = 30;
    debtSheet.getRangeByIndex(1, 4).columnWidth = 14;
    debtSheet.getRangeByIndex(1, 5).columnWidth = 18;

    // Debt title
    final debtTitle = debtSheet.getRangeByName('A1:E1');
    debtTitle.merge();
    debtTitle.setText('حركات الديون — ${account.name}');
    _applyTitleStyle(debtTitle.cellStyle);
    debtSheet.getRangeByIndex(1, 1).rowHeight = 30;

    // Debt headers
    final debtHeaders = ['التاريخ', 'الجهة', 'البيان', 'النوع', 'المبلغ (ش)'];
    for (var c = 0; c < debtHeaders.length; c++) {
      final cell = debtSheet.getRangeByIndex(3, c + 1);
      cell.setText(debtHeaders[c]);
      _applyHeaderStyle(cell.cellStyle);
    }

    // Debt data
    var debtRow = 4;
    if (debtF.isEmpty) {
      final emptyRange = debtSheet.getRangeByName('A$debtRow:E$debtRow');
      emptyRange.merge();
      emptyRange.setText('لا توجد معاملات في هذه الفترة');
      emptyRange.cellStyle.hAlign = HAlignType.center;
      emptyRange.cellStyle.fontColor = '#7B7890';
    } else {
      for (final t in debtF) {
        final isGave = t.type == TransactionType.gave;
        debtSheet.getRangeByIndex(debtRow, 1).setText(_date(t.date));
        debtSheet.getRangeByIndex(debtRow, 2).setText(
          UnifiedLedgerMath.debtName(debtors, t.customerId),
        );
        debtSheet.getRangeByIndex(debtRow, 3).setText(t.note);
        final typeCell = debtSheet.getRangeByIndex(debtRow, 4);
        typeCell.setText(isGave ? 'دين جديد' : 'سداد');
        if (isGave) {
          _applyRedStyle(typeCell.cellStyle);
        } else {
          _applyGreenStyle(typeCell.cellStyle);
        }
        final amtCell = debtSheet.getRangeByIndex(debtRow, 5);
        amtCell.setText('${isGave ? '-' : '+'}${_amt(t.amount)}');
        if (isGave) {
          _applyRedStyle(amtCell.cellStyle);
        } else {
          _applyGreenStyle(amtCell.cellStyle);
        }

        if (debtRow.isOdd) {
          for (var c = 1; c <= 5; c++) {
            debtSheet.getRangeByIndex(debtRow, c).cellStyle.backColor =
                '#FAF8FD';
          }
        }
        debtRow++;
      }
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: General unified Excel report (cash + debts)
  // ─────────────────────────────────────────────────────────────────────────

  static Uint8List buildUnifiedReport({
    required DateTime fromInclusive,
    required DateTime toInclusive,
    required AppReportDebtFilterExcel filter,
    required List<CashbookEntry> cash,
    required List<TransactionUi> txs,
    required List<DebtorUi> debtors,
    String? storeName,
  }) {
    final workbook = Workbook();

    // Filter
    final cashF = [
      for (final e in cash)
        if (!e.isDeleted && _inRange(e.date, fromInclusive, toInclusive)) e,
    ]..sort((a, b) => b.date.compareTo(a.date));

    final allowedIds = <String>{};
    for (final d in debtors) {
      switch (filter) {
        case AppReportDebtFilterExcel.unifiedAll:
          allowedIds.add(d.id);
          break;
        case AppReportDebtFilterExcel.customersOnly:
          if (!d.isSupplier) allowedIds.add(d.id);
          break;
        case AppReportDebtFilterExcel.suppliersOnly:
          if (d.isSupplier) allowedIds.add(d.id);
          break;
      }
    }
    final txRange = [
      for (final t in txs)
        if (!t.isDeleted && _inRange(t.date, fromInclusive, toInclusive)) t,
    ];
    final txsF = switch (filter) {
      AppReportDebtFilterExcel.unifiedAll => txRange,
      _ => [
          for (final t in txRange)
            if (allowedIds.contains(t.customerId)) t,
        ],
    }..sort((a, b) => b.date.compareTo(a.date));

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

    final inclCash = filter == AppReportDebtFilterExcel.unifiedAll;
    final totalIn = (inclCash ? cashIn : 0) + recv;
    final totalOut = (inclCash ? cashOut : 0) + gave;
    final net = totalIn - totalOut;

    // ── Summary sheet ──
    final summary = workbook.worksheets[0];
    summary.name = 'الملخص';
    summary.isRightToLeft = true;
    summary.getRangeByIndex(1, 1).columnWidth = 25;
    summary.getRangeByIndex(1, 2).columnWidth = 30;

    final title = summary.getRangeByName('A1:B1');
    title.merge();
    title.setText(storeName ?? 'تقرير الصافي');
    _applyTitleStyle(title.cellStyle);
    summary.getRangeByIndex(1, 1).rowHeight = 35;

    final dateR = summary.getRangeByName('A2:B2');
    dateR.merge();
    dateR.setText('من ${_date(fromInclusive)}  إلى  ${_date(toInclusive)}');
    dateR.cellStyle.hAlign = HAlignType.center;
    dateR.cellStyle.fontColor = '#7B7890';

    var row = 4;
    void addRow(String label, String value, {String? color}) {
      final lbl = summary.getRangeByIndex(row, 1);
      lbl.setText(label);
      _applyInfoLabelStyle(lbl.cellStyle);
      final val = summary.getRangeByIndex(row, 2);
      val.setText(value);
      _applyInfoValueStyle(val.cellStyle);
      if (color != null) val.cellStyle.fontColor = color;
      row++;
    }

    addRow('إجمالي الوارد', '+${_amt(totalIn)} ش', color: '#2E7D32');
    addRow('إجمالي الصادر', '-${_amt(totalOut)} ش', color: '#B71C1C');
    addRow('الصافي', '${net >= 0 ? '+' : ''}${_amt(net)} ش',
        color: net >= 0 ? '#2E7D32' : '#B71C1C');
    addRow('حركات الصندوق', '${cashF.length}');
    addRow('حركات الديون', '${txsF.length}');

    // ── Cash sheet ──
    if (inclCash) {
      final cs = workbook.worksheets.addWithName('حركات الصندوق');
      cs.isRightToLeft = true;
      cs.getRangeByIndex(1, 1).columnWidth = 18;
      cs.getRangeByIndex(1, 2).columnWidth = 12;
      cs.getRangeByIndex(1, 3).columnWidth = 35;
      cs.getRangeByIndex(1, 4).columnWidth = 18;

      final hdr = ['التاريخ', 'النوع', 'البيان', 'المبلغ (ش)'];
      for (var c = 0; c < hdr.length; c++) {
        final cell = cs.getRangeByIndex(1, c + 1);
        cell.setText(hdr[c]);
        _applyHeaderStyle(cell.cellStyle);
      }
      var r = 2;
      for (final e in cashF) {
        final isIn = e.isIncome;
        cs.getRangeByIndex(r, 1).setText(_date(e.date));
        final tc = cs.getRangeByIndex(r, 2);
        tc.setText(isIn ? 'وارد' : 'صادر');
        if (isIn) {
          _applyGreenStyle(tc.cellStyle);
        } else {
          _applyRedStyle(tc.cellStyle);
        }
        cs.getRangeByIndex(r, 3).setText(e.title);
        final ac = cs.getRangeByIndex(r, 4);
        ac.setText('${isIn ? '+' : '-'}${_amt(e.amount)}');
        if (isIn) {
          _applyGreenStyle(ac.cellStyle);
        } else {
          _applyRedStyle(ac.cellStyle);
        }
        if (r.isOdd) {
          for (var c = 1; c <= 4; c++) {
            cs.getRangeByIndex(r, c).cellStyle.backColor = '#FAF8FD';
          }
        }
        r++;
      }
    }

    // ── Debt sheet ──
    final ds = workbook.worksheets.addWithName('حركات الديون');
    ds.isRightToLeft = true;
    ds.getRangeByIndex(1, 1).columnWidth = 18;
    ds.getRangeByIndex(1, 2).columnWidth = 20;
    ds.getRangeByIndex(1, 3).columnWidth = 30;
    ds.getRangeByIndex(1, 4).columnWidth = 14;
    ds.getRangeByIndex(1, 5).columnWidth = 18;

    final dHdr = ['التاريخ', 'الجهة', 'البيان', 'النوع', 'المبلغ (ش)'];
    for (var c = 0; c < dHdr.length; c++) {
      final cell = ds.getRangeByIndex(1, c + 1);
      cell.setText(dHdr[c]);
      _applyHeaderStyle(cell.cellStyle);
    }
    var dr = 2;
    for (final t in txsF) {
      final isGave = t.type == TransactionType.gave;
      ds.getRangeByIndex(dr, 1).setText(_date(t.date));
      ds.getRangeByIndex(dr, 2).setText(
        UnifiedLedgerMath.debtName(debtors, t.customerId),
      );
      ds.getRangeByIndex(dr, 3).setText(t.note);
      final tc = ds.getRangeByIndex(dr, 4);
      tc.setText(isGave ? 'دين جديد' : 'سداد');
      if (isGave) {
        _applyRedStyle(tc.cellStyle);
      } else {
        _applyGreenStyle(tc.cellStyle);
      }
      final ac = ds.getRangeByIndex(dr, 5);
      ac.setText('${isGave ? '-' : '+'}${_amt(t.amount)}');
      if (isGave) {
        _applyRedStyle(ac.cellStyle);
      } else {
        _applyGreenStyle(ac.cellStyle);
      }
      if (dr.isOdd) {
        for (var c = 1; c <= 5; c++) {
          ds.getRangeByIndex(dr, c).cellStyle.backColor = '#FAF8FD';
        }
      }
      dr++;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC: Per-client Excel report
  // ─────────────────────────────────────────────────────────────────────────

  static Uint8List buildClientReport({
    required DebtorUi client,
    required DateTime fromInclusive,
    required DateTime toInclusive,
    required List<TransactionUi> allTxs,
    String? storeName,
  }) {
    final workbook = Workbook();

    // Filter
    final txs = [
      for (final t in allTxs)
        if (t.customerId == client.id &&
            !t.isDeleted &&
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
    final net = recv - gave;

    final balance =
        double.tryParse(client.amount.replaceAll('₪', '').trim()) ?? 0.0;
    final clientType = client.isSupplier ? 'بائع جملة' : 'زبون';
    final balLabel = balance > 0
        ? 'يدين لك ${_amt(balance.abs())} ش'
        : balance < 0
            ? 'أنت مدين ${_amt(balance.abs())} ش'
            : 'لا رصيد';

    // ── Summary sheet ──
    final summary = workbook.worksheets[0];
    summary.name = 'كشف الحساب';
    summary.isRightToLeft = true;
    summary.getRangeByIndex(1, 1).columnWidth = 25;
    summary.getRangeByIndex(1, 2).columnWidth = 30;

    final title = summary.getRangeByName('A1:B1');
    title.merge();
    title.setText('كشف حساب $clientType: ${client.name}');
    _applyTitleStyle(title.cellStyle);
    summary.getRangeByIndex(1, 1).rowHeight = 35;

    final storeR = summary.getRangeByName('A2:B2');
    storeR.merge();
    storeR.setText(storeName ?? 'تطبيق الصافي');
    storeR.cellStyle.hAlign = HAlignType.center;
    storeR.cellStyle.fontColor = '#7B7890';

    final dateR = summary.getRangeByName('A3:B3');
    dateR.merge();
    dateR.setText('من ${_date(fromInclusive)}  إلى  ${_date(toInclusive)}');
    dateR.cellStyle.hAlign = HAlignType.center;
    dateR.cellStyle.fontColor = '#7B7890';

    var row = 5;

    // Client info
    final infoTitle = summary.getRangeByName('A$row:B$row');
    infoTitle.merge();
    infoTitle.setText('معلومات العميل');
    _applySectionStyle(infoTitle.cellStyle);
    row++;

    void addRow(String label, String value, {String? color}) {
      final lbl = summary.getRangeByIndex(row, 1);
      lbl.setText(label);
      _applyInfoLabelStyle(lbl.cellStyle);
      final val = summary.getRangeByIndex(row, 2);
      val.setText(value);
      _applyInfoValueStyle(val.cellStyle);
      if (color != null) {
        val.cellStyle.fontColor = color;
      }
      row++;
    }

    addRow('الاسم', client.name);
    addRow('النوع', clientType);
    if (client.phone.trim().isNotEmpty) {
      addRow('الهاتف', client.phone.trim());
    }
    addRow('الرصيد الحالي', balLabel,
        color: balance > 0 ? '#B71C1C' : (balance < 0 ? '#2E7D32' : null));

    row++;

    // KPI
    final kpiTitle = summary.getRangeByName('A$row:B$row');
    kpiTitle.merge();
    kpiTitle.setText('ملخص الفترة');
    _applySectionStyle(kpiTitle.cellStyle);
    row++;

    addRow('إجمالي السداد', '+${_amt(recv)} ش', color: '#2E7D32');
    addRow('إجمالي الديون الجديدة', '-${_amt(gave)} ش', color: '#B71C1C');
    addRow('الصافي', '${net >= 0 ? '+' : ''}${_amt(net)} ش',
        color: net >= 0 ? '#2E7D32' : '#B71C1C');
    addRow('عدد المعاملات', '${txs.length}');

    // ── Transactions sheet ──
    final ts = workbook.worksheets.addWithName('سجل المعاملات');
    ts.isRightToLeft = true;
    ts.getRangeByIndex(1, 1).columnWidth = 18;
    ts.getRangeByIndex(1, 2).columnWidth = 35;
    ts.getRangeByIndex(1, 3).columnWidth = 14;
    ts.getRangeByIndex(1, 4).columnWidth = 18;

    final tTitle = ts.getRangeByName('A1:D1');
    tTitle.merge();
    tTitle.setText('سجل معاملات — ${client.name}');
    _applyTitleStyle(tTitle.cellStyle);
    ts.getRangeByIndex(1, 1).rowHeight = 30;

    final hdr = ['التاريخ', 'البيان', 'النوع', 'المبلغ (ش)'];
    for (var c = 0; c < hdr.length; c++) {
      final cell = ts.getRangeByIndex(3, c + 1);
      cell.setText(hdr[c]);
      _applyHeaderStyle(cell.cellStyle);
    }

    var r = 4;
    if (txs.isEmpty) {
      final emptyRange = ts.getRangeByName('A$r:D$r');
      emptyRange.merge();
      emptyRange.setText('لا توجد معاملات في هذه الفترة');
      emptyRange.cellStyle.hAlign = HAlignType.center;
      emptyRange.cellStyle.fontColor = '#7B7890';
    } else {
      for (final t in txs) {
        final isGave = t.type == TransactionType.gave;
        ts.getRangeByIndex(r, 1).setText(_date(t.date));
        ts.getRangeByIndex(r, 2).setText(t.note);
        final tc = ts.getRangeByIndex(r, 3);
        tc.setText(isGave ? 'دين جديد' : 'سداد');
        if (isGave) {
          _applyRedStyle(tc.cellStyle);
        } else {
          _applyGreenStyle(tc.cellStyle);
        }
        final ac = ts.getRangeByIndex(r, 4);
        ac.setText('${isGave ? '-' : '+'}${_amt(t.amount)}');
        if (isGave) {
          _applyRedStyle(ac.cellStyle);
        } else {
          _applyGreenStyle(ac.cellStyle);
        }
        if (r.isOdd) {
          for (var c = 1; c <= 4; c++) {
            ts.getRangeByIndex(r, c).cellStyle.backColor = '#FAF8FD';
          }
        }
        r++;
      }
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  }
}

/// نسخة مطابقة لـ [AppReportDebtFilter] لتجنّب اقتران ملفي PDF و Excel.
enum AppReportDebtFilterExcel { unifiedAll, customersOnly, suppliersOnly }

