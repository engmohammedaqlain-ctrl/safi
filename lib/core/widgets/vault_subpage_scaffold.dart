import 'package:flutter/material.dart';

/// هيكل قياسي للصفحات الفرعية: AppBar بعنوان + جسم قابل للتمرير.
class VaultSubpageScaffold extends StatelessWidget {
  const VaultSubpageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: body,
    );
  }
}
