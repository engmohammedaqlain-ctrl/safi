import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/debts_ui_provider.dart';
import '../widgets/debt_transaction_receipt_card.dart';

/// يُنشئ صورة إيصال كما في شاشة النجاح ويشاركها، مع إرفاق الصورة الأصلية للمعاملة إن وُجدت.
Future<void> shareDebtTransactionReceipt({
  required BuildContext context,
  required String customerName,
  required double amount,
  required TransactionType type,
  required DateTime date,
  required String counterpartyLabel,
  String? paymentMethod,
  String? note,
  String? attachmentPath,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final originBox = context.findRenderObject() as RenderBox?;
  final rect =
      originBox != null ? originBox.localToGlobal(Offset.zero) & originBox.size : null;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );

  Uint8List? png;
  try {
    png = await _captureReceiptPng(
      context: context,
      receipt: DebtTransactionReceiptCard(
        customerName: customerName,
        amount: amount,
        type: type,
        date: date,
        counterpartyLabel: counterpartyLabel,
        paymentMethod: paymentMethod,
        note: note,
      ),
    );
  } finally {
    navigator.pop();
  }

  if (!context.mounted) return;

  if (png == null || png.isEmpty) {
    await SharePlus.instance.share(
      ShareParams(
        text: _shareTextFallback(
          customerName: customerName,
          amount: amount,
          type: type,
          date: date,
          paymentMethod: paymentMethod,
          note: note,
        ),
        subject: 'معاملة — الصافي',
        sharePositionOrigin: rect,
      ),
    );
    return;
  }

  final files = <XFile>[
    XFile.fromData(
      png,
      mimeType: 'image/png',
      name: 'safi-receipt.png',
    ),
  ];

  if (attachmentPath != null &&
      attachmentPath.isNotEmpty &&
      !kIsWeb &&
      await File(attachmentPath).exists()) {
    files.add(XFile(attachmentPath));
  }

  await SharePlus.instance.share(
    ShareParams(
      text: 'معاملة من تطبيق الصافي',
      files: files,
      sharePositionOrigin: rect,
    ),
  );
}

Future<Uint8List?> _captureReceiptPng({
  required BuildContext context,
  required Widget receipt,
}) async {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return null;

  final key = GlobalKey();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: -10000,
      top: 0,
      child: Material(
        color: const Color(0xFFF5F5F8),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 360,
              child: receipt,
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(const Duration(milliseconds: 140));

  Uint8List? result;
  try {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      result = byteData?.buffer.asUint8List();
      image.dispose();
    }
  } finally {
    entry.remove();
  }
  return result;
}

String _shareTextFallback({
  required String customerName,
  required double amount,
  required TransactionType type,
  required DateTime date,
  String? paymentMethod,
  String? note,
}) {
  final isGave = type == TransactionType.gave;
  final label = isGave ? 'دين جديد' : 'سداد';
  final sign = isGave ? '+' : '-';
  final buf = StringBuffer()
    ..writeln(customerName)
    ..writeln('$label: $sign${amount.toStringAsFixed(2)} ₪')
    ..writeln(
      '${formatReceiptDate(date)} ${formatReceiptTime(date)}',
    );
  if (paymentMethod != null && paymentMethod.isNotEmpty) {
    buf.writeln('وسيلة الدفع: $paymentMethod');
  }
  if (note != null && note.isNotEmpty) {
    buf.writeln(note);
  }
  buf.writeln('الصافي');
  return buf.toString();
}
