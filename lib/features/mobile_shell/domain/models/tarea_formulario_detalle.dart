class TareaFormularioDetalle {
  const TareaFormularioDetalle({
    required this.id,
    required this.estadoTarea,
    required this.nombreActividad,
    required this.responsableTipo,
    required this.responsableId,
    required this.formularioDefinicion,
    required this.formularioRespuesta,
    required this.observaciones,
  });

  final String id;
  final String estadoTarea;
  final String nombreActividad;
  final String responsableTipo;
  final String responsableId;
  final List<CampoFormularioDetalle> formularioDefinicion;
  final Map<String, dynamic> formularioRespuesta;
  final String observaciones;

  bool get estaAbierta {
    final String normalized = estadoTarea.trim().toUpperCase();
    return normalized == 'PENDIENTE' || normalized == 'EN_PROCESO';
  }

  bool get tieneCampos => formularioDefinicion.isNotEmpty;

  bool get requiereCampoArchivo => formularioDefinicion.any(
    (CampoFormularioDetalle campo) => campo.tipoNormalizado == 'ARCHIVO',
  );
}

class CampoFormularioDetalle {
  const CampoFormularioDetalle({required this.clave, required this.tipo});

  final String clave;
  final String tipo;

  String get tipoNormalizado => tipo.trim().toUpperCase();
}
