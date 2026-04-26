class PantallasGuiaUsuarioMovil {
  const PantallasGuiaUsuarioMovil._();

  static const String inicioUsuario = 'INICIO_USUARIO';
  static const String listaTramites = 'LISTA_TRAMITES';
  static const String detalleTramite = 'DETALLE_TRAMITE';
  static const String estadoTramite = 'ESTADO_TRAMITE';
  static const String formularioSolicitud = 'FORMULARIO_SOLICITUD';
  static const String perfilUsuario = 'PERFIL_USUARIO';
  static const String notificaciones = 'NOTIFICACIONES';
}

class EtapaActualGuiaUsuarioMovil {
  const EtapaActualGuiaUsuarioMovil({
    this.identificador = '',
    this.nombre = '',
    this.descripcion = '',
    this.departamento = '',
    this.responsable = '',
  });

  final String identificador;
  final String nombre;
  final String descripcion;
  final String departamento;
  final String responsable;

  bool get estaVacia {
    return identificador.trim().isEmpty &&
        nombre.trim().isEmpty &&
        descripcion.trim().isEmpty &&
        departamento.trim().isEmpty &&
        responsable.trim().isEmpty;
  }

  Map<String, dynamic> aJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    _agregarTextoSiExiste(json, 'id', identificador);
    _agregarTextoSiExiste(json, 'nombre', nombre);
    _agregarTextoSiExiste(json, 'descripcion', descripcion);
    _agregarTextoSiExiste(json, 'departamento', departamento);
    _agregarTextoSiExiste(json, 'responsable', responsable);
    return json;
  }
}

class ResumenProgresoGuiaUsuarioMovil {
  const ResumenProgresoGuiaUsuarioMovil({
    this.pasosCompletados = 0,
    this.pasoActual = '',
    this.pasosPendientes = 0,
    this.porcentajeAvance = 0,
  });

  final int pasosCompletados;
  final String pasoActual;
  final int pasosPendientes;
  final int porcentajeAvance;

  bool get estaVacio {
    return pasosCompletados <= 0 &&
        pasosPendientes <= 0 &&
        porcentajeAvance <= 0 &&
        pasoActual.trim().isEmpty;
  }

  Map<String, dynamic> aJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (pasosCompletados > 0) {
      json['pasosCompletados'] = pasosCompletados;
    }
    _agregarTextoSiExiste(json, 'pasoActual', pasoActual);
    if (pasosPendientes > 0) {
      json['pasosPendientes'] = pasosPendientes;
    }
    if (porcentajeAvance > 0) {
      json['porcentajeAvance'] = porcentajeAvance;
    }
    return json;
  }
}

class HistorialGuiaUsuarioMovil {
  const HistorialGuiaUsuarioMovil({
    this.etapa = '',
    this.estado = '',
    this.fecha = '',
    this.detalle = '',
    this.responsable = '',
  });

  final String etapa;
  final String estado;
  final String fecha;
  final String detalle;
  final String responsable;

  bool get estaVacio {
    return etapa.trim().isEmpty &&
        estado.trim().isEmpty &&
        fecha.trim().isEmpty &&
        detalle.trim().isEmpty &&
        responsable.trim().isEmpty;
  }

  Map<String, dynamic> aJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    _agregarTextoSiExiste(json, 'etapa', etapa);
    _agregarTextoSiExiste(json, 'estado', estado);
    _agregarTextoSiExiste(json, 'fecha', fecha);
    _agregarTextoSiExiste(json, 'detalle', detalle);
    _agregarTextoSiExiste(json, 'responsable', responsable);
    return json;
  }
}

class ContextoGuiaUsuarioMovil {
  const ContextoGuiaUsuarioMovil({
    this.tramiteId = '',
    this.politicaId = '',
    this.nombrePolitica = '',
    this.estadoTramite = '',
    this.etapaActual,
    this.resumenProgreso,
    this.historial = const <HistorialGuiaUsuarioMovil>[],
    this.documentosFaltantes = const <String>[],
    this.observaciones = const <String>[],
    this.proximosPasos = const <String>[],
    this.accionesDisponibles = const <String>[],
  });

  final String tramiteId;
  final String politicaId;
  final String nombrePolitica;
  final String estadoTramite;
  final EtapaActualGuiaUsuarioMovil? etapaActual;
  final ResumenProgresoGuiaUsuarioMovil? resumenProgreso;
  final List<HistorialGuiaUsuarioMovil> historial;
  final List<String> documentosFaltantes;
  final List<String> observaciones;
  final List<String> proximosPasos;
  final List<String> accionesDisponibles;

  bool get estaVacio {
    return tramiteId.trim().isEmpty &&
        politicaId.trim().isEmpty &&
        nombrePolitica.trim().isEmpty &&
        estadoTramite.trim().isEmpty &&
        (etapaActual == null || etapaActual!.estaVacia) &&
        (resumenProgreso == null || resumenProgreso!.estaVacio) &&
        historial.isEmpty &&
        documentosFaltantes.isEmpty &&
        observaciones.isEmpty &&
        proximosPasos.isEmpty &&
        accionesDisponibles.isEmpty;
  }

  Map<String, dynamic> aJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    _agregarTextoSiExiste(json, 'tramiteId', tramiteId);
    _agregarTextoSiExiste(json, 'politicaId', politicaId);
    _agregarTextoSiExiste(json, 'nombrePolitica', nombrePolitica);
    _agregarTextoSiExiste(json, 'estadoTramite', estadoTramite);

    if (etapaActual != null && !etapaActual!.estaVacia) {
      json['etapaActual'] = etapaActual!.aJson();
    }
    if (resumenProgreso != null && !resumenProgreso!.estaVacio) {
      json['resumenProgreso'] = resumenProgreso!.aJson();
    }

    final List<Map<String, dynamic>> historialJson = historial
        .where((HistorialGuiaUsuarioMovil item) => !item.estaVacio)
        .map((HistorialGuiaUsuarioMovil item) => item.aJson())
        .toList(growable: false);
    if (historialJson.isNotEmpty) {
      json['historial'] = historialJson;
    }

    final List<String> documentos = _limpiarTextos(documentosFaltantes);
    if (documentos.isNotEmpty) {
      json['documentosFaltantes'] = documentos;
    }

    final List<String> observacionesLimpias = _limpiarTextos(observaciones);
    if (observacionesLimpias.isNotEmpty) {
      json['observaciones'] = observacionesLimpias;
    }

    final List<String> proximos = _limpiarTextos(proximosPasos);
    if (proximos.isNotEmpty) {
      json['proximosPasos'] = proximos;
    }

    final List<String> acciones = _limpiarTextos(accionesDisponibles);
    if (acciones.isNotEmpty) {
      json['accionesDisponibles'] = acciones;
    }

    return json;
  }
}

void _agregarTextoSiExiste(
  Map<String, dynamic> json,
  String clave,
  String valor,
) {
  final String texto = valor.trim();
  if (texto.isNotEmpty) {
    json[clave] = texto;
  }
}

List<String> _limpiarTextos(List<String> valores) {
  return valores
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}
