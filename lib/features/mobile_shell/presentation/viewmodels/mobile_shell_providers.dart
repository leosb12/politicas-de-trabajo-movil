import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mobile_shell_state.dart';
import 'mobile_shell_view_model.dart';

final mobileShellViewModelProvider =
    StateNotifierProvider<MobileShellViewModel, MobileShellState>((ref) {
  return MobileShellViewModel();
});