import '../../domain/models/tramite_disponible_item.dart';

abstract class IniciarTramiteDataSource {
  Future<List<TramiteDisponibleItem>> obtenerTramitesActivos({
    required String actorUserId,
  });

  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
  });
}

class IniciarTramiteMockDataSource implements IniciarTramiteDataSource {
  static const List<TramiteDisponibleItem> _tramitesMock =
      <TramiteDisponibleItem>[
        TramiteDisponibleItem(
          id: 'tramite_001',
          nombre: 'Solicitud de partida de nacimiento',
          descripcion: 'Genera una solicitud digital para obtener la partida.',
          categoria: 'Registro civil',
          requierePago: false,
        ),
        TramiteDisponibleItem(
          id: 'tramite_002',
          nombre: 'Renovación de licencia comercial',
          descripcion: 'Inicia el proceso para renovar tu licencia vigente.',
          categoria: 'Comercio',
          requierePago: true,
          montoPago: 250.0,
          monedaPago: 'DOP',
          descripcionPago: 'Pago de trámite',
        ),
        TramiteDisponibleItem(
          id: 'tramite_003',
          nombre: 'Certificado de residencia',
          descripcion: 'Solicita el certificado con validación local.',
          categoria: 'Ciudadanía',
          requierePago: false,
        ),
      ];

  @override
  Future<List<TramiteDisponibleItem>> obtenerTramitesActivos({
    required String actorUserId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return _tramitesMock
        .map((TramiteDisponibleItem item) => item.copyWith())
        .toList();
  }

  @override
  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final bool existe = _tramitesMock.any(
      (TramiteDisponibleItem item) => item.id == tramiteId,
    );

    if (!existe) {
      throw Exception('No se encontró el trámite seleccionado.');
    }
  }
}
