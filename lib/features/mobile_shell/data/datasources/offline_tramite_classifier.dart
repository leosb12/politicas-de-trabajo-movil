import '../../domain/models/tramite_disponible_item.dart';

class OfflineTramiteClassifier {
  const OfflineTramiteClassifier._();

  static const double _minThreshold = 3.0;

  static final List<_PolicySpec> _policySpecs = <_PolicySpec>[
    const _PolicySpec(
      id: 'wifi_instalacion',
      nombre: 'Solicitar instalación de internet WiFi',
      descripcion: 'Inicia el proceso para solicitar la instalación de internet WiFi en tu domicilio u oficina.',
      palabrasClave: <String>[
        'instalar', 'instalacion', 'wifi', 'internet', 'nuevo servicio',
        'domicilio', 'oficina', 'contratar internet', 'poner internet', 'servicio wifi'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_cambio_plan',
      nombre: 'Cambiar plan de internet',
      descripcion: 'Permite al cliente cambiar su plan actual de internet por uno de mayor o menor velocidad según sus necesidades.',
      palabrasClave: <String>[
        'cambiar plan', 'plan de internet', 'subir plan', 'bajar plan', 'mayor velocidad',
        'menor velocidad', 'cambiar velocidad', 'modificar plan', 'plan actual'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_mejorar_velocidad',
      nombre: 'Mejorar velocidad de internet',
      descripcion: 'Solicita un aumento de la velocidad de tu internet para una mejor navegación.',
      palabrasClave: <String>[
        'mejorar velocidad', 'internet lento', 'velocidad baja', 'mas velocidad',
        'navegacion lenta', 'aumentar velocidad', 'lentitud', 'lento'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_internet_caido',
      nombre: 'Reportar internet caído',
      descripcion: 'Reporta un corte total en el servicio de internet.',
      palabrasClave: <String>[
        'internet caido', 'sin internet', 'no tengo internet', 'corte', 'sin conexion',
        'caido', 'no funciona internet', 'falla total', 'servicio caido'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_internet_lento',
      nombre: 'Reportar internet lento',
      descripcion: 'Reporta problemas de lentitud o intermitencia en la red WiFi.',
      palabrasClave: <String>[
        'internet lento', 'lentitud', 'baja velocidad', 'demora', 'navegacion lenta',
        'intermitente', 'inestable', 'se corta', 'lag'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_cambiar_password',
      nombre: 'Cambiar contraseña del WiFi',
      descripcion: 'Cambia la clave de acceso de tu red WiFi para mayor seguridad.',
      palabrasClave: <String>[
        'cambiar contrasena', 'contraseña wifi', 'clave wifi', 'password wifi',
        'nueva clave', 'seguridad wifi', 'cambiar clave'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_cambiar_nombre_red',
      nombre: 'Cambiar nombre de la red WiFi',
      descripcion: 'Cambia el SSID o nombre visible de tu red WiFi.',
      palabrasClave: <String>[
        'cambiar nombre wifi', 'nombre de red', 'ssid', 'cambiar ssid',
        'nombre visible', 'red wifi'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_visita_tecnica',
      nombre: 'Solicitar visita técnica',
      descripcion: 'Agenda la visita de un técnico para revisar tus equipos o cableado.',
      palabrasClave: <String>[
        'visita tecnica', 'tecnico', 'revisar modem', 'revisar router', 'cableado',
        'asistencia tecnica', 'enviar tecnico', 'soporte tecnico en casa'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_reprogramar_visita',
      nombre: 'Reprogramar visita técnica',
      descripcion: 'Cambia la fecha u hora de una visita técnica previamente agendada.',
      palabrasClave: <String>[
        'reprogramar visita', 'cambiar fecha', 'cambiar horario',
        'visita tecnica programada', 'mover cita', 'reagendar visita'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_estado_instalacion',
      nombre: 'Consultar estado de instalación',
      descripcion: 'Consulta el avance o fecha de instalación programada para tu nuevo servicio.',
      palabrasClave: <String>[
        'estado instalacion', 'consultar instalacion', 'seguimiento instalacion',
        'cuando instalan', 'activacion servicio', 'estado de solicitud'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_traslado_servicio',
      nombre: 'Solicitar traslado de servicio',
      descripcion: 'Solicita mudar tu servicio de internet a un nuevo domicilio.',
      palabrasClave: <String>[
        'traslado', 'mudanza', 'cambiar direccion', 'nueva direccion',
        'mover servicio', 'trasladar internet', 'cambio de domicilio'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_actualizar_datos',
      nombre: 'Actualizar datos del titular',
      descripcion: 'Modifica tu información de contacto personal en el sistema.',
      palabrasClave: <String>[
        'actualizar datos', 'datos titular', 'telefono', 'correo',
        'documento', 'contacto', 'cambiar datos personales'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_cambio_titular',
      nombre: 'Cambiar titular del servicio',
      descripcion: 'Transfiere la titularidad del contrato de servicio a otra persona.',
      palabrasClave: <String>[
        'cambiar titular', 'titularidad', 'cambio de titular',
        'pasar servicio a otra persona', 'nuevo titular'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_consultar_factura',
      nombre: 'Consultar factura',
      descripcion: 'Revisa tu saldo pendiente, fecha de vencimiento o descarga tu factura actual.',
      palabrasClave: <String>[
        'factura', 'consultar factura', 'monto a pagar', 'periodo facturado',
        'deuda', 'ver factura', 'facturacion'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_reclamo_cobro',
      nombre: 'Reclamar cobro incorrecto',
      descripcion: 'Inicia un reclamo por cargos indebidos o montos incorrectos en tu facturación.',
      palabrasClave: <String>[
        'cobro incorrecto', 'me cobraron de mas', 'reclamo factura',
        'monto incorrecto', 'factura mal', 'cargo indebido', 'cobro de mas'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_duplicado_factura',
      nombre: 'Solicitar duplicado de factura',
      descripcion: 'Solicita una copia o duplicado de facturas de periodos anteriores.',
      palabrasClave: <String>[
        'duplicado factura', 'copia factura', 'reenviar factura',
        'factura anterior', 'solicitar copia'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_registrar_pago',
      nombre: 'Registrar comprobante de pago',
      descripcion: 'Reporta y sube tu comprobante de pago para registrar la transacción en el sistema.',
      palabrasClave: <String>[
        'comprobante pago', 'registrar pago', 'subir comprobante',
        'validar pago', 'pague factura', 'pago realizado'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_reconexion',
      nombre: 'Solicitar reconexión de servicio',
      descripcion: 'Solicita restablecer tu servicio luego de haber realizado el pago pendiente.',
      palabrasClave: <String>[
        'reconexion', 'reconectar', 'restablecer servicio',
        'servicio suspendido', 'corte por deuda', 'volver a activar'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_baja_servicio',
      nombre: 'Solicitar baja del servicio',
      descripcion: 'Inicia el trámite para dar de baja tu contrato o cancelar el servicio de internet.',
      palabrasClave: <String>[
        'baja servicio', 'cancelar servicio', 'dar de baja',
        'cancelar internet', 'terminar contrato', 'anular servicio'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_soporte_modem_router',
      nombre: 'Solicitar soporte por modem o router',
      descripcion: 'Soporte técnico ante problemas con el módem o router WiFi.',
      palabrasClave: <String>[
        'modem', 'router', 'equipo', 'problema modem', 'problema router',
        'configuracion router', 'luces modem', 'no prende modem'
      ],
    ),
    const _PolicySpec(
      id: 'wifi_cambio_equipo',
      nombre: 'Solicitar cambio de equipo',
      descripcion: 'Solicita el reemplazo de tu módem o router por daño o antigüedad.',
      palabrasClave: <String>[
        'cambiar equipo', 'reemplazar modem', 'reemplazar router',
        'equipo dañado', 'modem viejo', 'router viejo', 'equipo antiguo'
      ],
    ),
    const _PolicySpec(
      id: 'solicitud_reparacion_tecnica',
      nombre: 'Solicitud de Reparación Técnica',
      descripcion: 'Reporta averías físicas o fallas en los equipos de telecomunicaciones para su reparación.',
      palabrasClave: <String>[
        'reparacion tecnica', 'reparar', 'falla tecnica', 'equipo dañado',
        'sistema dañado', 'problema tecnico', 'arreglo'
      ],
    ),
    const _PolicySpec(
      id: 'solicitud_megas_ilimitados',
      nombre: 'Solicitud de Plan de Megas Ilimitados',
      descripcion: 'Solicitud de planes de megas ilimitados corporativos.',
      palabrasClave: <String>[
        'megas ilimitados', 'datos ilimitados', 'plan ilimitado',
        'internet movil ilimitado', 'celular corporativo', 'datos moviles'
      ],
    ),
    const _PolicySpec(
      id: 'cambio_compania',
      nombre: 'Política para cambiar de compañía',
      descripcion: 'Trámite y portabilidad para cambiar a otro operador.',
      palabrasClave: <String>[
        'cambiar compañia', 'cambiar empresa', 'portabilidad',
        'cambiar proveedor', 'pasarme a otra compañia'
      ],
    ),
    const _PolicySpec(
      id: 'politica_internos',
      nombre: 'politica para internos',
      descripcion: 'Trámite exclusivo para personal interno y empleados.',
      palabrasClave: <String>[
        'interno', 'internos', 'personal interno', 'empleado', 'politica interna'
      ],
    ),
    const _PolicySpec(
      id: 'politica_ser_parte_equipo',
      nombre: 'politica para ser parte del equipo',
      descripcion: 'Formulario y requisitos para unirse a trabajar en el equipo.',
      palabrasClave: <String>[
        'ser parte del equipo', 'unirse al equipo', 'trabajar con ustedes',
        'formar parte', 'equipo', 'postulacion', 'empleo'
      ],
    ),
  ];

  static String _normalize(String text) {
    String normalized = text.toLowerCase().trim();
    // Reemplazar acentos
    final Map<String, String> accents = <String, String>{
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'ü': 'u', 'ñ': 'n'
    };
    accents.forEach((String key, String value) {
      normalized = normalized.replaceAll(key, value);
    });
    // Quitar signos y dejar solo alfanuméricos y espacios
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    // Limpiar espacios duplicados
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return normalized.trim();
  }

  static ClasificacionSolicitudResult clasificar({
    required String texto,
    String? nombreDocumento,
    required List<TramiteDisponibleItem> politicasEnCache,
    List<dynamic>? catalogoDinamico,
    bool usarSoloRequisitosIniciales = false,
  }) {
    final bool tieneCatalogo = catalogoDinamico != null && catalogoDinamico.isNotEmpty;

    final String query = _normalize(texto);
    final String docQuery = nombreDocumento != null ? _normalize(nombreDocumento) : '';
    final String fullQuery = '$query $docQuery'.trim();
    final List<String> queryWords = fullQuery.split(' ');

    if (tieneCatalogo) {
      final List<_DynamicMatchScore> matches = <_DynamicMatchScore>[];

      for (final dynamic item in catalogoDinamico) {
        if (item is! Map) continue;
        final Map<String, dynamic> policy = Map<String, dynamic>.from(item);
        final String id = policy['id']?.toString() ?? '';
        final String nombre = policy['nombre']?.toString() ?? '';
        final String descripcion = policy['descripcion']?.toString() ?? '';
        final String categoria = policy['categoria']?.toString() ?? 'Trámite';
        final List<dynamic> palabrasClave = policy['palabrasClave'] as List? ?? [];
        final List<dynamic> requisitos = policy['requisitosIniciales'] as List? ?? [];

        double score = 0.0;
        final String normName = _normalize(nombre);
        final String normDesc = _normalize(descripcion);
        final String normCat = _normalize(categoria);

        // 1. Frase exacta en nombre: +6
        if (fullQuery.isNotEmpty && normName.contains(fullQuery)) {
          score += 6.0;
        }

        // 2. Frase exacta en palabras clave: +5
        for (final dynamic kw in palabrasClave) {
          final String normKw = _normalize(kw?.toString() ?? '');
          if (normKw.isNotEmpty && fullQuery.isNotEmpty && fullQuery.contains(normKw)) {
            score += 5.0;
          }
        }

        // 3. Coincidencia en requisito inicial (solo si usarSoloRequisitosIniciales es true):
        if (usarSoloRequisitosIniciales) {
          for (final dynamic req in requisitos) {
            if (req is Map) {
              final String normReqCampo = _normalize(req['campo']?.toString() ?? '');
              final String normReqEtiqueta = _normalize(req['etiqueta']?.toString() ?? '');
              final String normReqAyuda = _normalize(req['ayuda']?.toString() ?? '');
              final String normReqTipo = _normalize(req['tipo']?.toString() ?? '');
              final List<dynamic> reqKws = req['palabrasClave'] as List? ?? [];

              double reqScore = 0.0;

              // - frase exacta del requisito inicial en el texto: +5
              if ((normReqEtiqueta.isNotEmpty && OfflineRequisitoDetector.containsWordOrPhrase(fullQuery, normReqEtiqueta)) ||
                  (normReqCampo.isNotEmpty && OfflineRequisitoDetector.containsWordOrPhrase(fullQuery, normReqCampo))) {
                reqScore = reqScore > 5.0 ? reqScore : 5.0;
              }

              // - coincidencia con sinónimo fuerte: +4
              String? grupoEncontrado;
              for (final String grupo in OfflineRequisitoDetector._sinonimos.keys) {
                if (normReqEtiqueta.contains(grupo) || normReqCampo.contains(grupo) || grupo.contains(normReqEtiqueta) || grupo.contains(normReqCampo)) {
                  grupoEncontrado = grupo;
                  break;
                }
              }
              if (grupoEncontrado == null) {
                if (normReqEtiqueta.contains('cliente') || normReqCampo.contains('cliente') || normReqEtiqueta.contains('codigo') || normReqCampo.contains('codigo')) {
                  grupoEncontrado = 'codigo de cliente';
                } else if (normReqEtiqueta.contains('identidad') || normReqCampo.contains('identidad') || normReqEtiqueta.contains('dni') || normReqCampo.contains('dni') || normReqEtiqueta.contains('carnet') || normReqCampo.contains('carnet') || normReqEtiqueta.contains('cedula') || normReqCampo.contains('cedula')) {
                  grupoEncontrado = 'documento de identidad';
                } else if (normReqEtiqueta.contains('domicilio') || normReqCampo.contains('domicilio') || normReqEtiqueta.contains('direccion') || normReqCampo.contains('direccion')) {
                  grupoEncontrado = 'comprobante de domicilio';
                } else if (normReqEtiqueta.contains('pago') || normReqCampo.contains('pago') || normReqEtiqueta.contains('deposito') || normReqCampo.contains('deposito') || normReqEtiqueta.contains('transferencia') || normReqCampo.contains('transferencia')) {
                  grupoEncontrado = 'comprobante de pago';
                } else if (normReqEtiqueta.contains('factura') || normReqCampo.contains('factura')) {
                  grupoEncontrado = 'factura';
                } else if (normReqEtiqueta.contains('titular') || normReqCampo.contains('titular')) {
                  grupoEncontrado = 'titular';
                }
              }
              if (grupoEncontrado != null) {
                final List<String> sinonimosGrupo = OfflineRequisitoDetector._sinonimos[grupoEncontrado] ?? [];
                for (final String sinonimo in sinonimosGrupo) {
                  if (OfflineRequisitoDetector.containsWordOrPhrase(fullQuery, sinonimo)) {
                    reqScore = reqScore > 4.0 ? reqScore : 4.0;
                    break;
                  }
                }
              }

              // - palabra importante del requisito en el texto: +3
              final List<String> reqLabelWords = normReqEtiqueta.split(' ');
              final List<String> reqCampoWords = normReqCampo.split(' ');
              bool hasImportantWordMatch = false;
              for (final String word in queryWords) {
                if (word.length > 3 && (reqLabelWords.contains(word) || reqCampoWords.contains(word))) {
                  hasImportantWordMatch = true;
                  break;
                }
              }
              if (hasImportantWordMatch) {
                reqScore = reqScore > 3.0 ? reqScore : 3.0;
              }

              // - coincidencia en descripción del requisito: +2
              final List<String> reqAyudaWords = normReqAyuda.split(' ');
              bool hasAyudaMatch = false;
              for (final String word in queryWords) {
                if (word.length > 3 && reqAyudaWords.contains(word)) {
                  hasAyudaMatch = true;
                  break;
                }
              }
              if (hasAyudaMatch) {
                reqScore = reqScore > 2.0 ? reqScore : 2.0;
              }

              // - coincidencia débil: +1
              bool hasWeakMatch = false;
              if (normReqTipo.isNotEmpty && OfflineRequisitoDetector.containsWordOrPhrase(fullQuery, normReqTipo)) {
                hasWeakMatch = true;
              }
              for (final dynamic kw in reqKws) {
                final String kwNorm = _normalize(kw?.toString() ?? '');
                if (kwNorm.isNotEmpty && OfflineRequisitoDetector.containsWordOrPhrase(fullQuery, kwNorm)) {
                  hasWeakMatch = true;
                  break;
                }
              }
              if (hasWeakMatch) {
                reqScore = reqScore > 1.0 ? reqScore : 1.0;
              }

              score += reqScore;
            }
          }
        }

        // 4. Palabra importante en nombre: +3
        final List<String> nameWords = normName.split(' ');
        for (final String word in nameWords) {
          if (word.length > 3 && queryWords.contains(word)) {
            score += 3.0;
          }
        }

        // 5. Palabra en descripción: +2
        final List<String> descWords = normDesc.split(' ');
        for (final String word in descWords) {
          if (word.length > 3 && queryWords.contains(word)) {
            score += 2.0;
          }
        }

        // 6. Palabra en categoría: +1
        final List<String> catWords = normCat.split(' ');
        for (final String word in catWords) {
          if (word.length > 3 && queryWords.contains(word)) {
            score += 1.0;
          }
        }

        if (score > 0) {
          matches.add(_DynamicMatchScore(
            id: id,
            nombre: nombre,
            descripcion: descripcion,
            score: score,
            policy: policy,
          ));
        }
      }

      matches.sort((a, b) => b.score.compareTo(a.score));

      if (matches.isEmpty || matches.first.score < _minThreshold) {
        return ClasificacionSolicitudResult(
          politicaId: '',
          nombrePolitica: 'No determinado',
          confianza: 0.0,
          origen: 'CLASIFICADOR_LOCAL_FLUTTER',
          metodoRecomendacion: 'OFFLINE_CATALOGO_LOCAL',
          requiereMasInformacion: true,
          requiereConfirmacion: false,
          mensaje: 'No se pudo determinar un trámite claro con el catálogo sincronizado localmente. Intenta describir tu necesidad con otras palabras.',
          topResultados: const <ClasificacionSolicitudItem>[],
        );
      }

      final _DynamicMatchScore bestMatch = matches.first;
      final double bestScore = bestMatch.score;

      final List<_DynamicMatchScore> closeMatches = matches
          .where((m) => m.score >= (bestScore - 2.0))
          .toList();

      final List<ClasificacionSolicitudItem> topResultados = closeMatches.map((m) {
        final double normalizedConf = (m.score / 15.0).clamp(0.1, 0.99);
        final double confidence = double.parse(normalizedConf.toStringAsFixed(4));

        return ClasificacionSolicitudItem(
          politicaId: m.id,
          nombrePolitica: m.nombre,
          confianza: confidence,
          scoreFinal: confidence,
          scoreSemantico: confidence,
          scoreRequisitos: 0.0,
        );
      }).toList();

      final double normBestConf = (bestScore / 15.0).clamp(0.1, 0.99);
      final double finalConfidence = double.parse(normBestConf.toStringAsFixed(4));

      final bool requiereMasInfo = closeMatches.length > 1 && (bestScore - closeMatches[1].score) <= 1.0;

      final String mensajeExplicacion = usarSoloRequisitosIniciales
          ? 'Recomendación offline generada usando políticas y requisitos iniciales sincronizados.'
          : 'Recomendación offline generada usando el catálogo local de políticas.';

      return ClasificacionSolicitudResult(
        politicaId: bestMatch.id,
        nombrePolitica: bestMatch.nombre,
        descripcionPolitica: bestMatch.descripcion,
        confianza: finalConfidence,
        origen: 'CLASIFICADOR_LOCAL_FLUTTER',
        metodoRecomendacion: 'OFFLINE_CATALOGO_LOCAL',
        requiereMasInformacion: requiereMasInfo,
        requiereConfirmacion: true,
        mensaje: mensajeExplicacion,
        topResultados: topResultados,
      );
    } else {
      // Fallback
      final result = _clasificarStatic(
        texto: texto,
        nombreDocumento: nombreDocumento,
        politicasEnCache: politicasEnCache,
      );

      return ClasificacionSolicitudResult(
        politicaId: result.politicaId,
        nombrePolitica: result.nombrePolitica,
        descripcionPolitica: result.descripcionPolitica,
        confianza: result.confianza,
        origen: result.origen,
        metodoRecomendacion: 'OFFLINE_KEYWORDS',
        requiereMasInformacion: result.requiereMasInformacion,
        requiereConfirmacion: result.requiereConfirmacion,
        mensaje: 'La recomendación offline es limitada porque no se sincronizaron datos.',
        topResultados: result.topResultados,
      );
    }
  }

  static ClasificacionSolicitudResult _clasificarStatic({
    required String texto,
    String? nombreDocumento,
    required List<TramiteDisponibleItem> politicasEnCache,
  }) {
    final String query = _normalize(texto);
    final String docQuery = nombreDocumento != null ? _normalize(nombreDocumento) : '';
    final String fullQuery = '$query $docQuery'.trim();
    final List<String> queryWords = fullQuery.split(' ');

    // Pre-pass: Identify matched multi-word phrase keywords and consume their individual words
    final Set<String> consumedWords = <String>{};
    for (final _PolicySpec spec in _policySpecs) {
      for (final String keyword in spec.palabrasClave) {
        final String normKw = _normalize(keyword);
        if (normKw.contains(' ')) {
          if (fullQuery.contains(normKw)) {
            consumedWords.addAll(normKw.split(' '));
          } else {
            final List<String> kwWords = normKw.split(' ');
            bool allWordsPresent = true;
            for (final String kwW in kwWords) {
              if (kwW.length > 2 && !queryWords.contains(kwW)) {
                allWordsPresent = false;
                break;
              }
            }
            if (allWordsPresent && kwWords.length > 1) {
              consumedWords.addAll(kwWords);
            }
          }
        }
      }
    }

    final List<_MatchScore> matches = <_MatchScore>[];

    for (final _PolicySpec spec in _policySpecs) {
      double score = 0.0;

      // Intentar buscar correspondencia en caché para enriquecer datos
      final TramiteDisponibleItem? cachedItem = _findBestCachedMatch(spec, politicasEnCache);
      final String targetName = spec.nombre;
      final String targetDesc = spec.descripcion;
      final String normCat = cachedItem != null ? _normalize(cachedItem.categoria) : '';

      final String normName = _normalize(targetName);
      final String normDesc = _normalize(targetDesc);

      // 1. Coincidencia de frase clave
      for (final String keyword in spec.palabrasClave) {
        final String normKw = _normalize(keyword);
        if (normKw.contains(' ')) {
          if (fullQuery.contains(normKw)) {
            score += 5.0;
          } else {
            final List<String> kwWords = normKw.split(' ');
            bool allWordsPresent = true;
            for (final String kwW in kwWords) {
              if (kwW.length > 2 && !queryWords.contains(kwW)) {
                allWordsPresent = false;
                break;
              }
            }
            if (allWordsPresent && kwWords.length > 1) {
              score += 4.0;
            }
          }
        } else if (normKw.isNotEmpty) {
          if (queryWords.contains(normKw) && !consumedWords.contains(normKw)) {
            score += 3.0;
          }
        }
      }

      // 3. Coincidencia parcial en nombre de política
      final List<String> nameWords = normName.split(' ');
      for (final String word in nameWords) {
        if (word.length > 3 && queryWords.contains(word)) {
          score += 2.0;
        }
      }

      // 4. Coincidencia parcial en descripción/categoría
      final List<String> descWords = normDesc.split(' ');
      for (final String word in descWords) {
        if (word.length > 3 && queryWords.contains(word)) {
          score += 1.0;
        }
      }
      if (normCat.isNotEmpty) {
        final List<String> catWords = normCat.split(' ');
        for (final String word in catWords) {
          if (word.length > 3 && queryWords.contains(word)) {
            score += 1.0;
          }
        }
      }

      if (score > 0) {
        matches.add(_MatchScore(
          spec: spec,
          score: score,
          cachedItem: cachedItem,
        ));
      }
    }

    matches.sort((_MatchScore a, _MatchScore b) => b.score.compareTo(a.score));

    if (matches.isEmpty || matches.first.score < _minThreshold) {
      return ClasificacionSolicitudResult(
        politicaId: '',
        nombrePolitica: 'No determinado',
        confianza: 0.0,
        origen: 'CLASIFICADOR_LOCAL_FLUTTER',
        metodoRecomendacion: 'OFFLINE_KEYWORDS',
        requiereMasInformacion: true,
        requiereConfirmacion: false,
        mensaje: 'No se pudo determinar un trámite claro con la información proporcionada en modo offline. Por favor, intenta describir tu necesidad con otras palabras.',
        topResultados: const <ClasificacionSolicitudItem>[],
      );
    }

    final _MatchScore bestMatch = matches.first;
    final double bestScore = bestMatch.score;

    final List<_MatchScore> closeMatches = matches
        .where((_MatchScore m) => m.score >= (bestScore - 2.0))
        .toList();

    final List<ClasificacionSolicitudItem> topResultados = closeMatches.map((_MatchScore m) {
      final double normalizedConf = (m.score / 15.0).clamp(0.1, 0.99);
      final double confidence = double.parse(normalizedConf.toStringAsFixed(4));

      final String targetId = m.cachedItem?.id ?? m.spec.id;
      final String targetName = m.cachedItem?.nombre ?? m.spec.nombre;

      return ClasificacionSolicitudItem(
        politicaId: targetId,
        nombrePolitica: targetName,
        confianza: confidence,
        scoreFinal: confidence,
        scoreSemantico: confidence,
        scoreRequisitos: 0.0,
      );
    }).toList();

    final String finalId = bestMatch.cachedItem?.id ?? bestMatch.spec.id;
    final String finalName = bestMatch.cachedItem?.nombre ?? bestMatch.spec.nombre;
    final String finalDesc = bestMatch.cachedItem?.descripcion ?? bestMatch.spec.descripcion;

    final double normBestConf = (bestScore / 15.0).clamp(0.1, 0.99);
    final double finalConfidence = double.parse(normBestConf.toStringAsFixed(4));

    final bool requiereMasInfo = closeMatches.length > 1 && (bestScore - closeMatches[1].score) <= 1.0;

    return ClasificacionSolicitudResult(
      politicaId: finalId,
      nombrePolitica: finalName,
      descripcionPolitica: finalDesc,
      confianza: finalConfidence,
      origen: 'CLASIFICADOR_LOCAL_FLUTTER',
      metodoRecomendacion: 'OFFLINE_KEYWORDS',
      requiereMasInformacion: requiereMasInfo,
      requiereConfirmacion: true,
      mensaje: 'Recomendación generada en modo offline. Será validada con el servidor cuando vuelva la conexión.',
      topResultados: topResultados,
    );
  }

  static TramiteDisponibleItem? _findBestCachedMatch(
    _PolicySpec spec,
    List<TramiteDisponibleItem> cache,
  ) {
    if (cache.isEmpty) return null;

    final String normSpecName = _normalize(spec.nombre);

    // 1. Buscar coincidencia exacta por nombre normalizado
    for (final TramiteDisponibleItem item in cache) {
      if (_normalize(item.nombre) == normSpecName) {
        return item;
      }
    }

    // 2. Coincidencia parcial si contiene el nombre
    for (final TramiteDisponibleItem item in cache) {
      final String normItemName = _normalize(item.nombre);
      if (normItemName.contains(normSpecName) || normSpecName.contains(normItemName)) {
        return item;
      }
    }

    return null;
  }
}

class _PolicySpec {
  const _PolicySpec({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.palabrasClave,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final List<String> palabrasClave;
}

class _MatchScore {
  const _MatchScore({
    required this.spec,
    required this.score,
    this.cachedItem,
  });

  final _PolicySpec spec;
  final double score;
  final TramiteDisponibleItem? cachedItem;
}

class _DynamicMatchScore {
  const _DynamicMatchScore({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.score,
    required this.policy,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final double score;
  final Map<String, dynamic> policy;
}

class OfflineRequisitoDetector {
  static String normalizarTexto(String texto) {
    String normalized = texto.toLowerCase().trim();
    // Quitar extensión del archivo
    normalized = normalized.replaceAll(RegExp(r'\.[a-z0-9]{2,4}$'), '');
    // Reemplazar guiones y underscores por espacios
    normalized = normalized.replaceAll(RegExp(r'[-_]'), ' ');
    // Reemplazar acentos
    final Map<String, String> accents = <String, String>{
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'ü': 'u', 'ñ': 'n'
    };
    accents.forEach((String key, String value) {
      normalized = normalized.replaceAll(key, value);
    });
    // Quitar signos
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    // Limpiar espacios dobles
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return normalized.trim();
  }

  static final Map<String, List<String>> _sinonimos = {
    'codigo de cliente': [
      'codigo cliente',
      'numero cliente',
      'nro cliente',
      'cliente',
      'id cliente',
      'identificador cliente'
    ],
    'documento de identidad': [
      'documento identidad',
      'carnet',
      'carnet identidad',
      'ci',
      'cedula',
      'dni',
      'identidad'
    ],
    'comprobante de domicilio': [
      'comprobante domicilio',
      'domicilio',
      'direccion',
      'factura luz',
      'factura agua',
      'recibo luz',
      'recibo agua',
      'servicio basico',
      'servicios basicos'
    ],
    'comprobante de pago': [
      'comprobante pago',
      'recibo pago',
      'pago',
      'deposito',
      'transferencia'
    ],
    'factura': [
      'factura',
      'duplicado factura',
      'recibo factura'
    ],
    'titular': [
      'titular',
      'datos titular',
      'cambio titular'
    ],
  };

  static bool containsWordOrPhrase(String text, String query) {
    if (query.isEmpty) return false;
    final RegExp regex = RegExp('\\b' + RegExp.escape(query) + '\\b');
    return regex.hasMatch(text);
  }

  static double calcularScoreRequisito({
    required String nombreArchivo,
    required String clave,
    required String etiqueta,
    required String ayuda,
    List<dynamic>? palabrasClave,
  }) {
    final String fileNorm = normalizarTexto(nombreArchivo);
    final String claveNorm = normalizarTexto(clave);
    final String etiquetaNorm = normalizarTexto(etiqueta);
    final String ayudaNorm = normalizarTexto(ayuda);

    if (fileNorm.isEmpty) return 0.0;

    // 1. Coincidencia exacta con nombre/etiqueta/clave del requisito: +6
    if (fileNorm == etiquetaNorm || fileNorm == claveNorm) {
      return 6.0;
    }

    // 2. Coincidencia con sinónimo fuerte: +5
    String? grupoEncontrado;
    for (final String grupo in _sinonimos.keys) {
      if (etiquetaNorm.contains(grupo) || claveNorm.contains(grupo) || grupo.contains(etiquetaNorm) || grupo.contains(claveNorm)) {
        grupoEncontrado = grupo;
        break;
      }
    }
    if (grupoEncontrado == null) {
      if (etiquetaNorm.contains('cliente') || claveNorm.contains('cliente') || etiquetaNorm.contains('codigo') || claveNorm.contains('codigo')) {
        grupoEncontrado = 'codigo de cliente';
      } else if (etiquetaNorm.contains('identidad') || claveNorm.contains('identidad') || etiquetaNorm.contains('dni') || claveNorm.contains('dni') || etiquetaNorm.contains('carnet') || claveNorm.contains('carnet') || etiquetaNorm.contains('cedula') || claveNorm.contains('cedula')) {
        grupoEncontrado = 'documento de identidad';
      } else if (etiquetaNorm.contains('domicilio') || claveNorm.contains('domicilio') || etiquetaNorm.contains('direccion') || claveNorm.contains('direccion')) {
        grupoEncontrado = 'comprobante de domicilio';
      } else if (etiquetaNorm.contains('pago') || claveNorm.contains('pago') || etiquetaNorm.contains('deposito') || claveNorm.contains('deposito') || etiquetaNorm.contains('transferencia') || claveNorm.contains('transferencia')) {
        grupoEncontrado = 'comprobante de pago';
      } else if (etiquetaNorm.contains('factura') || claveNorm.contains('factura')) {
        grupoEncontrado = 'factura';
      } else if (etiquetaNorm.contains('titular') || claveNorm.contains('titular')) {
        grupoEncontrado = 'titular';
      }
    }

    if (grupoEncontrado != null) {
      final List<String> sinonimosGrupo = _sinonimos[grupoEncontrado] ?? [];
      for (final String sinonimo in sinonimosGrupo) {
        if (containsWordOrPhrase(fileNorm, sinonimo)) {
          return 5.0;
        }
      }
    }

    // 3. Coincidencia con palabra clave del requisito (o contiene el nombre entero): +4
    if (palabrasClave != null && palabrasClave.isNotEmpty) {
      for (final dynamic kw in palabrasClave) {
        final String kwNorm = normalizarTexto(kw?.toString() ?? '');
        if (kwNorm.isNotEmpty && containsWordOrPhrase(fileNorm, kwNorm)) {
          return 4.0;
        }
      }
    }
    if (etiquetaNorm.isNotEmpty && containsWordOrPhrase(fileNorm, etiquetaNorm)) {
      return 4.0;
    }
    if (claveNorm.isNotEmpty && containsWordOrPhrase(fileNorm, claveNorm)) {
      return 4.0;
    }

    // 4. Coincidencia parcial con descripción (ayuda): +2
    final List<String> fileWords = fileNorm.split(' ');
    final List<String> ayudaWords = ayudaNorm.split(' ');
    bool hasAyudaMatch = false;
    for (final String word in fileWords) {
      if (word.length > 3 && ayudaWords.contains(word)) {
        hasAyudaMatch = true;
        break;
      }
    }
    if (hasAyudaMatch) {
      return 2.0;
    }

    // 5. Coincidencia débil: +1
    final List<String> etiquetaWords = etiquetaNorm.split(' ');
    final List<String> claveWords = claveNorm.split(' ');
    for (final String word in fileWords) {
      if (word.length > 3 && (etiquetaWords.contains(word) || claveWords.contains(word))) {
        return 1.0;
      }
    }

    return 0.0;
  }
}
