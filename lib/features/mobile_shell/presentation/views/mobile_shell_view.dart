import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../guia_usuario_movil/dominio/modelos/contexto_guia_usuario_movil.dart';
import '../../../guia_usuario_movil/presentacion/widgets/boton_guia_usuario_movil.dart';
import '../viewmodels/mobile_shell_providers.dart';
import '../widgets/mobile_bottom_nav_bar.dart';
import 'iniciar_tramite_view.dart';
import 'mis_tramites_view.dart';
import 'perfil_view.dart';

class MobileShellView extends ConsumerStatefulWidget {
  const MobileShellView({super.key});

  @override
  ConsumerState<MobileShellView> createState() => _MobileShellViewState();
}

class _MobileShellViewState extends ConsumerState<MobileShellView> {
  final Set<int> _loadedTabs = <int>{0};

  @override
  Widget build(BuildContext context) {
    final shellState = ref.watch(mobileShellViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    _loadedTabs.add(shellState.currentIndex);

    final List<Widget> pages = <Widget>[
      _loadedTabs.contains(0) ? const IniciarTramiteView() : const SizedBox(),
      _loadedTabs.contains(1) ? const MisTramitesView() : const SizedBox(),
      _loadedTabs.contains(2) ? const PerfilView() : const SizedBox(),
    ];

    final List<String> titles = <String>[
      'Iniciar tramite',
      'Mis tramites',
      'Perfil',
    ];
    final String usuarioId = authState.authenticatedUser?.id.trim() ?? '';
    final String nombreUsuario =
        authState.authenticatedUser?.nombre.trim() ?? '';
    final _ConfiguracionGuiaShell configuracionGuia = _configuracionGuia(
      shellState.currentIndex,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[shellState.currentIndex]),
        centerTitle: false,
      ),
      body: SafeArea(
        child: IndexedStack(index: shellState.currentIndex, children: pages),
      ),
      floatingActionButton: BotonGuiaUsuarioMovil(
        heroTag: 'guia_shell_${shellState.currentIndex}',
        usuarioId: usuarioId,
        nombreUsuario: nombreUsuario,
        pantalla: configuracionGuia.pantalla,
        contexto: ContextoGuiaUsuarioMovil(
          accionesDisponibles: configuracionGuia.accionesDisponibles,
        ),
        preguntasSugeridas: configuracionGuia.preguntasSugeridas,
      ),
      bottomNavigationBar: MobileBottomNavBar(
        currentIndex: shellState.currentIndex,
        onTap: (int index) {
          ref.read(mobileShellViewModelProvider.notifier).selectTab(index);
        },
      ),
    );
  }

  _ConfiguracionGuiaShell _configuracionGuia(int index) {
    switch (index) {
      case 0:
        return const _ConfiguracionGuiaShell(
          pantalla: PantallasGuiaUsuarioMovil.inicioUsuario,
          accionesDisponibles: <String>['INICIAR_TRAMITE'],
          preguntasSugeridas: <String>[
            '¿Qué puedo hacer aquí?',
            '¿Cómo inicio un trámite?',
            '¿Qué pasa después de iniciar una solicitud?',
          ],
        );
      case 1:
        return const _ConfiguracionGuiaShell(
          pantalla: PantallasGuiaUsuarioMovil.listaTramites,
          accionesDisponibles: <String>[
            'CONSULTAR_ESTADO',
            'VER_HISTORIAL',
            'VER_DETALLE_TRAMITE',
          ],
          preguntasSugeridas: <String>[
            '¿Qué puedo hacer aquí?',
            '¿Cómo reviso el estado de un trámite?',
            '¿Qué significa cada estado?',
          ],
        );
      case 2:
      default:
        return const _ConfiguracionGuiaShell(
          pantalla: PantallasGuiaUsuarioMovil.perfilUsuario,
          preguntasSugeridas: <String>[
            '¿Qué puedo hacer aquí?',
            '¿Para qué sirve mi perfil?',
            '¿Cómo se usa esta información en mis trámites?',
          ],
        );
    }
  }
}

class _ConfiguracionGuiaShell {
  const _ConfiguracionGuiaShell({
    required this.pantalla,
    this.accionesDisponibles = const <String>[],
    this.preguntasSugeridas = const <String>[],
  });

  final String pantalla;
  final List<String> accionesDisponibles;
  final List<String> preguntasSugeridas;
}
