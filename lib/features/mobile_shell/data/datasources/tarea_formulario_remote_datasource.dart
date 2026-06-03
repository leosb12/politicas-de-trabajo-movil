import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_constants.dart';
import '../../domain/models/tarea_formulario_detalle.dart';
import '../models/tarea_formulario_detalle_model.dart';

abstract class TareaFormularioDataSource {
  Future<TareaFormularioDetalle> obtenerDetalle({
    required String usuarioId,
    required String tareaId,
  });

  Future<void> completarTarea({
    required String usuarioId,
    required String tareaId,
    required Map<String, dynamic> formularioRespuesta,
    String? observaciones,
  });

  Future<String> subirArchivo({
    required String usuarioId,
    required String instanciaId,
    required String tareaId,
    required String nombreArchivo,
    required List<int> bytes,
  });
}

class TareaFormularioRemoteDataSource implements TareaFormularioDataSource {
  TareaFormularioRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<TareaFormularioDetalle> obtenerDetalle({
    required String usuarioId,
    required String tareaId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get(
        NetworkConstants.tareaDetallePath(tareaId),
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      final JsonMap? json = _toJsonMap(response.data);
      if (json == null) {
        throw ApiFailure(message: 'Respuesta invalida del servidor.');
      }

      return TareaFormularioDetalleModel.fromJson(json).toDomain();
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<void> completarTarea({
    required String usuarioId,
    required String tareaId,
    required Map<String, dynamic> formularioRespuesta,
    String? observaciones,
  }) async {
    try {
      await _dio.post<dynamic>(
        NetworkConstants.tareaCompletarPath(tareaId),
        data: <String, dynamic>{
          'formularioRespuesta': formularioRespuesta,
          'observaciones': _normalize(observaciones),
        },
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  @override
  Future<String> subirArchivo({
    required String usuarioId,
    required String instanciaId,
    required String tareaId,
    required String nombreArchivo,
    required List<int> bytes,
  }) async {
    try {
      final MultipartFile file = MultipartFile.fromBytes(
        bytes,
        filename: nombreArchivo,
      );

      final FormData formData = FormData.fromMap(<String, dynamic>{
        'file': file,
        'origenCarga': 'MOBILE',
      });

      final String path = '/api/documentos/tramites/${Uri.encodeComponent(instanciaId)}/archivos';

      final Response<dynamic> response = await _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(headers: <String, String>{'X-User-Id': usuarioId}),
      );

      final JsonMap? json = _toJsonMap(response.data);
      final String? fileId = json?['archivoId']?.toString() ?? json?['id']?.toString();
      if (json == null || fileId == null) {
        throw ApiFailure(message: 'Respuesta inválida al subir el archivo.');
      }

      return fileId;
    } on DioException catch (exception) {
      throw ApiFailure.fromDioException(exception);
    } on ApiFailure {
      rethrow;
    }
  }

  String? _normalize(String? value) {
    final String normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }
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
