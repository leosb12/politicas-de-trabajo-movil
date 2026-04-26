import 'package:flutter/material.dart';

import '../../dominio/modelos/contexto_guia_usuario_movil.dart';
import 'panel_guia_usuario_movil.dart';

class BotonGuiaUsuarioMovil extends StatelessWidget {
  const BotonGuiaUsuarioMovil({
    super.key,
    required this.usuarioId,
    required this.pantalla,
    required this.contexto,
    this.nombreUsuario = '',
    this.preguntasSugeridas = const <String>[],
    this.heroTag,
  });

  final String usuarioId;
  final String nombreUsuario;
  final String pantalla;
  final ContextoGuiaUsuarioMovil contexto;
  final List<String> preguntasSugeridas;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag ?? 'guia_usuario_movil_$pantalla',
      onPressed: () => _abrirPanel(context),
      tooltip: 'Abrir guia',
      icon: const Icon(Icons.support_agent_rounded),
      label: const Text('Guia'),
    );
  }

  Future<void> _abrirPanel(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return PanelGuiaUsuarioMovil(
          usuarioId: usuarioId,
          nombreUsuario: nombreUsuario,
          pantalla: pantalla,
          contexto: contexto,
          preguntasSugeridas: preguntasSugeridas,
        );
      },
    );
  }
}
