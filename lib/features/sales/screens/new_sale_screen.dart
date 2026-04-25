import 'package:flutter/material.dart';

import 'sales_screen.dart';

/// شاشة بيع مخصصة للإنتاج: عنوان واضح ونفس واجهة نقطة البيع
class NewSaleScreen extends StatelessWidget {
  const NewSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيع جديد'),
      ),
      body: const SalesScreen(bottomInset: 20),
    );
  }
}
