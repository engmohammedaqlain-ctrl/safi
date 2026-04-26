import 'package:flutter/material.dart';

import 'sales_pos_catalog.dart';

/// شاشة بيع: شبكة المنتجات (لوحة دفتر النقدية تبقى في التبويب الرئيسي)
class NewSaleScreen extends StatelessWidget {
  const NewSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيع جديد'),
      ),
      body: const SalesPosCatalog(bottomInset: 20),
    );
  }
}
