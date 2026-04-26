class AccionSugeridaGuiaUsuarioMovil {
  const AccionSugeridaGuiaUsuarioMovil({
    required this.accion,
    required this.etiqueta,
  });

  final String accion;
  final String etiqueta;

  factory AccionSugeridaGuiaUsuarioMovil.desdeJson(Map<String, dynamic> json) {
    return AccionSugeridaGuiaUsuarioMovil(
      accion: _texto(json['action']),
      etiqueta: _texto(json['label']),
    );
  }
}

class RespuestaGuiaUsuarioMovil {
  const RespuestaGuiaUsuarioMovil({
    required this.respuesta,
    this.pasos = const <String>[],
    this.estadoExplicado = '',
    this.progresoExplicado = '',
    this.documentosFaltantes = const <String>[],
    this.proximosPasos = const <String>[],
    this.accionesSugeridas = const <AccionSugeridaGuiaUsuarioMovil>[],
    this.severidad = 'INFO',
    this.intencion = '',
    this.fuente = '',
    this.disponible = true,
  });

  final String respuesta;
  final List<String> pasos;
  final String estadoExplicado;
  final String progresoExplicado;
  final List<String> documentosFaltantes;
  final List<String> proximosPasos;
  final List<AccionSugeridaGuiaUsuarioMovil> accionesSugeridas;
  final String severidad;
  final String intencion;
  final String fuente;
  final bool disponible;

  bool get tieneContenido {
    return respuesta.trim().isNotEmpty ||
        pasos.isNotEmpty ||
        estadoExplicado.trim().isNotEmpty ||
        progresoExplicado.trim().isNotEmpty;
  }

  factory RespuestaGuiaUsuarioMovil.desdeJson(Map<String, dynamic> json) {
    return RespuestaGuiaUsuarioMovil(
      respuesta: _texto(json['answer']),
      pasos: _listaDeTextos(json['steps']),
      estadoExplicado: _texto(json['estadoExplicado']),
      progresoExplicado: _texto(json['progresoExplicado']),
      documentosFaltantes: _listaDeTextos(json['documentosFaltantes']),
      proximosPasos: _listaDeTextos(json['proximosPasos']),
      accionesSugeridas: _listaDeMapas(
        json['accionesSugeridas'],
      ).map(AccionSugeridaGuiaUsuarioMovil.desdeJson).toList(growable: false),
      severidad: _texto(json['severity']).isEmpty
          ? 'INFO'
          : _texto(json['severity']),
      intencion: _texto(json['intent']),
      fuente: _texto(json['source']),
      disponible: json['available'] is bool ? json['available'] as bool : true,
    );
  }
}

class ResultadoGuiaUsuarioMovil {
  const ResultadoGuiaUsuarioMovil({
    required this.respuesta,
    required this.usoRespaldoLocal,
    this.detalleRespaldo,
  });

  final RespuestaGuiaUsuarioMovil respuesta;
  final bool usoRespaldoLocal;
  final String? detalleRespaldo;
}

String _texto(dynamic valor) {
  return valor?.toString().trim() ?? '';
}

List<String> _listaDeTextos(dynamic valor) {
  if (valor is! List<dynamic>) {
    return const <String>[];
  }

  return valor
      .map(_texto)
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _listaDeMapas(dynamic valor) {
  if (valor is! List<dynamic>) {
    return const <Map<String, dynamic>>[];
  }

  return valor
      .map<Map<String, dynamic>?>((dynamic item) {
        if (item is Map<String, dynamic>) {
          return item;
        }
        if (item is Map<dynamic, dynamic>) {
          return item.map(
            (dynamic key, dynamic value) =>
                MapEntry<String, dynamic>(key.toString(), value),
          );
        }
        return null;
      })
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}
