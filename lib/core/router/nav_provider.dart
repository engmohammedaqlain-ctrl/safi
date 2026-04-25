import 'package:flutter_riverpod/flutter_riverpod.dart';

/// تبويب الشريط السفلي: 0=الرئيسية، 1=مبيعات، 2=مخزون، 3=ديون، 4=تقارير
class NavIndex extends Notifier<int> {
  @override
  int build() => 0;

  void goTo(int index) {
    if (index < 0 || index > 4) return;
    state = index;
  }
}

final navIndexProvider = NotifierProvider<NavIndex, int>(NavIndex.new);
