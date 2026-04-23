import '../../domain/models/tarea_formulario_detalle.dart';

typedef JsonMap = Map<String, dynamic>;

class TareaFormularioDetalleModel {
  const TareaFormularioDetalleModel({
    required this.id,
    required this.estadoTarea,
    required this.nombreActividad,
    required this.responsableTipo,
    required this.responsableId,
    required this.formularioDefinicion,
    required this.formularioRespuesta,
    required this.observaciones,
  });

  factory TareaFormularioDetalleModel.fromJson(JsonMap json) {
    final JsonMap actividad =
        _toJsonMap(json['actividad']) ?? <String, dynamic>{};

    return TareaFormularioDetalleModel(
      id: _stringByKeys(json, <String>['id', 'tareaId']),
      estadoTarea: _stringByKeys(json, <String>['estadoTarea', 'estado']),
      nombreActividad: _stringByKeys(actividad, <String>[
        'nombreActividad',
        'nombreNodo',
        'nombre',
      ]),
      responsableTipo: _stringByKeys(actividad, <String>['responsableTipo']),
      responsableId: _stringByKeys(actividad, <String>['responsableId']),
      formularioDefinicion: _parseCampos(actividad['formularioDefinicion']),
      formularioRespuesta: _mapValues(json['formularioRespuesta']),
      observaciones: _stringByKeys(json, <String>['observaciones']),
    );
  }

  final String id;
  final String estadoTarea;
  final String nombreActividad;
  final String responsableTipo;
  final String responsableId;
  final List<CampoFormularioDetalleModel> formularioDefinicion;
  final Map<String, dynamic> formularioRespuesta;
  final String observaciones;

  TareaFormularioDetalle toDomain() {
    return TareaFormularioDetalle(
      id: id,
      estadoTarea: estadoTarea,
      nombreActividad: nombreActividad,
      responsableTipo: responsableTipo,
      responsableId: responsableId,
      formularioDefinicion: formularioDefinicion
          .map((CampoFormularioDetalleModel campo) => campo.toDomain())
          .toList(growable: false),
      formularioRespuesta: formularioRespuesta,
      observaciones: observaciones,
    );
  }
}

class CampoFormularioDetalleModel {
  const CampoFormularioDetalleModel({required this.clave, required this.tipo});

  factory CampoFormularioDetalleModel.fromJson(JsonMap json) {
    return CampoFormularioDetalleModel(
      clave: _stringByKeys(json, <String>[
        'campo',
        'clave',
        'nombre',
        'label',
        'etiqueta',
      ]),
      tipo: _stringByKeys(json, <String>['tipo']),
    );
  }

  final String clave;
  final String tipo;

  CampoFormularioDetalle toDomain() {
    return CampoFormularioDetalle(clave: clave, tipo: tipo);
  }
}

List<CampoFormularioDetalleModel> _parseCampos(dynamic value) {
  if (value is List<dynamic>) {
    return value
        .map(_toJsonMap)
        .whereType<JsonMap>()
        .map(CampoFormularioDetalleModel.fromJson)
        .where(
          (CampoFormularioDetalleModel campo) =>
              campo.clave.trim().isNotEmpty && campo.tipo.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  final JsonMap? object = _toJsonMap(value);
  if (object == null) {
    return const <CampoFormularioDetalleModel>[];
  }

  if (object.containsKey('campos')) {
    return _parseCampos(object['campos']);
  }

  final CampoFormularioDetalleModel single =
      CampoFormularioDetalleModel.fromJson(object);
  if (single.clave.trim().isEmpty || single.tipo.trim().isEmpty) {
    return const <CampoFormularioDetalleModel>[];
  }

  return <CampoFormularioDetalleModel>[single];
}

Map<String, dynamic> _mapValues(dynamic value) {
  return _toJsonMap(value) ?? <String, dynamic>{};
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

JsonMap? _toJsonMap(dynamic value) {
  if (value is JsonMap) {
    return value;
  }

  if (value is Map<dynamic, dynamic>) {
    return value.map(
      (dynamic key, dynamic item) =>
          MapEntry<String, dynamic>(key.toString(), item),
    );
  }

  return null;
}
