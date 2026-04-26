import '../../domain/models/mis_tramite_item.dart';
import '../../domain/models/tramite_seguimiento.dart';

abstract class MisTramitesDataSource {
  Future<List<MisTramiteItem>> obtenerMisTramites({required String usuarioId});

  Future<TramiteSeguimiento> obtenerSeguimiento({
    required String usuarioId,
    required String instanciaId,
  });
}

class MisTramitesMockDataSource implements MisTramitesDataSource {
  static final List<MisTramiteItem> _items = <MisTramiteItem>[
    MisTramiteItem(
      id: 'inst_001',
      usuarioId: '1',
      codigoTramite: 'TRM-001',
      nombre: 'Solicitud de partida de nacimiento',
      estado: 'En revision',
      progreso: 0.45,
      fechaCreacion: DateTime(2026, 4, 21, 10, 30),
    ),
    MisTramiteItem(
      id: 'inst_002',
      usuarioId: '1',
      codigoTramite: 'TRM-002',
      nombre: 'Renovacion de licencia comercial',
      estado: 'Documentacion completa',
      progreso: 0.80,
      fechaCreacion: DateTime(2026, 4, 22, 8, 10),
    ),
    MisTramiteItem(
      id: 'inst_003',
      usuarioId: '2',
      codigoTramite: 'TRM-003',
      nombre: 'Certificado de residencia',
      estado: 'Finalizado',
      progreso: 1,
      fechaCreacion: DateTime(2026, 4, 20, 16, 40),
    ),
  ];

  @override
  Future<List<MisTramiteItem>> obtenerMisTramites({
    required String usuarioId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return _items
        .where((MisTramiteItem item) => item.usuarioId == usuarioId)
        .map((MisTramiteItem item) => item.copyWith())
        .toList();
  }

  @override
  Future<TramiteSeguimiento> obtenerSeguimiento({
    required String usuarioId,
    required String instanciaId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final MisTramiteItem item = _items.firstWhere(
      (MisTramiteItem item) =>
          item.usuarioId == usuarioId && item.id == instanciaId,
      orElse: () => throw Exception('Tramite no encontrado.'),
    );

    return TramiteSeguimiento(
      instanciaId: item.id,
      politicaId: 'politica_mock',
      politicaNombre: item.nombre,
      codigoTramite: item.codigoTramite,
      estadoInstancia: item.estado,
      laneOrientation: 'VERTICAL',
      laneWidth: 320,
      laneHeight: 760,
      nodosActualesIds: const <String>['revision'],
      departamentosActuales: const <DepartamentoActualSeguimiento>[
        DepartamentoActualSeguimiento(
          departamentoId: 'dep_revision',
          departamentoNombre: 'Revision',
          nodoId: 'revision',
          nodoNombre: 'Revision documental',
          tareaId: 'tarea_revision',
          estadoTarea: 'EN_CURSO',
          responsableTipo: 'DEPARTAMENTO',
          responsableNombre: 'Equipo de revision',
          asignadoANombre: 'Analista municipal',
        ),
      ],
      nodos: const <NodoSeguimiento>[
        NodoSeguimiento(
          id: 'inicio',
          tipo: 'INICIO',
          nombre: 'Inicio',
          departamentoId: '',
          departamentoNombre: '',
          responsableTipo: '',
          responsableId: '',
          responsableNombre: '',
          posX: 40,
          posY: 20,
          estadoSeguimiento: 'COMPLETADO',
          tareaActualId: '',
          estadoTareaActual: '',
          asignadoA: '',
          asignadoANombre: '',
        ),
        NodoSeguimiento(
          id: 'revision',
          tipo: 'ACTIVIDAD',
          nombre: 'Revision documental',
          departamentoId: 'dep_revision',
          departamentoNombre: 'Revision',
          responsableTipo: 'DEPARTAMENTO',
          responsableId: 'dep_revision',
          responsableNombre: 'Equipo de revision',
          posX: 40,
          posY: 220,
          estadoSeguimiento: 'ACTUAL',
          tareaActualId: 'tarea_revision',
          estadoTareaActual: 'EN_CURSO',
          asignadoA: 'user_mock',
          asignadoANombre: 'Analista municipal',
        ),
        NodoSeguimiento(
          id: 'fin',
          tipo: 'FIN',
          nombre: 'Finalizacion',
          departamentoId: '',
          departamentoNombre: '',
          responsableTipo: '',
          responsableId: '',
          responsableNombre: '',
          posX: 40,
          posY: 420,
          estadoSeguimiento: 'PENDIENTE',
          tareaActualId: '',
          estadoTareaActual: '',
          asignadoA: '',
          asignadoANombre: '',
        ),
      ],
      conexiones: const <ConexionSeguimiento>[
        ConexionSeguimiento(
          origen: 'inicio',
          destino: 'revision',
          puertoOrigen: '',
          puertoDestino: '',
        ),
        ConexionSeguimiento(
          origen: 'revision',
          destino: 'fin',
          puertoOrigen: '',
          puertoDestino: '',
        ),
      ],
      tareas: const <TareaSeguimiento>[
        TareaSeguimiento(
          id: 'tarea_revision',
          nodoId: 'revision',
          nombre: 'Revision documental',
          responsableTipo: 'DEPARTAMENTO',
          responsableId: 'dep_revision',
          responsableNombre: 'Equipo de revision',
          estado: 'EN_CURSO',
          asignadoA: 'user_mock',
          asignadoANombre: 'Analista municipal',
        ),
      ],
    );
  }
}
