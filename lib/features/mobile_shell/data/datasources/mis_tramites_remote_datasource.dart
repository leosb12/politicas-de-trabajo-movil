import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../../domain/models/mis_tramite_item.dart';
import '../../domain/models/tramite_seguimiento.dart';
import '../models/tramite_seguimiento_model.dart';
import 'mis_tramites_mock_datasource.dart';

class MisTramitesRemoteDataSource implements MisTramitesDataSource {
  MisTramitesRemoteDataSource(this._dio);

  final Dio _dio;
  static const int _defaultPage = 0;
  static const int _defaultSize = 50;

  @override
  Future<List<MisTramiteItem>> obtenerMisTramites({
    required String usuarioId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.misTramitesCardsPath,
        queryParameters: const <String, dynamic>{
          'page': _defaultPage,
          'size': _defaultSize,
        },
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      return _parseInstanciasCards(data: response.data, usuarioId: usuarioId);
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<TramiteSeguimiento> obtenerSeguimiento({
    required String usuarioId,
    required String instanciaId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.instanciaFlujoPath(instanciaId),
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      final TramiteSeguimiento seguimiento = _parseSeguimientoResponse(
        response.data,
      ).toDomain();
      final List<DocumentoSeguimiento> documentos =
          await _obtenerDocumentosVisibles(
            usuarioId: usuarioId,
            instanciaId: instanciaId,
          );

      return TramiteSeguimiento(
        instanciaId: seguimiento.instanciaId,
        politicaId: seguimiento.politicaId,
        politicaNombre: seguimiento.politicaNombre,
        codigoTramite: seguimiento.codigoTramite,
        estadoInstancia: seguimiento.estadoInstancia,
        laneOrientation: seguimiento.laneOrientation,
        laneWidth: seguimiento.laneWidth,
        laneHeight: seguimiento.laneHeight,
        nodos: seguimiento.nodos,
        conexiones: seguimiento.conexiones,
        tareas: seguimiento.tareas,
        documentos: documentos,
        departamentosActuales: seguimiento.departamentosActuales,
        nodosActualesIds: seguimiento.nodosActualesIds,
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  Future<List<DocumentoSeguimiento>> _obtenerDocumentosVisibles({
    required String usuarioId,
    required String instanciaId,
  }) async {
    final List<DocumentoSeguimiento> result = <DocumentoSeguimiento>[];

    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.archivosPorInstanciaPath(instanciaId),
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      final dynamic raw = response.data;
      if (raw is List<dynamic>) {
        result.addAll(
          raw
              .map(_asJsonMap)
              .whereType<Map<String, dynamic>>()
              .map(_parseDocumentoSeguimiento)
              .where(
                (DocumentoSeguimiento item) =>
                    item.puedeVer || item.urlAcceso.trim().isNotEmpty,
              ),
        );
      }
    } catch (_) {
      // Ignorar si falla la obtención de archivos normales
    }

    try {
      final Response<dynamic> colabResponse = await _dio.get(
        NetworkConstants.documentosColaborativosPorTramitePath(instanciaId),
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      final dynamic rawColab = colabResponse.data;
      if (rawColab is List<dynamic>) {
        result.addAll(
          rawColab
              .map(_asJsonMap)
              .whereType<Map<String, dynamic>>()
              .map(_parseDocColabSeguimiento)
              .whereType<DocumentoSeguimiento>()
              .where((DocumentoSeguimiento item) => item.puedeVer),
        );
      }
    } catch (_) {
      // Ignorar si falla la obtención de documentos colaborativos
    }

    return result;
  }

  DocumentoSeguimiento? _parseDocColabSeguimiento(Map<String, dynamic> json) {
    try {
      final String documentoId = _stringValue(json['documentoId']);
      if (documentoId.isEmpty) return null;

      final Map<String, dynamic>? permisos =
          json['permisosUsuario'] is Map<dynamic, dynamic>
              ? (json['permisosUsuario'] as Map<dynamic, dynamic>).map(
                  (dynamic k, dynamic v) =>
                      MapEntry<String, dynamic>(k.toString(), v),
                )
              : json['permisosUsuario'] as Map<String, dynamic>?;

      final bool puedeLeer = _boolValue(permisos?['puedeLeer']);
      final bool puedeEditar = _boolValue(permisos?['puedeEditar']);

      if (!puedeLeer) return null;

      return DocumentoSeguimiento(
        id: documentoId,
        nombreOriginal: _stringValue(json['nombreDocumento']),
        contentType: 'application/octet-stream',
        extension: _stringValue(json['tipoDocumento']).toLowerCase(),
        fechaSubida: _tryParseDateTime(json['fechaCreacion']),
        subidoPor: _stringValue(json['creadoPor']),
        subidoPorNombre: '',
        estado: _stringValue(json['estado']),
        tareaId: _stringValue(json['tareaId']),
        actividadId: _stringValue(json['nodoId']),
        campoId: _stringValue(json['campoFormularioId']),
        urlAcceso: '',
        puedeVer: puedeLeer,
        puedeDescargar: _boolValue(permisos?['puedeDescargar']),
        puedeEditar: puedeEditar,
        puedeReemplazar: false,
        puedeEliminar: false,
        documentoColaborativoId: documentoId,
      );
    } catch (_) {
      return null;
    }
  }

  DocumentoSeguimiento _parseDocumentoSeguimiento(Map<String, dynamic> json) {
    final String urlAcceso = _stringByKeys(json, <String>[
      'urlAcceso',
      'onlyOfficeUrl',
      'urlOnlyOffice',
      'viewerUrl',
      'viewUrl',
      'editorUrl',
      'url',
    ]);
    // documentoColaborativoId links this ArchivoAdjunto to the DynamoDB
    // collaborative document record. The backend may surface it under several
    // keys, or we can extract it from the urlAcceso path when it follows the
    // pattern /api/documentos-colaborativos/{documentoId}/...
    String documentoColaborativoId = _stringByKeys(json, <String>[
      'documentoColaborativoId',
      'documentoId',
      'colabDocId',
    ]);
    if (documentoColaborativoId.isEmpty && urlAcceso.isNotEmpty) {
      documentoColaborativoId = _extractDocumentoIdFromUrl(urlAcceso);
    }
    return DocumentoSeguimiento(
      id: _stringByKeys(json, <String>['id', 'archivoId']),
      nombreOriginal: _stringByKeys(json, <String>[
        'nombreOriginal',
        'nombreArchivo',
        'filename',
        'name',
      ]),
      contentType: _stringByKeys(json, <String>['contentType', 'mimeType']),
      extension: _stringByKeys(json, <String>['extension', 'ext']),
      fechaSubida: _tryParseDateTime(json['fechaSubida']),
      subidoPor: _stringValue(json['subidoPor']),
      subidoPorNombre: _stringValue(json['subidoPorNombre']),
      estado: _stringValue(json['estado']),
      tareaId: _stringByKeys(json, <String>['tareaId', 'taskId']),
      actividadId: _stringByKeys(json, <String>['actividadId', 'activityId']),
      campoId: _stringValue(json['campoId']),
      urlAcceso: urlAcceso,
      puedeVer:
          _boolByKeys(json, <String>[
            'puedeVer',
            'puedeVisualizar',
            'permisoLectura',
            'canView',
          ]) ||
          urlAcceso.isNotEmpty,
      puedeDescargar: _boolValue(json['puedeDescargar']),
      puedeEditar: _boolValue(json['puedeEditar']),
      puedeReemplazar: _boolValue(json['puedeReemplazar']),
      puedeEliminar: _boolValue(json['puedeEliminar']),
      documentoColaborativoId:
          documentoColaborativoId.isNotEmpty ? documentoColaborativoId : null,
    );
  }

  /// Tries to extract documentoId from a URL like:
  /// http://host/api/documentos-colaborativos/{documentoId}/source
  String _extractDocumentoIdFromUrl(String url) {
    try {
      final Uri? uri = Uri.tryParse(url);
      if (uri == null) return '';
      final List<String> segments = uri.pathSegments;
      // Look for the segment after 'documentos-colaborativos'
      for (int i = 0; i < segments.length - 1; i++) {
        if (segments[i] == 'documentos-colaborativos') {
          final String candidate = segments[i + 1].trim();
          if (candidate.isNotEmpty &&
              !candidate.startsWith('onlyoffice') &&
              candidate != 'source' &&
              candidate != 'mobile-viewer') {
            return candidate;
          }
        }
      }
    } catch (_) {}
    return '';
  }


  @override
  Future<DocumentoArchivoBinario> verDocumento({
    required String usuarioId,
    required String archivoId,
  }) {
    return _obtenerArchivoBinario(
      usuarioId: usuarioId,
      path: NetworkConstants.archivoVerPath(archivoId),
    );
  }

  @override
  Future<DocumentoArchivoBinario> descargarDocumento({
    required String usuarioId,
    required String archivoId,
  }) {
    return _obtenerArchivoBinario(
      usuarioId: usuarioId,
      path: NetworkConstants.archivoDescargarPath(archivoId),
    );
  }

  Future<DocumentoArchivoBinario> _obtenerArchivoBinario({
    required String usuarioId,
    required String path,
  }) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        path,
        options: Options(
          headers: <String, String>{'X-User-Id': usuarioId},
          responseType: ResponseType.bytes,
        ),
      );
      return DocumentoArchivoBinario(
        bytes: response.data ?? <int>[],
        nombreArchivo: _filenameFromDisposition(
          response.headers.value('content-disposition'),
        ),
        contentType: response.headers.value(Headers.contentTypeHeader) ?? '',
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    }
  }

  @override
  Future<void> editarDocumento({
    required String usuarioId,
    required String archivoId,
    required String nombreOriginal,
    required String descripcion,
  }) async {
    try {
      await _dio.patch<dynamic>(
        NetworkConstants.archivoDetallePath(archivoId),
        data: <String, String>{
          'nombreOriginal': nombreOriginal,
          'descripcion': descripcion,
        },
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    }
  }

  @override
  Future<void> reemplazarDocumento({
    required String usuarioId,
    required String archivoId,
    required String nombreArchivo,
    required List<int> bytes,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'archivo': MultipartFile.fromBytes(bytes, filename: nombreArchivo),
      });
      await _dio.put<dynamic>(
        NetworkConstants.archivoReemplazarPath(archivoId),
        data: formData,
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    }
  }

  @override
  Future<void> eliminarDocumento({
    required String usuarioId,
    required String archivoId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        NetworkConstants.archivoDetallePath(archivoId),
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    }
  }

  List<MisTramiteItem> _parseInstanciasCards({
    required dynamic data,
    required String usuarioId,
  }) {
    final dynamic rawContent;
    if (data is List<dynamic>) {
      rawContent = data;
    } else if (data is Map<String, dynamic>) {
      rawContent = data['content'];
    } else if (data is Map<dynamic, dynamic>) {
      rawContent = data['content'];
    } else {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    if (rawContent is! List<dynamic>) {
      throw ApiFailure(message: 'Respuesta invalida del servidor.');
    }

    return rawContent
        .map((dynamic rawItem) {
          final Map<String, dynamic>? item = _asJsonMap(rawItem);
          if (item == null) {
            throw ApiFailure(message: 'Respuesta invalida del servidor.');
          }

          final String id = _stringValue(item['id']);
          if (id.isEmpty) {
            throw ApiFailure(
              message: 'El servidor devolvio una instancia invalida.',
            );
          }

          final String estadoRaw = _stringValue(
            item['estadoInstancia'],
          ).toUpperCase();

          return MisTramiteItem(
            id: id,
            usuarioId: usuarioId,
            codigoTramite: _stringValue(item['codigoTramite']),
            nombre: _stringValue(item['nombre']).isEmpty
                ? 'Tramite sin nombre'
                : _stringValue(item['nombre']),
            estado: _normalizarEstado(estadoRaw),
            progreso: _parsePorcentaje(item['porcentaje']),
            fechaCreacion: _parseDateTime(item['fechaCreacion']),
          );
        })
        .toList(growable: false);
  }

  String _normalizarEstado(String estadoRaw) {
    switch (estadoRaw) {
      case 'EN_CURSO':
        return 'En curso';
      case 'FINALIZADA':
        return 'Finalizada';
      case 'PAUSADA':
        return 'Pausada';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return estadoRaw.isEmpty ? 'Sin estado' : estadoRaw;
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  DateTime? _tryParseDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  double _parsePorcentaje(dynamic value) {
    final double? porcentaje = _doubleValue(value);
    if (porcentaje == null) {
      return 0;
    }

    return (porcentaje / 100).clamp(0, 1).toDouble();
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

  bool _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.trim().toLowerCase() == 'true';
    }
    return false;
  }

  bool _boolByKeys(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      if (_boolValue(json[key])) {
        return true;
      }
    }
    return false;
  }

  String _stringByKeys(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      final String value = _stringValue(json[key]);
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  Map<String, dynamic>? _asJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) {
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

  TramiteSeguimientoModel _parseSeguimientoResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return TramiteSeguimientoModel.fromJson(data);
    }

    if (data is Map<dynamic, dynamic>) {
      return TramiteSeguimientoModel.fromJson(
        data.map(
          (dynamic key, dynamic value) =>
              MapEntry<String, dynamic>(key.toString(), value),
        ),
      );
    }

    throw ApiFailure(message: 'Respuesta invalida del servidor.');
  }
}

String _filenameFromDisposition(String? disposition) {
  if (disposition == null || disposition.trim().isEmpty) {
    return 'documento';
  }
  final RegExp encoded = RegExp("filename\\*=UTF-8''([^;]+)");
  final RegExp plain = RegExp('filename="?([^";]+)"?');
  final RegExpMatch? encodedMatch = encoded.firstMatch(disposition);
  if (encodedMatch != null) {
    return Uri.decodeComponent(encodedMatch.group(1) ?? 'documento');
  }
  return plain.firstMatch(disposition)?.group(1) ?? 'documento';
}
