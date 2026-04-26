import 'package:flutter_riverpod/flutter_riverpod.dart';

/// تبويب الشريط السفلي: 0=ديون، 1=كاشير، 2=المزيد
class NavIndex extends Notifier<int> {
  @override
  int build() => 0;

  void goTo(int index) {
    if (index < 0 || index > 2) return;
    state = index;
  }
}

final navIndexProvider = NotifierProvider<NavIndex, int>(NavIndex.new);
