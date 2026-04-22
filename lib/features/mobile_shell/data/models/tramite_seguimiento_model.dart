import '../../domain/models/tramite_seguimiento.dart';

class TramiteSeguimientoModel {
  const TramiteSeguimientoModel({
    required this.instanciaId,
    required this.politicaId,
    required this.politicaNombre,
    required this.codigoTramite,
    required this.estadoInstancia,
    required this.laneOrientation,
    required this.laneWidth,
    required this.laneHeight,
    required this.nodos,
    required this.conexiones,
    required this.tareas,
    required this.departamentosActuales,
    required this.nodosActualesIds,
  });

  factory TramiteSeguimientoModel.fromJson(JsonMap json) {
    return TramiteSeguimientoModel(
      instanciaId: _stringByKeys(json, <String>['instanciaId', 'id']),
      politicaId: _stringByKeys(json, <String>['politicaId']),
      politicaNombre: _stringByKeys(json, <String>[
        'politicaNombre',
        'nombrePolitica',
        'nombre',
      ]),
      codigoTramite: _stringByKeys(json, <String>['codigoTramite', 'codigo']),
      estadoInstancia: _stringByKeys(json, <String>['estadoInstancia']),
      laneOrientation: _stringByKeys(json, <String>['laneOrientation']),
      laneWidth: _doubleValue(json['laneWidth']),
      laneHeight: _doubleValue(json['laneHeight']),
      nodos: _parseModelList(json['nodos'], NodoSeguimientoModel.fromJson),
      conexiones: _parseModelList(
        json['conexiones'],
        ConexionSeguimientoModel.fromJson,
      ),
      tareas: _parseModelList(json['tareas'], TareaSeguimientoModel.fromJson),
      departamentosActuales: _parseModelList(
        json['departamentosActuales'],
        DepartamentoActualSeguimientoModel.fromJson,
      ),
      nodosActualesIds: _stringList(json['nodosActualesIds']),
    );
  }

  final String instanciaId;
  final String politicaId;
  final String politicaNombre;
  final String codigoTramite;
  final String estadoInstancia;
  final String laneOrientation;
  final double? laneWidth;
  final double? laneHeight;
  final List<NodoSeguimientoModel> nodos;
  final List<ConexionSeguimientoModel> conexiones;
  final List<TareaSeguimientoModel> tareas;
  final List<DepartamentoActualSeguimientoModel> departamentosActuales;
  final List<String> nodosActualesIds;

  TramiteSeguimiento toDomain() {
    return TramiteSeguimiento(
      instanciaId: instanciaId,
      politicaId: politicaId,
      politicaNombre: politicaNombre,
      codigoTramite: codigoTramite,
      estadoInstancia: estadoInstancia,
      laneOrientation: laneOrientation,
      laneWidth: laneWidth,
      laneHeight: laneHeight,
      nodos: nodos
          .map((NodoSeguimientoModel model) => model.toDomain())
          .toList(growable: false),
      conexiones: conexiones
          .map((ConexionSeguimientoModel model) => model.toDomain())
          .toList(growable: false),
      tareas: tareas
          .map((TareaSeguimientoModel model) => model.toDomain())
          .toList(growable: false),
      departamentosActuales: departamentosActuales
          .map((DepartamentoActualSeguimientoModel model) => model.toDomain())
          .toList(growable: false),
      nodosActualesIds: nodosActualesIds,
    );
  }
}

class NodoSeguimientoModel {
  const NodoSeguimientoModel({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.departamentoId,
    required this.departamentoNombre,
    required this.responsableTipo,
    required this.responsableId,
    required this.responsableNombre,
    required this.posX,
    required this.posY,
    required this.estadoSeguimiento,
    required this.tareaActualId,
    required this.estadoTareaActual,
    required this.asignadoA,
    required this.asignadoANombre,
  });

  factory NodoSeguimientoModel.fromJson(JsonMap json) {
    return NodoSeguimientoModel(
      id: _stringByKeys(json, <String>['id', 'nodoId']),
      tipo: _stringByKeys(json, <String>['tipo']),
      nombre: _stringByKeys(json, <String>['nombre']),
      departamentoId: _stringByKeys(json, <String>['departamentoId']),
      departamentoNombre: _stringByKeys(json, <String>['departamentoNombre']),
      responsableTipo: _stringByKeys(json, <String>['responsableTipo']),
      responsableId: _stringByKeys(json, <String>['responsableId']),
      responsableNombre: _stringByKeys(json, <String>['responsableNombre']),
      posX: _doubleValue(json['posX']),
      posY: _doubleValue(json['posY']),
      estadoSeguimiento: _stringByKeys(json, <String>['estadoSeguimiento']),
      tareaActualId: _stringByKeys(json, <String>['tareaActualId']),
      estadoTareaActual: _stringByKeys(json, <String>['estadoTareaActual']),
      asignadoA: _stringByKeys(json, <String>['asignadoA']),
      asignadoANombre: _stringByKeys(json, <String>['asignadoANombre']),
    );
  }

  final String id;
  final String tipo;
  final String nombre;
  final String departamentoId;
  final String departamentoNombre;
  final String responsableTipo;
  final String responsableId;
  final String responsableNombre;
  final double? posX;
  final double? posY;
  final String estadoSeguimiento;
  final String tareaActualId;
  final String estadoTareaActual;
  final String asignadoA;
  final String asignadoANombre;

  NodoSeguimiento toDomain() {
    return NodoSeguimiento(
      id: id,
      tipo: tipo,
      nombre: nombre,
      departamentoId: departamentoId,
      departamentoNombre: departamentoNombre,
      responsableTipo: responsableTipo,
      responsableId: responsableId,
      responsableNombre: responsableNombre,
      posX: posX,
      posY: posY,
      estadoSeguimiento: estadoSeguimiento,
      tareaActualId: tareaActualId,
      estadoTareaActual: estadoTareaActual,
      asignadoA: asignadoA,
      asignadoANombre: asignadoANombre,
    );
  }
}

class ConexionSeguimientoModel {
  const ConexionSeguimientoModel({
    required this.origen,
    required this.destino,
    required this.puertoOrigen,
    required this.puertoDestino,
  });

  factory ConexionSeguimientoModel.fromJson(JsonMap json) {
    return ConexionSeguimientoModel(
      origen: _stringByKeys(json, <String>['origen', 'source']),
      destino: _stringByKeys(json, <String>['destino', 'target']),
      puertoOrigen: _stringByKeys(json, <String>['puertoOrigen']),
      puertoDestino: _stringByKeys(json, <String>['puertoDestino']),
    );
  }

  final String origen;
  final String destino;
  final String puertoOrigen;
  final String puertoDestino;

  ConexionSeguimiento toDomain() {
    return ConexionSeguimiento(
      origen: origen,
      destino: destino,
      puertoOrigen: puertoOrigen,
      puertoDestino: puertoDestino,
    );
  }
}

class TareaSeguimientoModel {
  const TareaSeguimientoModel({
    required this.id,
    required this.nodoId,
    required this.nombre,
    required this.estado,
    required this.asignadoA,
    required this.asignadoANombre,
  });

  factory TareaSeguimientoModel.fromJson(JsonMap json) {
    return TareaSeguimientoModel(
      id: _stringByKeys(json, <String>['id', 'tareaId']),
      nodoId: _stringByKeys(json, <String>['nodoId']),
      nombre: _stringByKeys(json, <String>['nombre']),
      estado: _stringByKeys(json, <String>['estado', 'estadoTarea']),
      asignadoA: _stringByKeys(json, <String>['asignadoA']),
      asignadoANombre: _stringByKeys(json, <String>['asignadoANombre']),
    );
  }

  final String id;
  final String nodoId;
  final String nombre;
  final String estado;
  final String asignadoA;
  final String asignadoANombre;

  TareaSeguimiento toDomain() {
    return TareaSeguimiento(
      id: id,
      nodoId: nodoId,
      nombre: nombre,
      estado: estado,
      asignadoA: asignadoA,
      asignadoANombre: asignadoANombre,
    );
  }
}

class DepartamentoActualSeguimientoModel {
  const DepartamentoActualSeguimientoModel({
    required this.departamentoId,
    required this.departamentoNombre,
    required this.nodoId,
    required this.nodoNombre,
    required this.tareaId,
    required this.estadoTarea,
    required this.responsableTipo,
    required this.responsableNombre,
    required this.asignadoANombre,
  });

  factory DepartamentoActualSeguimientoModel.fromJson(JsonMap json) {
    return DepartamentoActualSeguimientoModel(
      departamentoId: _stringByKeys(json, <String>['departamentoId']),
      departamentoNombre: _stringByKeys(json, <String>['departamentoNombre']),
      nodoId: _stringByKeys(json, <String>['nodoId']),
      nodoNombre: _stringByKeys(json, <String>['nodoNombre']),
      tareaId: _stringByKeys(json, <String>['tareaId']),
      estadoTarea: _stringByKeys(json, <String>['estadoTarea']),
      responsableTipo: _stringByKeys(json, <String>['responsableTipo']),
      responsableNombre: _stringByKeys(json, <String>['responsableNombre']),
      asignadoANombre: _stringByKeys(json, <String>['asignadoANombre']),
    );
  }

  final String departamentoId;
  final String departamentoNombre;
  final String nodoId;
  final String nodoNombre;
  final String tareaId;
  final String estadoTarea;
  final String responsableTipo;
  final String responsableNombre;
  final String asignadoANombre;

  DepartamentoActualSeguimiento toDomain() {
    return DepartamentoActualSeguimiento(
      departamentoId: departamentoId,
      departamentoNombre: departamentoNombre,
      nodoId: nodoId,
      nodoNombre: nodoNombre,
      tareaId: tareaId,
      estadoTarea: estadoTarea,
      responsableTipo: responsableTipo,
      responsableNombre: responsableNombre,
      asignadoANombre: asignadoANombre,
    );
  }
}

typedef JsonMap = Map<String, dynamic>;

List<T> _parseModelList<T>(dynamic value, T Function(JsonMap json) fromJson) {
  if (value is! List<dynamic>) {
    return <T>[];
  }

  return value
      .map(_toJsonMap)
      .whereType<JsonMap>()
      .map(fromJson)
      .toList(growable: false);
}

List<String> _stringList(dynamic value) {
  if (value is! List<dynamic>) {
    return <String>[];
  }

  return value
      .map(_stringValue)
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

String _stringByKeys(JsonMap json, List<String> keys) {
  for (final String key in keys) {
    final String value = _stringValue(json[key]);
    if (value.isNotEmpty) {
      return value;
    }
  }

  return '';
}

String _stringValue(dynamic value) {
  return value?.toString().trim() ?? '';
}

double? _doubleValue(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  return null;
}

JsonMap? _toJsonMap(dynamic value) {
  if (value is JsonMap) {
    return value;
  }

  if (value is Map<dynamic, dynamic>) {
    return value.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }

  return null;
}
