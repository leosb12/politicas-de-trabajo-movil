import '../../dominio/modelos/contexto_guia_usuario_movil.dart';
import '../../dominio/modelos/respuesta_guia_usuario_movil.dart';
import '../../dominio/modelos/solicitud_guia_usuario_movil.dart';
import '../../dominio/servicios/clasificador_intencion_guia_usuario_movil.dart';

class RespaldoGuiaUsuarioMovilLocal {
  RespaldoGuiaUsuarioMovilLocal(this._clasificador);

  final ClasificadorIntencionGuiaUsuarioMovil _clasificador;

  RespuestaGuiaUsuarioMovil construir(SolicitudGuiaUsuarioMovil solicitud) {
    final ContextoGuiaUsuarioMovil contexto = solicitud.contexto;
    final String intencion = _clasificador.resolver(
      pregunta: solicitud.pregunta,
      pantalla: solicitud.pantalla,
    );
    final String estadoExplicado = _construirEstadoExplicado(
      contexto.estadoTramite,
    );
    final String progresoExplicado = _construirProgresoExplicado(
      contexto.resumenProgreso,
    );
    final List<String> documentosFaltantes = _limpiarLista(
      contexto.documentosFaltantes,
    );
    final List<String> proximosPasos = _limpiarLista(contexto.proximosPasos);
    final List<AccionSugeridaGuiaUsuarioMovil> accionesSugeridas =
        _construirAccionesSugeridas(contexto.accionesDisponibles);
    final String severidad = _construirSeveridad(contexto);

    if (intencion == 'EXPLICAR_PANTALLA' ||
        intencion == 'QUE_PUEDO_HACER_AQUI' ||
        intencion == 'GUIA_PASO_A_PASO') {
      return RespuestaGuiaUsuarioMovil(
        respuesta: _construirRespuestaPantalla(solicitud.pantalla),
        pasos: _construirPasosPantalla(solicitud.pantalla),
        estadoExplicado: estadoExplicado,
        progresoExplicado: progresoExplicado,
        documentosFaltantes: documentosFaltantes,
        proximosPasos: proximosPasos,
        accionesSugeridas: accionesSugeridas,
        severidad: severidad,
        intencion: intencion,
        fuente: 'GUIA_LOCAL',
      );
    }

    if (intencion == 'AYUDA_INICIAR_TRAMITE') {
      return RespuestaGuiaUsuarioMovil(
        respuesta:
            'Si esta pantalla lo permite, puedes iniciar un tramite y luego revisar su avance desde tu lista de solicitudes.',
        pasos: const <String>[
          'Busca un tramite disponible para iniciar.',
          'Completa la solicitud si el sistema te lo pide.',
          'Despues revisa el estado desde tu lista de tramites.',
        ],
        accionesSugeridas: accionesSugeridas,
        severidad: 'INFO',
        intencion: intencion,
        fuente: 'GUIA_LOCAL',
      );
    }

    if (intencion == 'AYUDA_SUBIR_DOCUMENTO' ||
        intencion == 'EXPLICAR_DOCUMENTOS_FALTANTES') {
      return RespuestaGuiaUsuarioMovil(
        respuesta: _construirRespuestaDocumentos(documentosFaltantes),
        pasos: _construirPasosDocumentos(documentosFaltantes),
        documentosFaltantes: documentosFaltantes,
        accionesSugeridas: accionesSugeridas,
        severidad: documentosFaltantes.isEmpty ? 'INFO' : 'WARNING',
        intencion: intencion,
        fuente: 'GUIA_LOCAL',
      );
    }

    if (intencion == 'EXPLICAR_ESTADO_TRAMITE') {
      return RespuestaGuiaUsuarioMovil(
        respuesta: _construirRespuestaEstado(contexto, estadoExplicado),
        pasos: const <String>[
          'Revisa la etapa actual del tramite.',
          'Confirma si tienes observaciones o documentos pendientes.',
          'Consulta que paso sigue despues de la revision actual.',
        ],
        estadoExplicado: estadoExplicado,
        progresoExplicado: progresoExplicado,
        documentosFaltantes: documentosFaltantes,
        proximosPasos: proximosPasos,
        accionesSugeridas: accionesSugeridas,
        severidad: severidad,
        intencion: intencion,
        fuente: 'GUIA_LOCAL',
      );
    }

    if (intencion == 'EXPLICAR_PROGRESO_TRAMITE' ||
        intencion == 'EXPLICAR_HISTORIAL') {
      return RespuestaGuiaUsuarioMovil(
        respuesta: _construirRespuestaProgreso(progresoExplicado),
        pasos: const <String>[
          'Revisa cuantos pasos ya se completaron.',
          'Ubica la etapa actual de la solicitud.',
          'Consulta los proximos pasos para saber que falta.',
        ],
        estadoExplicado: estadoExplicado,
        progresoExplicado: progresoExplicado,
        proximosPasos: proximosPasos,
        accionesSugeridas: accionesSugeridas,
        severidad: severidad,
        intencion: intencion,
        fuente: 'GUIA_LOCAL',
      );
    }

    if (intencion == 'EXPLICAR_ETAPA_ACTUAL') {
      return RespuestaGuiaUsuarioMovil(
        respuesta: _construirRespuestaEtapaActual(contexto),
        pasos: const <String>[
          'Revisa el area actual del tramite.',
          'Confirma si esa etapa requiere un documento o correccion adicional.',
          'Consulta el siguiente paso del flujo.',
        ],
        estadoExplicado: estadoExplicado,
        proximosPasos: proximosPasos,
        accionesSugeridas: accionesSugeridas,
        severidad: severidad,
        intencion: intencion,
        fuente: 'GUIA_LOCAL',
      );
    }

    if (intencion == 'EXPLICAR_OBSERVACIONES' ||
        intencion == 'EXPLICAR_RECHAZO') {
      return RespuestaGuiaUsuarioMovil(
        respuesta: _construirRespuestaObservaciones(contexto),
        pasos: const <String>[
          'Revisa el motivo informado en observaciones.',
          'Corrige o adjunta lo que te solicitaron.',
          'Vuelve a consultar el estado cuando termines.',
        ],
        estadoExplicado: estadoExplicado,
        documentosFaltantes: documentosFaltantes,
        accionesSugeridas: accionesSugeridas,
        severidad: intencion == 'EXPLICAR_RECHAZO' ? 'ERROR' : severidad,
        intencion: intencion,
        fuente: 'GUIA_LOCAL',
      );
    }

    if (intencion == 'EXPLICAR_PROXIMO_PASO') {
      return RespuestaGuiaUsuarioMovil(
        respuesta: _construirRespuestaSiguientePaso(proximosPasos),
        pasos: const <String>[
          'Confirma si la etapa actual ya esta completa.',
          'Revisa si queda alguna observacion pendiente.',
          'Consulta el siguiente paso esperado del flujo.',
        ],
        progresoExplicado: progresoExplicado,
        proximosPasos: proximosPasos,
        accionesSugeridas: accionesSugeridas,
        severidad: 'INFO',
        intencion: intencion,
        fuente: 'GUIA_LOCAL',
      );
    }

    return RespuestaGuiaUsuarioMovil(
      respuesta: _construirRespuestaGeneral(solicitud.pantalla),
      pasos: _construirPasosGenerales(solicitud.pantalla),
      estadoExplicado: estadoExplicado,
      progresoExplicado: progresoExplicado,
      documentosFaltantes: documentosFaltantes,
      proximosPasos: proximosPasos,
      accionesSugeridas: accionesSugeridas,
      severidad: severidad,
      intencion: intencion,
      fuente: 'GUIA_LOCAL',
    );
  }

  String _construirRespuestaPantalla(String pantalla) {
    switch (pantalla.trim().toUpperCase()) {
      case PantallasGuiaUsuarioMovil.inicioUsuario:
        return 'Estas en el inicio del usuario movil. Aqui puedes iniciar tramites si el sistema lo permite y revisar accesos a tus solicitudes.';
      case PantallasGuiaUsuarioMovil.listaTramites:
        return 'Estas en la lista de tramites. Aqui puedes revisar tus solicitudes y entrar al detalle para consultar su estado.';
      case PantallasGuiaUsuarioMovil.detalleTramite:
      case PantallasGuiaUsuarioMovil.estadoTramite:
        return 'Estas viendo el detalle del tramite. Aqui puedes entender el estado actual, la etapa en curso y lo que falta para avanzar.';
      case PantallasGuiaUsuarioMovil.formularioSolicitud:
        return 'Estas en un formulario de solicitud. Aqui debes completar la informacion requerida y adjuntar documentos si el sistema lo solicita.';
      case PantallasGuiaUsuarioMovil.perfilUsuario:
        return 'Estas en tu perfil. Aqui puedes revisar tus datos personales y la informacion basica usada en tus tramites.';
      case PantallasGuiaUsuarioMovil.notificaciones:
        return 'Estas en notificaciones. Aqui puedes revisar avisos sobre cambios o avances en tus tramites.';
      default:
        return 'Puedo ayudarte a entender la pantalla actual, explicar el estado de tus tramites y decirte que falta para avanzar.';
    }
  }

  List<String> _construirPasosPantalla(String pantalla) {
    switch (pantalla.trim().toUpperCase()) {
      case PantallasGuiaUsuarioMovil.listaTramites:
        return const <String>[
          'Busca el tramite que quieres revisar.',
          'Entra al detalle para ver estado y etapa actual.',
          'Si hay observaciones, revisa que te falta para avanzar.',
        ];
      case PantallasGuiaUsuarioMovil.detalleTramite:
      case PantallasGuiaUsuarioMovil.estadoTramite:
        return const <String>[
          'Revisa el estado actual de la solicitud.',
          'Confirma en que etapa se encuentra tu tramite.',
          'Consulta si tienes documentos u observaciones pendientes.',
        ];
      default:
        return const <String>[
          'Revisa la informacion principal de esta pantalla.',
          'Consulta que acciones tienes disponibles.',
          'Pregunta por el estado o el siguiente paso si necesitas mas detalle.',
        ];
    }
  }

  String _construirRespuestaEstado(
    ContextoGuiaUsuarioMovil contexto,
    String estadoExplicado,
  ) {
    final String etapa = contexto.etapaActual?.nombre.trim() ?? '';
    if (etapa.isNotEmpty) {
      return 'Tu tramite esta en $etapa. ${_textoSeguro(estadoExplicado, '')}'
          .trim();
    }
    return _textoSeguro(
      estadoExplicado,
      'Tu tramite tiene un estado registrado y puedo ayudarte a interpretarlo.',
    );
  }

  String _construirRespuestaProgreso(String progresoExplicado) {
    if (progresoExplicado.trim().isNotEmpty) {
      return progresoExplicado;
    }
    return 'Puedo orientarte sobre las etapas completadas, la etapa actual y lo que falta para cerrar el tramite.';
  }

  String _construirRespuestaEtapaActual(ContextoGuiaUsuarioMovil contexto) {
    final EtapaActualGuiaUsuarioMovil? etapaActual = contexto.etapaActual;
    if (etapaActual == null || etapaActual.nombre.trim().isEmpty) {
      return 'No tengo una etapa actual detallada, pero si quieres puedo explicarte el estado general del tramite.';
    }

    final StringBuffer respuesta = StringBuffer(
      'Tu solicitud esta en la etapa ${etapaActual.nombre}.',
    );
    if (etapaActual.descripcion.trim().isNotEmpty) {
      respuesta.write(' ${etapaActual.descripcion.trim()}');
    }
    if (etapaActual.departamento.trim().isNotEmpty) {
      respuesta.write(' El area actual es ${etapaActual.departamento.trim()}.');
    }
    return respuesta.toString();
  }

  String _construirRespuestaDocumentos(List<String> documentosFaltantes) {
    if (documentosFaltantes.isEmpty) {
      return 'Por ahora no veo documentos faltantes en el contexto disponible del tramite.';
    }
    return 'Todavia faltan estos documentos: ${documentosFaltantes.join(', ')}.';
  }

  List<String> _construirPasosDocumentos(List<String> documentosFaltantes) {
    if (documentosFaltantes.isEmpty) {
      return const <String>[
        'Si esperabas un documento pendiente, revisa observaciones y detalle del tramite.',
        'Vuelve a consultar el estado despues de una actualizacion del sistema.',
      ];
    }

    return const <String>[
      'Revisa cada documento solicitado.',
      'Sube o corrige solo los documentos faltantes.',
      'Vuelve a consultar el estado despues del envio.',
    ];
  }

  String _construirRespuestaObservaciones(ContextoGuiaUsuarioMovil contexto) {
    final List<String> observaciones = _limpiarLista(contexto.observaciones);
    if (observaciones.isNotEmpty) {
      return 'Tu tramite tiene observaciones. La principal es: ${observaciones.first}';
    }
    return 'No veo una observacion textual disponible, pero si el tramite esta detenido conviene revisar detalle e historial reciente.';
  }

  String _construirRespuestaSiguientePaso(List<String> proximosPasos) {
    if (proximosPasos.isEmpty) {
      return 'Todavia no tengo un siguiente paso detallado, pero puedo explicarte el estado y la etapa actual del tramite.';
    }
    return 'El siguiente paso esperado de tu tramite es ${proximosPasos.first}.';
  }

  String _construirRespuestaGeneral(String pantalla) {
    switch (pantalla.trim().toUpperCase()) {
      case PantallasGuiaUsuarioMovil.listaTramites:
        return 'Puedo ayudarte a entender tu lista de tramites, explicarte estados y decirte que hacer cuando una solicitud este observada o detenida.';
      case PantallasGuiaUsuarioMovil.detalleTramite:
      case PantallasGuiaUsuarioMovil.estadoTramite:
        return 'Puedo explicarte en que estado va tu tramite, en que etapa esta y que falta para avanzar.';
      default:
        return 'Puedo ayudarte a entender la pantalla actual, iniciar tramites si el sistema lo permite y explicar el estado de tus solicitudes.';
    }
  }

  List<String> _construirPasosGenerales(String pantalla) {
    switch (pantalla.trim().toUpperCase()) {
      case PantallasGuiaUsuarioMovil.detalleTramite:
      case PantallasGuiaUsuarioMovil.estadoTramite:
        return const <String>[
          'Preguntame que significa el estado actual.',
          'Preguntame en que etapa va tu solicitud.',
          'Preguntame que falta o que pasa despues.',
        ];
      default:
        return const <String>[
          'Preguntame que puedes hacer en esta pantalla.',
          'Preguntame como iniciar un tramite o como revisar uno ya creado.',
        ];
    }
  }

  String _construirEstadoExplicado(String estadoTramite) {
    switch (estadoTramite.trim().toUpperCase()) {
      case 'EN_PROCESO':
        return 'EN_PROCESO significa que tu tramite todavia esta siendo revisado.';
      case 'DETENIDO':
        return 'DETENIDO significa que el tramite no puede avanzar por ahora.';
      case 'RECHAZADO':
        return 'RECHAZADO significa que la solicitud no pudo continuar con la informacion actual.';
      case 'FINALIZADO':
      case 'FINALIZADA':
        return 'FINALIZADO significa que el tramite ya termino.';
      case 'CANCELADO':
        return 'CANCELADO significa que el tramite se cerro sin continuar.';
      default:
        return estadoTramite.trim().isEmpty
            ? ''
            : 'El estado actual informado es ${estadoTramite.trim()}.';
    }
  }

  String _construirProgresoExplicado(ResumenProgresoGuiaUsuarioMovil? resumen) {
    if (resumen == null) {
      return '';
    }

    final int total = resumen.pasosCompletados + resumen.pasosPendientes;
    final List<String> partes = <String>[];
    if (total > 0) {
      partes.add(
        'Llevas ${resumen.pasosCompletados} de $total etapas completadas.',
      );
    }
    if (resumen.pasoActual.trim().isNotEmpty) {
      partes.add('La etapa actual es ${resumen.pasoActual.trim()}.');
    }
    if (resumen.porcentajeAvance > 0) {
      partes.add('El avance estimado es ${resumen.porcentajeAvance}%.');
    }
    return partes.join(' ');
  }

  List<AccionSugeridaGuiaUsuarioMovil> _construirAccionesSugeridas(
    List<String> accionesDisponibles,
  ) {
    final Set<String> acciones = accionesDisponibles
        .map((String accion) => accion.trim().toUpperCase())
        .where((String accion) => accion.isNotEmpty)
        .toSet();

    final List<AccionSugeridaGuiaUsuarioMovil> sugeridas =
        <AccionSugeridaGuiaUsuarioMovil>[];
    _agregarAccion(sugeridas, acciones, 'SUBIR_DOCUMENTO', 'Subir documento');
    _agregarAccion(
      sugeridas,
      acciones,
      'VER_OBSERVACIONES',
      'Ver observaciones',
    );
    _agregarAccion(sugeridas, acciones, 'CONSULTAR_ESTADO', 'Consultar estado');
    _agregarAccion(sugeridas, acciones, 'VER_HISTORIAL', 'Ver historial');
    _agregarAccion(
      sugeridas,
      acciones,
      'VER_DETALLE_TRAMITE',
      'Ver detalle del tramite',
    );
    _agregarAccion(sugeridas, acciones, 'INICIAR_TRAMITE', 'Iniciar tramite');
    return sugeridas.take(5).toList(growable: false);
  }

  void _agregarAccion(
    List<AccionSugeridaGuiaUsuarioMovil> sugeridas,
    Set<String> accionesDisponibles,
    String accion,
    String etiqueta,
  ) {
    if (!accionesDisponibles.contains(accion)) {
      return;
    }
    sugeridas.add(
      AccionSugeridaGuiaUsuarioMovil(accion: accion, etiqueta: etiqueta),
    );
  }

  String _construirSeveridad(ContextoGuiaUsuarioMovil contexto) {
    final String estado = contexto.estadoTramite.trim().toUpperCase();
    if (estado == 'RECHAZADO' || estado == 'CANCELADO') {
      return 'ERROR';
    }
    if (_limpiarLista(contexto.documentosFaltantes).isNotEmpty ||
        _limpiarLista(contexto.observaciones).isNotEmpty ||
        estado == 'DETENIDO') {
      return 'WARNING';
    }
    if (estado == 'FINALIZADO' || estado == 'FINALIZADA') {
      return 'SUCCESS';
    }
    return 'INFO';
  }

  List<String> _limpiarLista(List<String> valores) {
    return valores
        .map((String valor) => valor.trim())
        .where((String valor) => valor.isNotEmpty)
        .take(5)
        .toList(growable: false);
  }

  String _textoSeguro(String valor, String respaldo) {
    return valor.trim().isNotEmpty ? valor.trim() : respaldo;
  }
}
