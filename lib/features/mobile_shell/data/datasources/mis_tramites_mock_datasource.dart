import '../../domain/models/mis_tramite_item.dart';

abstract class MisTramitesDataSource {
  Future<List<MisTramiteItem>> obtenerMisTramites({required String usuarioId});
}

class MisTramitesMockDataSource implements MisTramitesDataSource {
  static final List<MisTramiteItem> _items = <MisTramiteItem>[
    MisTramiteItem(
      id: 'inst_001',
      usuarioId: '1',
      nombre: 'Solicitud de partida de nacimiento',
      estado: 'En revisión',
      progreso: 0.45,
      actualizadoEn: DateTime(2026, 4, 21, 10, 30),
    ),
    MisTramiteItem(
      id: 'inst_002',
      usuarioId: '1',
      nombre: 'Renovación de licencia comercial',
      estado: 'Documentación completa',
      progreso: 0.80,
      actualizadoEn: DateTime(2026, 4, 22, 8, 10),
    ),
    MisTramiteItem(
      id: 'inst_003',
      usuarioId: '2',
      nombre: 'Certificado de residencia',
      estado: 'Finalizado',
      progreso: 1,
      actualizadoEn: DateTime(2026, 4, 20, 16, 40),
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
}