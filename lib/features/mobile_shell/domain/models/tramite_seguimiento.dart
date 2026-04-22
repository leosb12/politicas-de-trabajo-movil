class TramiteSeguimiento {
  const TramiteSeguimiento({
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

  final String instanciaId;
  final String politicaId;
  final String politicaNombre;
  final String codigoTramite;
  final String estadoInstancia;
  final String laneOrientation;
  final double? laneWidth;
  final double? laneHeight;
  final List<NodoSeguimiento> nodos;
  final List<ConexionSeguimiento> conexiones;
  final List<TareaSeguimiento> tareas;
  final List<DepartamentoActualSeguimiento> departamentosActuales;
  final List<String> nodosActualesIds;

  bool get isEmpty => nodos.isEmpty && conexiones.isEmpty;

  Set<String> get nodosActualesIdSet => nodosActualesIds.toSet();
}

class NodoSeguimiento {
  const NodoSeguimiento({
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

  bool get tienePosicion => posX != null && posY != null;
}

class ConexionSeguimiento {
  const ConexionSeguimiento({
    required this.origen,
    required this.destino,
    required this.puertoOrigen,
    required this.puertoDestino,
  });

  final String origen;
  final String destino;
  final String puertoOrigen;
  final String puertoDestino;
}

class TareaSeguimiento {
  const TareaSeguimiento({
    required this.id,
    required this.nodoId,
    required this.nombre,
    required this.estado,
    required this.asignadoA,
    required this.asignadoANombre,
  });

  final String id;
  final String nodoId;
  final String nombre;
  final String estado;
  final String asignadoA;
  final String asignadoANombre;
}

class DepartamentoActualSeguimiento {
  const DepartamentoActualSeguimiento({
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

  final String departamentoId;
  final String departamentoNombre;
  final String nodoId;
  final String nodoNombre;
  final String tareaId;
  final String estadoTarea;
  final String responsableTipo;
  final String responsableNombre;
  final String asignadoANombre;
}
