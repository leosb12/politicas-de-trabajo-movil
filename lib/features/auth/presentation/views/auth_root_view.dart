import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/auth_providers.dart';
import 'login_view.dart';
import 'mobile_home_view.dart';

class AuthRootView extends ConsumerWidget {
  const AuthRootView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authViewModelProvider);

    if (state.isCheckingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.isAuthenticated) {
      return const MobileHomeView();
    }

    return const LoginView();
  }
}
