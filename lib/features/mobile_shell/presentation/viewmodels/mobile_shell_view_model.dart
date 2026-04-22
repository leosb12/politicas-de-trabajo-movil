import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mobile_shell_state.dart';

class MobileShellViewModel extends StateNotifier<MobileShellState> {
  MobileShellViewModel() : super(MobileShellState.initial());

  void selectTab(int index) {
    if (index == state.currentIndex) {
      return;
    }

    state = state.copyWith(currentIndex: index);
  }
}