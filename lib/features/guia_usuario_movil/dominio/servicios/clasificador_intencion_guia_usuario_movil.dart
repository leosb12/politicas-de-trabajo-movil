import 'dart:convert';

class ClasificadorIntencionGuiaUsuarioMovil {
  String resolver({required String pregunta, required String pantalla}) {
    final String preguntaNormalizada = _normalizar(pregunta);
    final String pantallaNormalizada = pantalla.trim().toUpperCase();

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'que hago aqui',
      'donde estoy',
      'explica esta pantalla',
      'para que sirve esta pantalla',
    ])) {
      return 'EXPLICAR_PANTALLA';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'que puedo hacer aqui',
      'que puedo hacer',
      'que opciones tengo',
      'que acciones tengo',
    ])) {
      return 'QUE_PUEDO_HACER_AQUI';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'como inicio un tramite',
      'como iniciar',
      'iniciar tramite',
      'nuevo tramite',
    ])) {
      return 'AYUDA_INICIAR_TRAMITE';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'subir documento',
      'adjuntar documento',
      'cargar documento',
      'enviar documento',
    ])) {
      return 'AYUDA_SUBIR_DOCUMENTO';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'por que fue rechazado',
      'por que lo rechazaron',
      'rechazado',
      'rechazada',
    ])) {
      return 'EXPLICAR_RECHAZO';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'que documentos me faltan',
      'documentos faltantes',
      'que documento falta',
      'me falta documento',
    ])) {
      return 'EXPLICAR_DOCUMENTOS_FALTANTES';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'observado',
      'observaciones',
      'que significa esta observacion',
    ])) {
      return 'EXPLICAR_OBSERVACIONES';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'historial',
      'que ya paso',
      'que etapas ya pasaron',
    ])) {
      return 'EXPLICAR_HISTORIAL';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'que pasa despues',
      'proximo paso',
      'que sigue despues',
      'cuanto podria tardar',
    ])) {
      return 'EXPLICAR_PROXIMO_PASO';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'en que etapa va',
      'etapa actual',
      'quien lo esta revisando',
    ])) {
      return 'EXPLICAR_ETAPA_ACTUAL';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'progreso del tramite',
      'como va mi tramite',
      'ya termino mi tramite',
      'que falta para que avance',
    ])) {
      return 'EXPLICAR_PROGRESO_TRAMITE';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'en que estado esta mi tramite',
      'estado del tramite',
      'que significa este estado',
      'por que esta detenido',
      'esta en proceso',
    ])) {
      return 'EXPLICAR_ESTADO_TRAMITE';
    }

    if (_contieneAlguna(preguntaNormalizada, const <String>[
      'paso a paso',
      'guiame',
      'como empiezo',
    ])) {
      return 'GUIA_PASO_A_PASO';
    }

    if (pantallaNormalizada == 'LISTA_TRAMITES' &&
        _contieneAlguna(preguntaNormalizada, const <String>[
          'tramite',
          'lista',
          'estado',
        ])) {
      return 'EXPLICAR_PANTALLA';
    }

    return 'AYUDA_GENERAL_USUARIO_MOVIL';
  }

  bool _contieneAlguna(String valor, List<String> opciones) {
    return opciones.any(valor.contains);
  }

  String _normalizar(String valor) {
    final String minusculas = valor.trim().toLowerCase();
    if (minusculas.isEmpty) {
      return '';
    }

    const Map<String, String> reemplazos = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };

    final StringBuffer buffer = StringBuffer();
    for (final int codigo in utf8.encode(minusculas)) {
      final String caracter = String.fromCharCode(codigo);
      buffer.write(reemplazos[caracter] ?? caracter);
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }
}
