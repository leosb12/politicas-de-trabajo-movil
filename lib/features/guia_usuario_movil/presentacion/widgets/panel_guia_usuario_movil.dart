import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../dominio/modelos/contexto_guia_usuario_movil.dart';
import '../../dominio/modelos/respuesta_guia_usuario_movil.dart';
import '../../dominio/modelos/solicitud_guia_usuario_movil.dart';
import '../proveedores/guia_usuario_movil_providers.dart';

class PanelGuiaUsuarioMovil extends ConsumerStatefulWidget {
  const PanelGuiaUsuarioMovil({
    super.key,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.pantalla,
    required this.contexto,
    required this.preguntasSugeridas,
  });

  final String usuarioId;
  final String nombreUsuario;
  final String pantalla;
  final ContextoGuiaUsuarioMovil contexto;
  final List<String> preguntasSugeridas;

  @override
  ConsumerState<PanelGuiaUsuarioMovil> createState() =>
      _PanelGuiaUsuarioMovilState();
}

class _PanelGuiaUsuarioMovilState extends ConsumerState<PanelGuiaUsuarioMovil> {
  final TextEditingController _preguntaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_MensajeGuiaUsuarioMovil> _mensajes = <_MensajeGuiaUsuarioMovil>[];

  bool _estaConsultando = false;
  String? _mensajeError;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechDisponible = false;
  bool _escuchandoVoz = false;


  @override
  void initState() {
    super.initState();
    _mensajes.add(
      _MensajeGuiaUsuarioMovil.asistente(
        respuesta: RespuestaGuiaUsuarioMovil(
          respuesta: _mensajeBienvenida(widget.pantalla),
          pasos: const <String>[
            'Haz una pregunta corta sobre esta pantalla o tu tramite.',
            'Tambien puedes usar una de las preguntas rapidas.',
          ],
          severidad: 'INFO',
          fuente: 'LOCAL_UI',
        ),
      ),
    );
    _inicializarVoz();
  }

  @override
  void dispose() {
    _speech.cancel();
    _preguntaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _inicializarVoz() async {
    try {
      final bool disponible = await _speech.initialize(
        onError: (val) {
          debugPrint('Error de voz: $val');
          if (mounted) {
            setState(() {
              _escuchandoVoz = false;
            });
          }
        },
        onStatus: (val) {
          debugPrint('Estado de voz: $val');
          if (val == 'notListening' || val == 'done') {
            if (mounted) {
              setState(() {
                _escuchandoVoz = false;
              });
            }
          }
        },
      );
      if (mounted) {
        setState(() {
          _speechDisponible = disponible;
        });
      }
    } catch (e) {
      debugPrint('Error inicializando voz: $e');
    }
  }

  Future<void> _toggleEscucharVoz() async {
    if (_estaConsultando) {
      return;
    }

    if (_escuchandoVoz) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _escuchandoVoz = false;
        });
      }
    } else {
      if (!_speechDisponible) {
        await _inicializarVoz();
      }

      if (_speechDisponible) {
        if (mounted) {
          setState(() {
            _escuchandoVoz = true;
            _mensajeError = null;
          });
        }
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _preguntaController.text = result.recognizedWords;
                if (result.finalResult) {
                  _escuchandoVoz = false;
                }
              });
            }
          },
          listenOptions: stt.SpeechListenOptions(
            localeId: 'es_ES',
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            _mensajeError = 'Permiso de microfono no concedido o no disponible.';
          });
        }
      }
    }
  }

  Future<void> _enviarPregunta([String? preguntaPredefinida]) async {
    final String pregunta = (preguntaPredefinida ?? _preguntaController.text)
        .trim();
    if (pregunta.isEmpty || _estaConsultando) {
      return;
    }

    setState(() {
      _mensajes.add(_MensajeGuiaUsuarioMovil.usuario(texto: pregunta));
      _estaConsultando = true;
      _mensajeError = null;
      _preguntaController.clear();
    });
    _desplazarAlFinal();

    try {
      final SolicitudGuiaUsuarioMovil solicitud = SolicitudGuiaUsuarioMovil(
        usuarioId: widget.usuarioId,
        nombreUsuario: widget.nombreUsuario,
        pantalla: widget.pantalla,
        pregunta: pregunta,
        contexto: widget.contexto,
      );

      final ResultadoGuiaUsuarioMovil resultado = await ref
          .read(servicioGuiaUsuarioMovilProvider)
          .responder(solicitud);

      if (!mounted) {
        return;
      }

      setState(() {
        _mensajes.add(
          _MensajeGuiaUsuarioMovil.asistente(
            respuesta: resultado.respuesta,
            usoRespaldoLocal: resultado.usoRespaldoLocal,
            detalleRespaldo: resultado.detalleRespaldo,
          ),
        );
        _estaConsultando = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _estaConsultando = false;
        _mensajeError =
            'No fue posible responder en este momento. Intenta nuevamente.';
      });
    }

    _desplazarAlFinal();
  }

  void _desplazarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets insets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              _PanelHeader(
                pantalla: widget.pantalla,
                onClose: () => Navigator.of(context).pop(),
              ),
              if (_mensajeError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _AvisoInline(
                    color: theme.colorScheme.errorContainer,
                    icon: Icons.error_outline_rounded,
                    message: _mensajeError!,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _PreguntasRapidas(
                  preguntas: _preguntasSugeridas(widget),
                  bloqueado: _estaConsultando,
                  onPreguntaTap: _enviarPregunta,
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemBuilder: (BuildContext context, int index) {
                    final _MensajeGuiaUsuarioMovil mensaje = _mensajes[index];
                    if (mensaje.esUsuario) {
                      return _BurbujaUsuario(texto: mensaje.texto);
                    }
                    return _TarjetaRespuestaGuia(mensaje: mensaje);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _mensajes.length,
                ),
              ),
              if (_estaConsultando)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _CargandoGuia(),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _CajaEnvio(
                    controller: _preguntaController,
                    estaDeshabilitada: _estaConsultando,
                    escuchandoVoz: _escuchandoVoz,
                    onToggleVoz: _toggleEscucharVoz,
                    onEnviar: _enviarPregunta,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _preguntasSugeridas(PanelGuiaUsuarioMovil widget) {
    if (widget.preguntasSugeridas.isNotEmpty) {
      return widget.preguntasSugeridas;
    }

    switch (widget.pantalla.trim().toUpperCase()) {
      case PantallasGuiaUsuarioMovil.listaTramites:
        return const <String>[
          '¿Qué puedo hacer aquí?',
          '¿Cómo reviso el estado de un trámite?',
          '¿Qué significa cada estado?',
        ];
      case PantallasGuiaUsuarioMovil.detalleTramite:
      case PantallasGuiaUsuarioMovil.estadoTramite:
        return const <String>[
          '¿En qué estado está mi trámite?',
          '¿Qué falta para que avance?',
          '¿Qué pasa después?',
        ];
      case PantallasGuiaUsuarioMovil.formularioSolicitud:
        return const <String>[
          '¿Qué tengo que completar aquí?',
          '¿Qué documentos me faltan?',
          '¿Cómo subo un documento?',
        ];
      default:
        return const <String>[
          '¿Qué puedo hacer aquí?',
          '¿Cómo inicio un trámite?',
          '¿Cómo reviso mis solicitudes?',
        ];
    }
  }

  String _mensajeBienvenida(String pantalla) {
    switch (pantalla.trim().toUpperCase()) {
      case PantallasGuiaUsuarioMovil.listaTramites:
        return 'Puedo ayudarte a entender tu lista de tramites y decirte como revisar el estado de cada solicitud.';
      case PantallasGuiaUsuarioMovil.detalleTramite:
      case PantallasGuiaUsuarioMovil.estadoTramite:
        return 'Puedo explicarte en que estado va tu tramite, en que etapa esta y que podria pasar despues.';
      case PantallasGuiaUsuarioMovil.formularioSolicitud:
        return 'Puedo orientarte sobre este formulario, lo que falta y los documentos pendientes.';
      case PantallasGuiaUsuarioMovil.perfilUsuario:
        return 'Puedo explicarte para que sirve esta seccion y como se relaciona con tus tramites.';
      default:
        return 'Puedo orientarte de forma simple sobre tus tramites y sobre lo que puedes hacer en esta pantalla.';
    }
  }
}

class _MensajeGuiaUsuarioMovil {
  const _MensajeGuiaUsuarioMovil({
    required this.esUsuario,
    this.texto = '',
    this.respuesta,
    this.usoRespaldoLocal = false,
    this.detalleRespaldo,
  });

  factory _MensajeGuiaUsuarioMovil.usuario({required String texto}) {
    return _MensajeGuiaUsuarioMovil(esUsuario: true, texto: texto);
  }

  factory _MensajeGuiaUsuarioMovil.asistente({
    required RespuestaGuiaUsuarioMovil respuesta,
    bool usoRespaldoLocal = false,
    String? detalleRespaldo,
  }) {
    return _MensajeGuiaUsuarioMovil(
      esUsuario: false,
      respuesta: respuesta,
      usoRespaldoLocal: usoRespaldoLocal,
      detalleRespaldo: detalleRespaldo,
    );
  }

  final bool esUsuario;
  final String texto;
  final RespuestaGuiaUsuarioMovil? respuesta;
  final bool usoRespaldoLocal;
  final String? detalleRespaldo;
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.pantalla, required this.onClose});

  final String pantalla;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        children: <Widget>[
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Guia IA contextual',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tituloPantalla(pantalla),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _tituloPantalla(String pantalla) {
    switch (pantalla.trim().toUpperCase()) {
      case PantallasGuiaUsuarioMovil.inicioUsuario:
        return 'Inicio del usuario movil';
      case PantallasGuiaUsuarioMovil.listaTramites:
        return 'Lista de tramites';
      case PantallasGuiaUsuarioMovil.detalleTramite:
        return 'Detalle del tramite';
      case PantallasGuiaUsuarioMovil.estadoTramite:
        return 'Estado del tramite';
      case PantallasGuiaUsuarioMovil.formularioSolicitud:
        return 'Formulario de solicitud';
      case PantallasGuiaUsuarioMovil.perfilUsuario:
        return 'Perfil del usuario';
      case PantallasGuiaUsuarioMovil.notificaciones:
        return 'Notificaciones';
      default:
        return 'Guia para tramites';
    }
  }
}

class _PreguntasRapidas extends StatelessWidget {
  const _PreguntasRapidas({
    required this.preguntas,
    required this.bloqueado,
    required this.onPreguntaTap,
  });

  final List<String> preguntas;
  final bool bloqueado;
  final ValueChanged<String> onPreguntaTap;

  @override
  Widget build(BuildContext context) {
    if (preguntas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Preguntas rapidas',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: preguntas
              .map((String pregunta) {
                return ActionChip(
                  label: Text(pregunta),
                  onPressed: bloqueado ? null : () => onPreguntaTap(pregunta),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _BurbujaUsuario extends StatelessWidget {
  const _BurbujaUsuario({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              texto,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaRespuestaGuia extends StatelessWidget {
  const _TarjetaRespuestaGuia({required this.mensaje});

  final _MensajeGuiaUsuarioMovil mensaje;

  @override
  Widget build(BuildContext context) {
    final RespuestaGuiaUsuarioMovil respuesta = mensaje.respuesta!;
    final ThemeData theme = Theme.of(context);
    final Color acento = _colorSeveridad(
      theme.colorScheme,
      respuesta.severidad,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.55,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: acento.withValues(alpha: 0.32)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.smart_toy_outlined, color: acento, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Asistente de guia',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _SelloSeveridad(severidad: respuesta.severidad),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  respuesta.respuesta,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                if (mensaje.usoRespaldoLocal) ...<Widget>[
                  const SizedBox(height: 10),
                  _AvisoInline(
                    color: Colors.amber.shade100,
                    icon: Icons.wifi_off_rounded,
                    message:
                        mensaje.detalleRespaldo ??
                        'Mostrando una orientacion local porque la IA no respondio.',
                  ),
                ],
                if (respuesta.estadoExplicado.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  _BloqueDetalle(
                    titulo: 'Estado',
                    contenido: respuesta.estadoExplicado,
                  ),
                ],
                if (respuesta.progresoExplicado.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  _BloqueDetalle(
                    titulo: 'Progreso',
                    contenido: respuesta.progresoExplicado,
                  ),
                ],
                if (respuesta.pasos.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  _ListaDetalle(
                    titulo: 'Sugerencias',
                    items: respuesta.pasos,
                    icon: Icons.chevron_right_rounded,
                  ),
                ],
                if (respuesta.documentosFaltantes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  _ListaDetalle(
                    titulo: 'Documentos faltantes',
                    items: respuesta.documentosFaltantes,
                    icon: Icons.description_outlined,
                  ),
                ],
                if (respuesta.proximosPasos.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  _ListaDetalle(
                    titulo: 'Proximos pasos',
                    items: respuesta.proximosPasos,
                    icon: Icons.route_outlined,
                  ),
                ],
                if (respuesta.accionesSugeridas.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: respuesta.accionesSugeridas
                        .map((AccionSugeridaGuiaUsuarioMovil accion) {
                          return Chip(
                            avatar: const Icon(
                              Icons.touch_app_outlined,
                              size: 16,
                            ),
                            label: Text(accion.etiqueta),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorSeveridad(ColorScheme colors, String severidad) {
    switch (severidad.trim().toUpperCase()) {
      case 'SUCCESS':
        return Colors.green.shade700;
      case 'WARNING':
        return Colors.orange.shade800;
      case 'ERROR':
        return colors.error;
      case 'INFO':
      default:
        return colors.primary;
    }
  }
}

class _SelloSeveridad extends StatelessWidget {
  const _SelloSeveridad({required this.severidad});

  final String severidad;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = _resolverColor(theme.colorScheme, severidad);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          severidad.trim().isEmpty ? 'INFO' : severidad.trim(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Color _resolverColor(ColorScheme colors, String severidad) {
    switch (severidad.trim().toUpperCase()) {
      case 'SUCCESS':
        return Colors.green.shade700;
      case 'WARNING':
        return Colors.orange.shade800;
      case 'ERROR':
        return colors.error;
      case 'INFO':
      default:
        return colors.primary;
    }
  }
}

class _BloqueDetalle extends StatelessWidget {
  const _BloqueDetalle({required this.titulo, required this.contenido});

  final String titulo;
  final String contenido;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titulo,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(contenido, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _ListaDetalle extends StatelessWidget {
  const _ListaDetalle({
    required this.titulo,
    required this.items,
    required this.icon,
  });

  final String titulo;
  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titulo,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map((String item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(icon, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(item, style: theme.textTheme.bodySmall)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _AvisoInline extends StatelessWidget {
  const _AvisoInline({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _CargandoGuia extends StatelessWidget {
  const _CargandoGuia();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const <Widget>[
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10),
        Expanded(child: Text('Pensando una respuesta simple y util...')),
      ],
    );
  }
}

class _CajaEnvio extends StatelessWidget {
  const _CajaEnvio({
    required this.controller,
    required this.estaDeshabilitada,
    required this.escuchandoVoz,
    required this.onToggleVoz,
    required this.onEnviar,
  });

  final TextEditingController controller;
  final bool estaDeshabilitada;
  final bool escuchandoVoz;
  final VoidCallback onToggleVoz;
  final ValueChanged<String?> onEnviar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                enabled: !estaDeshabilitada,
                textInputAction: TextInputAction.send,
                onSubmitted: estaDeshabilitada ? null : onEnviar,
                decoration: InputDecoration(
                  hintText: escuchandoVoz
                      ? 'Escuchando voz...'
                      : 'Pregunta por tu tramite o por esta pantalla',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: estaDeshabilitada ? null : onToggleVoz,
              icon: escuchandoVoz
                  ? const _IconoMicrofonoAnimado()
                  : const Icon(Icons.mic_rounded),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              onPressed: estaDeshabilitada || escuchandoVoz ? null : () => onEnviar(null),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconoMicrofonoAnimado extends StatefulWidget {
  const _IconoMicrofonoAnimado();

  @override
  State<_IconoMicrofonoAnimado> createState() => _IconoMicrofonoAnimadoState();
}

class _IconoMicrofonoAnimadoState extends State<_IconoMicrofonoAnimado>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _animation,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.mic_rounded,
          color: colorScheme.error,
        ),
      ),
    );
  }
}
