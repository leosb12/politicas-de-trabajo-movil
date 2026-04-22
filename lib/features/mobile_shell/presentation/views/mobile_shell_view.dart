import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/mobile_shell_providers.dart';
import '../widgets/mobile_bottom_nav_bar.dart';
import 'iniciar_tramite_view.dart';
import 'mis_tramites_view.dart';
import 'perfil_view.dart';

class MobileShellView extends ConsumerWidget {
  const MobileShellView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shellState = ref.watch(mobileShellViewModelProvider);

    final List<Widget> pages = <Widget>[
      const IniciarTramiteView(),
      const MisTramitesView(),
      const PerfilView(),
    ];

    final List<String> titles = <String>[
      'Iniciar trámite',
      'Mis trámites',
      'Perfil',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[shellState.currentIndex]),
        centerTitle: false,
      ),
      body: SafeArea(
        child: IndexedStack(index: shellState.currentIndex, children: pages),
      ),
      bottomNavigationBar: MobileBottomNavBar(
        currentIndex: shellState.currentIndex,
        onTap: (int index) {
          ref.read(mobileShellViewModelProvider.notifier).selectTab(index);
        },
      ),
    );
  }
}
