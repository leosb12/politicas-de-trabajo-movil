import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:politicas_negocio_flutter/core/offline/mobile_snapshot_store.dart';
import 'package:politicas_negocio_flutter/core/offline/offline_queue_store.dart';
import 'package:politicas_negocio_flutter/core/offline/offline_initial_sync_service.dart';
import 'package:politicas_negocio_flutter/core/offline/offline_sync_service.dart';
import 'package:politicas_negocio_flutter/core/offline/health_check_service.dart';
import 'package:politicas_negocio_flutter/core/offline/offline_profile_store.dart';
import 'package:politicas_negocio_flutter/features/mobile_shell/data/datasources/offline_tramite_classifier.dart';
import 'package:politicas_negocio_flutter/features/mobile_shell/domain/models/tramite_disponible_item.dart';
import 'package:politicas_negocio_flutter/features/mobile_shell/data/repositories/iniciar_tramite_repository_impl.dart';
import 'package:politicas_negocio_flutter/features/mobile_shell/data/repositories/mis_tramites_repository_impl.dart';
import 'package:politicas_negocio_flutter/features/mobile_shell/domain/models/tramite_seguimiento.dart';

// Imports of models and mock data sources to resolve the compiler types
import 'package:politicas_negocio_flutter/features/mobile_shell/data/datasources/iniciar_tramite_mock_datasource.dart';
import 'package:politicas_negocio_flutter/features/mobile_shell/data/datasources/mis_tramites_mock_datasource.dart';
import 'package:politicas_negocio_flutter/features/mobile_shell/data/models/tarea_formulario_detalle_model.dart';
import 'package:politicas_negocio_flutter/features/mobile_shell/domain/models/mis_tramite_item.dart';
import 'package:politicas_negocio_flutter/features/mobile_shell/domain/models/tarea_formulario_detalle.dart';
import 'package:politicas_negocio_flutter/features/tramites/data/datasource/tramites_remote_datasource.dart';
import 'package:politicas_negocio_flutter/features/tramites/data/models/tramite_disponible_model.dart';
import 'package:politicas_negocio_flutter/features/tramites/data/models/instancia_iniciada_model.dart';

// ── Mock classes ──────────────────────────────────────────────────────────

class MockDio implements Dio {
  MockDio();

  Map<String, dynamic> responses = <String, dynamic>{};
  List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    requests.add(<String, dynamic>{
      'method': 'GET',
      'path': path,
      'data': data,
      'queryParameters': queryParameters,
    });
    final dynamic res = responses[path] ?? <String, dynamic>{};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: res as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    requests.add(<String, dynamic>{
      'method': 'POST',
      'path': path,
      'data': data,
      'queryParameters': queryParameters,
    });
    final dynamic res = responses[path] ?? <String, dynamic>{};
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: res as T,
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #options) {
      return BaseOptions();
    }
    return null;
  }
}

class MockConnectivityNotifier extends StateNotifier<bool>
    implements ConnectivityNotifier {
  MockConnectivityNotifier(super.state);

  @override
  bool get isOnline => state;

  void setOnline(bool online) {
    state = online;
  }
}

class MockIniciarTramiteDataSource implements IniciarTramiteDataSource {
  @override
  Future<ClasificacionSolicitudResult> clasificarSolicitud({
    required String actorUserId,
    required String texto,
    bool usarDeepSeek = false,
    String? nombreDocumento,
    bool isOffline = false,
    bool usarSoloRequisitosIniciales = false,
  }) async {
    return const ClasificacionSolicitudResult(
      politicaId: '',
      nombrePolitica: '',
      confianza: 0.0,
      origen: 'MOCK',
      metodoRecomendacion: 'MOCK',
      requiereMasInformacion: false,
      requiereConfirmacion: false,
      mensaje: '',
      topResultados: <ClasificacionSolicitudItem>[],
    );
  }

  @override
  Future<void> iniciarTramite({
    required String actorUserId,
    required String tramiteId,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  }) async {
    // remote initiate
  }

  @override
  Future<List<TramiteDisponibleItem>> obtenerTramitesActivos({
    required String actorUserId,
  }) async {
    return <TramiteDisponibleItem>[];
  }
}

class MockTramitesRemoteDataSource implements TramitesRemoteDataSource {
  @override
  Future<List<TramiteDisponibleModel>> obtenerDisponibles({required String actorUserId}) async => <TramiteDisponibleModel>[];
  @override
  Future<List<InstanciaIniciadaModel>> obtenerInstancias({required String actorUserId, String? estado}) async => <InstanciaIniciadaModel>[];
  @override
  Future<InstanciaIniciadaModel> iniciarTramite({required String actorUserId, required String politicaId, Map<String, dynamic>? respuestasRequisitosIniciales}) async => throw UnimplementedError();
  @override
  Future<List<CampoFormularioDetalleModel>> obtenerRequisitosIniciales({required String actorUserId, required String politicaId}) async => <CampoFormularioDetalleModel>[];
}

class MockMisTramitesDataSource implements MisTramitesDataSource {
  @override
  Future<List<MisTramiteItem>> obtenerMisTramites({required String usuarioId}) async => <MisTramiteItem>[];
  @override
  Future<TramiteSeguimiento> obtenerSeguimiento({required String usuarioId, required String instanciaId}) async => throw UnimplementedError();
  @override
  Future<DocumentoArchivoBinario> descargarDocumento({required String usuarioId, required String archivoId}) async => throw UnimplementedError();
  @override
  Future<void> editarDocumento({required String usuarioId, required String archivoId, required String nombreOriginal, required String descripcion}) async {}
  @override
  Future<void> eliminarDocumento({required String usuarioId, required String archivoId}) async {}
  @override
  Future<void> reemplazarDocumento({required String usuarioId, required String archivoId, required String nombreArchivo, required List<int> bytes}) async {}
  @override
  Future<DocumentoArchivoBinario> verDocumento({required String usuarioId, required String archivoId}) async => throw UnimplementedError();
}

// ── Main Test Suite ───────────────────────────────────────────────────────

void main() {
  late Directory tempDir;
  late Box<String> authBox;
  late Box<String> snapshotBox;
  late Box<String> queueBox;
  late Box<String> conflictsBox;

  late MobileSnapshotStore snapshotStore;
  late OfflineQueueStore queueStore;
  late OfflineProfileStore profileStore;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_offline_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    authBox = await Hive.openBox<String>('auth_test_${DateTime.now().millisecondsSinceEpoch}');
    snapshotBox = await Hive.openBox<String>('snapshot_test_${DateTime.now().millisecondsSinceEpoch}');
    queueBox = await Hive.openBox<String>('queue_test_${DateTime.now().millisecondsSinceEpoch}');
    conflictsBox = await Hive.openBox<String>('conflicts_test_${DateTime.now().millisecondsSinceEpoch}');

    snapshotStore = MobileSnapshotStore(snapshotBox);
    queueStore = OfflineQueueStore(queueBox: queueBox, conflictsBox: conflictsBox);
    profileStore = OfflineProfileStore(authBox);
  });

  tearDown(() async {
    await authBox.close();
    await snapshotBox.close();
    await queueBox.close();
    await conflictsBox.close();
  });

  test('Escenario 1: Sincronización inicial guarda políticas, requisitos y flujos base', () async {
    final MockDio mockDio = MockDio();
    final OfflineInitialSyncService syncService = OfflineInitialSyncService(
      dio: mockDio,
      profileStore: profileStore,
      snapshotStore: snapshotStore,
    );

    final String userId = 'user_123';

    // Mock response for dynamic catalog
    mockDio.responses['/api/politicas/movil/sincronizar'] = <String, dynamic>{
      'content': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'pol_1',
          'nombre': 'Renovación de Matrícula',
          'descripcion': 'Trámite para renovar matrícula',
          'categoria': 'Trámites Académicos',
          'palabrasClave': <String>['renovacion', 'matricula', 'estudiante'],
          'requierePago': false,
          'requisitosIniciales': <Map<String, dynamic>>[
            <String, dynamic>{
              'campo': 'documento_identidad',
              'tipo': 'ARCHIVO',
              'etiqueta': 'Documento de Identidad',
              'requerido': true,
            },
            <String, dynamic>{
              'campo': 'correo_estudiantil',
              'tipo': 'TEXTO',
              'etiqueta': 'Correo Institucional',
              'requerido': true,
            }
          ],
          'nodos': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'nodo_inicio', 'tipo': 'INICIO', 'nombre': 'Inicio'},
            <String, dynamic>{'id': 'nodo_fin', 'tipo': 'FIN', 'nombre': 'Fin'},
          ],
          'conexiones': <Map<String, dynamic>>[
            <String, dynamic>{'origen': 'nodo_inicio', 'destino': 'nodo_fin'}
          ],
        }
      ]
    };

    // Before sync state
    expect(snapshotStore.getLastSync(userId), isNull);
    expect(snapshotStore.getCatalogoPoliticas(userId), isNull);

    // Run sync
    final SyncResult result = await syncService.syncCompleto(userId: userId);
    expect(result.success, isTrue);

    // After sync checks
    expect(snapshotStore.getLastSync(userId), isNotNull);
    final List<dynamic>? catalog = snapshotStore.getCatalogoPoliticas(userId);
    expect(catalog, isNotNull);
    expect(catalog!.length, 1);
    expect(catalog.first['id'], 'pol_1');
    expect(catalog.first['nombre'], 'Renovación de Matrícula');
  });

  test('Escenario 2: Nueva política recomendada por el clasificador offline dinámico', () async {
    final String userId = 'user_456';
    final List<Map<String, dynamic>> dynamicCatalog = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'pol_cambio_titular',
        'nombre': 'Cambiar titular del servicio',
        'descripcion': 'Permite transferir la titularidad de una cuenta activa.',
        'categoria': 'Soporte',
        'palabrasClave': <String>['titularidad', 'nombre', 'propietario'],
        'requisitosIniciales': <Map<String, dynamic>>[
          <String, dynamic>{
            'campo': 'datos_titular_nuevo',
            'tipo': 'TEXTO',
            'etiqueta': 'Datos del titular nuevo',
            'requerido': true,
          }
        ]
      }
    ];
    await snapshotStore.saveCatalogoPoliticas(userId, dynamicCatalog);

    // Query match phrase in requirement
    final ClasificacionSolicitudResult classificationResult = OfflineTramiteClassifier.clasificar(
      texto: 'quiero cambiar los datos del titular',
      politicasEnCache: <TramiteDisponibleItem>[],
      catalogoDinamico: dynamicCatalog,
    );

    expect(classificationResult.politicaId, 'pol_cambio_titular');
    expect(classificationResult.confianza, greaterThan(0.0));
    expect(classificationResult.metodoRecomendacion, 'OFFLINE_CATALOGO_LOCAL');
  });

  test('Escenario 3: Inicio de trámite offline con requisitos y dibujo del flujo base', () async {
    final String userId = 'user_789';
    final MockConnectivityNotifier connectivity = MockConnectivityNotifier(false);
    final MockIniciarTramiteDataSource remoteDS = MockIniciarTramiteDataSource();
    final IniciarTramiteRepositoryImpl repository = IniciarTramiteRepositoryImpl(
      remoteDataSource: remoteDS,
      snapshotStore: snapshotStore,
      queueStore: queueStore,
      connectivity: connectivity,
    );

    final List<Map<String, dynamic>> dynamicCatalog = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'pol_1',
        'nombre': 'Trámite Especial',
        'requierePago': false,
        'requisitosIniciales': <Map<String, dynamic>>[
          <String, dynamic>{'campo': 'identidad', 'tipo': 'TEXTO'}
        ],
        'nodos': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'n1', 'tipo': 'INICIO', 'nombre': 'Comienzo'}
        ],
        'conexiones': <Map<String, dynamic>>[]
      }
    ];
    await snapshotStore.saveCatalogoPoliticas(userId, dynamicCatalog);

    // Add to lightweight available catalog to resolve tramiteName inside repo
    await snapshotStore.saveTramitesDisponibles(userId, <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'pol_1',
        'nombre': 'Trámite Especial',
        'tieneRequisitosIniciales': true,
      }
    ]);

    // Perform offline start
    await repository.iniciarTramite(
      actorUserId: userId,
      tramiteId: 'pol_1',
      respuestasRequisitosIniciales: <String, dynamic>{
        'identidad': 'Leo'
      },
    );

    // Check card added to cache with PENDIENTE_SINCRONIZACION
    final List<dynamic>? cards = snapshotStore.getMisTramites(userId);
    expect(cards, isNotNull);
    expect(cards!.length, 1);
    expect(cards.first['estadoLocal'], 'PENDIENTE_SINCRONIZACION');
    expect(cards.first['esOffline'], isTrue);

    // Check queue has 1 pending create request
    expect(queueStore.pendingCount, 1);
    final OfflineQueueItem item = queueStore.getAll().first;
    expect(item.endpoint, '/api/instancias');
    expect(item.body!['politicaId'], 'pol_1');

    // Check that we can construct the flowchart mockup offline
    final MisTramitesRepositoryImpl misTramitesRepo = MisTramitesRepositoryImpl(
      remoteDataSource: MockMisTramitesDataSource(),
      snapshotStore: snapshotStore,
      connectivity: connectivity,
    );
    final TramiteSeguimiento offlineFlow = await misTramitesRepo.obtenerSeguimiento(
      usuarioId: userId,
      instanciaId: cards.first['id'],
    );
    expect(offlineFlow.nodos.length, 1);
    expect(offlineFlow.nodos.first.nombre, 'Comienzo');
  });

  test('Escenario 4 y 5: Reconexión, sincronización, subida de archivos, resolución de ID e idempotencia', () async {
    final String userId = 'user_999';
    final MockDio mockDio = MockDio();
    final MockConnectivityNotifier connectivity = MockConnectivityNotifier(false);

    final OfflineSyncService syncService = OfflineSyncService(
      dio: mockDio,
      connectivity: connectivity,
      queue: queueStore,
      snapshotStore: snapshotStore,
    );

    // Enqueue an offline start request that contains an offline file requirement
    final String localId = 'local_abc';
    final OfflineQueueItem item = OfflineQueueItem(
      id: 'queue_1',
      method: 'POST',
      endpoint: '/api/instancias',
      entityType: OfflineEntityType.instanciaTramite,
      userId: userId,
      localId: localId,
      body: <String, dynamic>{
        'politicaId': 'pol_1',
        'respuestasRequisitosIniciales': <String, dynamic>{
          'archivo_campo': <String, dynamic>{
            'isOfflineFile': true,
            'base64': 'SGVsbG8gV29ybGQ=', // "Hello World"
            'nombreOriginal': 'mi_dni.pdf'
          }
        }
      },
      headers: <String, String>{'X-User-Id': userId},
      createdAt: DateTime.now(),
    );
    await queueStore.enqueue(item);

    // Save local card snapshot
    await snapshotStore.saveMisTramites(userId, <Map<String, dynamic>>[
      <String, dynamic>{
        'id': localId,
        'nombre': 'Trámite con Archivo',
        'politicaId': 'pol_1',
        'estado': 'PENDIENTE_SINCRONIZACION',
        'esOffline': true,
      }
    ]);

    // Save local flow nodes mapping
    await snapshotStore.saveSeguimiento(userId, localId, <String, dynamic>{
      'instanciaId': localId,
      'nodos': <dynamic>[],
      'esOffline': true,
    });

    // Mock upload response
    mockDio.responses['/api/archivos'] = <String, dynamic>{
      'id': 'server_file_888',
      'nombreOriginal': 'mi_dni.pdf'
    };

    // Mock creation response with nested "instancia"
    mockDio.responses['/api/instancias'] = <String, dynamic>{
      'politicaId': 'pol_1',
      'politicaNombre': 'Trámite con Archivo',
      'instancia': <String, dynamic>{
        'id': 'real_server_instancia_555',
        'codigoTramite': 'T-0099',
        'estadoInstancia': 'EN_CURSO',
        'porcentaje': 15,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'creadaPor': userId
      }
    };

    // Go online
    connectivity.setOnline(true);
    await syncService.forceSyncNow();

    // Verify queue is empty (processed successfully)
    expect(queueStore.pendingCount, 0);

    // Verify file upload was performed
    final Map<String, dynamic> uploadRequest = mockDio.requests.firstWhere((r) => r['path'] == '/api/archivos');
    expect(uploadRequest['method'], 'POST');

    // Verify card snapshot was resolved correctly
    final List<dynamic>? cards = snapshotStore.getMisTramites(userId);
    expect(cards, isNotNull);
    expect(cards!.length, 1);
    expect(cards.first['id'], 'real_server_instancia_555');
    expect(cards.first['estadoInstancia'], 'EN_CURSO');
    expect(cards.first['esOffline'], isFalse);

    // Verify local flowchart migrated
    final Map<String, dynamic>? resolvedSeg = snapshotStore.getSeguimiento(userId, 'real_server_instancia_555');
    expect(resolvedSeg, isNotNull);
    expect(resolvedSeg!['instanciaId'], 'real_server_instancia_555');
    expect(resolvedSeg['esOffline'], isFalse);

    // Idempotency: Run sync again, confirm nothing happens
    mockDio.requests.clear();
    await syncService.forceSyncNow();
    expect(mockDio.requests.isEmpty, isTrue);
  });

  test('Escenario 6: Eliminar datos offline no borra la cola de solicitudes pendientes', () async {
    final String userId = 'user_abc';

    // Enqueue a request
    await queueStore.enqueue(OfflineQueueItem(
      id: 'item_pending',
      method: 'POST',
      endpoint: '/api/instancias',
      entityType: OfflineEntityType.instanciaTramite,
      userId: userId,
      createdAt: DateTime.now(),
    ));

    // Save catalog and sync timestamps
    await snapshotStore.saveCatalogoPoliticas(userId, <dynamic>[<String, dynamic>{'id': 'pol_1'}]);
    await snapshotStore.saveLastSync(userId);

    // Check we have data
    expect(snapshotStore.getLastSync(userId), isNotNull);
    expect(snapshotStore.getCatalogoPoliticas(userId), isNotNull);
    expect(queueStore.pendingCount, 1);

    // Clear data
    await snapshotStore.clearOfflineData(userId);

    // Check catalog is cleared, but queue remains untouched!
    expect(snapshotStore.getLastSync(userId), isNull);
    expect(snapshotStore.getCatalogoPoliticas(userId), isNull);
    expect(queueStore.pendingCount, 1);
  });

  test('Caso 2 y 3: Offline con casilla apagada vs encendida - Priorización por Requisitos', () async {
    final String userId = 'user_test_priorities';
    final List<Map<String, dynamic>> dynamicCatalog = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'pol_wifi_instalacion',
        'nombre': 'Solicitar instalación de internet WiFi',
        'descripcion': 'Inicia el proceso para solicitar la instalación de internet WiFi.',
        'categoria': 'Servicios',
        'palabrasClave': <String>['instalar', 'wifi', 'internet'],
        'requisitosIniciales': <Map<String, dynamic>>[
          <String, dynamic>{
            'campo': 'codigo_cliente',
            'tipo': 'TEXTO',
            'etiqueta': 'Código de cliente',
            'requerido': true,
          }
        ]
      }
    ];

    // Caso 2: Casilla apagada -> No prioriza por requisito inicial.
    final ClasificacionSolicitudResult resultApagada = OfflineTramiteClassifier.clasificar(
      texto: 'mi código de cliente es 123',
      politicasEnCache: <TramiteDisponibleItem>[],
      catalogoDinamico: dynamicCatalog,
      usarSoloRequisitosIniciales: false,
    );
    // Debe quedar como "No determinado" o tener score muy bajo porque los requisitos no se puntúan
    expect(resultApagada.politicaId, isEmpty);

    // Caso 3: Casilla encendida -> Prioriza por requisito inicial "Código de cliente".
    final ClasificacionSolicitudResult resultEncendida = OfflineTramiteClassifier.clasificar(
      texto: 'mi código de cliente es 123',
      politicasEnCache: <TramiteDisponibleItem>[],
      catalogoDinamico: dynamicCatalog,
      usarSoloRequisitosIniciales: true,
    );
    expect(resultEncendida.politicaId, 'pol_wifi_instalacion');
    expect(resultEncendida.mensaje, 'Recomendación offline generada usando políticas y requisitos iniciales sincronizados.');
  });

  test('Caso 4: Offline con casilla encendida - Priorización por Comprobante de Domicilio', () async {
    final String userId = 'user_test_domicilio';
    final List<Map<String, dynamic>> dynamicCatalog = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'pol_traslado_servicio',
        'nombre': 'Solicitar traslado de servicio',
        'descripcion': 'Muda tu servicio de internet a un nuevo domicilio.',
        'categoria': 'Mudar',
        'palabrasClave': <String>['traslado', 'mudanza'],
        'requisitosIniciales': <Map<String, dynamic>>[
          <String, dynamic>{
            'campo': 'comprobante_domicilio',
            'tipo': 'ARCHIVO',
            'etiqueta': 'Comprobante de domicilio',
            'requerido': true,
          }
        ]
      }
    ];

    final ClasificacionSolicitudResult result = OfflineTramiteClassifier.clasificar(
      texto: 'tengo comprobante de domicilio',
      politicasEnCache: <TramiteDisponibleItem>[],
      catalogoDinamico: dynamicCatalog,
      usarSoloRequisitosIniciales: true,
    );
    expect(result.politicaId, 'pol_traslado_servicio');
  });

  test('Caso 5: Offline con casilla apagada - Sigue recomendando por palabras clave', () async {
    final String userId = 'user_test_kw';
    final List<Map<String, dynamic>> dynamicCatalog = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'pol_wifi_cambio_plan',
        'nombre': 'Cambiar plan de internet',
        'descripcion': 'Permite cambiar tu plan actual de internet.',
        'categoria': 'Servicios',
        'palabrasClave': <String>['cambiar plan', 'plan de internet'],
        'requisitosIniciales': <Map<String, dynamic>>[
          <String, dynamic>{
            'campo': 'documento_identidad',
            'tipo': 'ARCHIVO',
            'etiqueta': 'Documento de identidad',
          }
        ]
      }
    ];

    final ClasificacionSolicitudResult result = OfflineTramiteClassifier.clasificar(
      texto: 'quiero cambiar mi plan de internet',
      politicasEnCache: <TramiteDisponibleItem>[],
      catalogoDinamico: dynamicCatalog,
      usarSoloRequisitosIniciales: false,
    );
    expect(result.politicaId, 'pol_wifi_cambio_plan');
    expect(result.mensaje, 'Recomendación offline generada usando el catálogo local de políticas.');
  });

  test('Caso 6, 7 y 8: Offline - Detección automática por nombre de archivo y ambigüedad', () {
    // Definimos algunos requisitos de tipo archivo
    final CampoFormularioDetalle ModelIdentidad = CampoFormularioDetalle(
      clave: 'doc_identidad',
      tipo: 'ARCHIVO',
      etiqueta: 'Documento de identidad',
    );
    final CampoFormularioDetalle ModelDomicilio = CampoFormularioDetalle(
      clave: 'comp_domicilio',
      tipo: 'ARCHIVO',
      etiqueta: 'Comprobante de domicilio',
    );

    // Caso 6: carnet_identidad.pdf -> Debe detectar "Documento de identidad" (score >= 5)
    final double scoreIdentidad = OfflineRequisitoDetector.calcularScoreRequisito(
      nombreArchivo: 'carnet_identidad.pdf',
      clave: ModelIdentidad.clave,
      etiqueta: ModelIdentidad.etiqueta ?? '',
      ayuda: '',
    );
    expect(scoreIdentidad, greaterThanOrEqualTo(5.0));

    // Caso 7: factura_luz_domicilio.jpg -> Debe detectar "Comprobante de domicilio" (score >= 5)
    final double scoreDomicilio = OfflineRequisitoDetector.calcularScoreRequisito(
      nombreArchivo: 'factura_luz_domicilio.jpg',
      clave: ModelDomicilio.clave,
      etiqueta: ModelDomicilio.etiqueta ?? '',
      ayuda: '',
    );
    expect(scoreDomicilio, greaterThanOrEqualTo(5.0));

    // Caso 8: documento.pdf -> Archivo ambiguo, no debe ser autodetectado (score < 3)
    final double scoreAmbiguo = OfflineRequisitoDetector.calcularScoreRequisito(
      nombreArchivo: 'documento.pdf',
      clave: ModelDomicilio.clave,
      etiqueta: ModelDomicilio.etiqueta ?? '',
      ayuda: '',
    );
    expect(scoreAmbiguo, lessThan(3.0));
  });

  test('Caso 9: Reconexión de trámite offline con archivo autodetectado', () async {
    final String userId = 'user_recon';
    final MockDio mockDio = MockDio();
    final MockConnectivityNotifier connectivity = MockConnectivityNotifier(false);

    final OfflineSyncService syncService = OfflineSyncService(
      dio: mockDio,
      connectivity: connectivity,
      queue: queueStore,
      snapshotStore: snapshotStore,
    );

    // Encolar solicitud offline con archivo autodetectado
    final String localId = 'local_recon_123';
    final OfflineQueueItem item = OfflineQueueItem(
      id: 'queue_recon',
      method: 'POST',
      endpoint: '/api/instancias',
      entityType: OfflineEntityType.instanciaTramite,
      userId: userId,
      localId: localId,
      body: <String, dynamic>{
        'politicaId': 'pol_1',
        'respuestasRequisitosIniciales': <String, dynamic>{
          'doc_identidad': <String, dynamic>{
            'isOfflineFile': true,
            'base64': 'SGVsbG8gV29ybGQ=', // "Hello World"
            'nombreOriginal': 'carnet_identidad.pdf',
            'requisitoId': 'doc_identidad',
            'nombreRequisito': 'Documento de identidad',
            'archivoLocalId': 'local_file_999',
            'nombreArchivo': 'carnet_identidad.pdf',
            'detectadoOffline': true,
            'metodoDeteccion': 'NOMBRE_ARCHIVO',
            'confianzaDeteccion': 0.8333
          }
        }
      },
      headers: <String, String>{'X-User-Id': userId},
      createdAt: DateTime.now(),
    );
    await queueStore.enqueue(item);

    // Mock upload response
    mockDio.responses['/api/archivos'] = <String, dynamic>{
      'id': 'real_file_555',
      'nombreOriginal': 'carnet_identidad.pdf'
    };

    // Mock creation response
    mockDio.responses['/api/instancias'] = <String, dynamic>{
      'politicaId': 'pol_1',
      'politicaNombre': 'Trámite Especial',
      'instancia': <String, dynamic>{
        'id': 'real_instancia_999',
        'codigoTramite': 'T-1000',
        'estadoInstancia': 'EN_CURSO',
        'porcentaje': 0,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'creadaPor': userId
      }
    };

    // Ir a online y forzar sync
    connectivity.setOnline(true);
    await syncService.forceSyncNow();

    // Confirmar que la cola está vacía
    expect(queueStore.pendingCount, 0);

    // Confirmar que el cuerpo enviado a /api/instancias tenía el ID real y conservó la asociación
    final Map<String, dynamic> req = mockDio.requests.firstWhere((r) => r['path'] == '/api/instancias');
    final dynamic reqsMap = req['data']['respuestasRequisitosIniciales'];
    expect(reqsMap['doc_identidad']['archivoId'], 'real_file_555');
    expect(reqsMap['doc_identidad']['nombreOriginal'], 'carnet_identidad.pdf');
    // La metadata offline isOfflineFile y base64 debe haber sido depurada para el backend
    expect(reqsMap['doc_identidad']['isOfflineFile'], isNull);
    expect(reqsMap['doc_identidad']['base64'], isNull);
  });
}
