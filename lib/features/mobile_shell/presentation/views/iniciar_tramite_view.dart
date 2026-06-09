import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';

import '../../../../core/network/pago_service.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../domain/models/tramite_disponible_item.dart';
import '../../../pagos/presentation/widgets/pago_bottom_sheet.dart';
import '../../../tramites/domain/entities/tramite_disponible.dart';
import '../../../tramites/presentation/views/requisitos_iniciales_sheet.dart';
import '../viewmodels/iniciar_tramite_providers.dart';
import '../viewmodels/mis_tramites_providers.dart';
import '../viewmodels/mobile_shell_providers.dart';
import '../widgets/tramite_disponible_card.dart';
import '../widgets/tramites_search_bar.dart';

class IniciarTramiteView extends ConsumerStatefulWidget {
  const IniciarTramiteView({super.key});

  @override
  ConsumerState<IniciarTramiteView> createState() => _IniciarTramiteViewState();
}

class _IniciarTramiteViewState extends ConsumerState<IniciarTramiteView> {
  final TextEditingController _necesidadController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  String? _requestedUserId;
  String _searchQuery = '';
  TramiteFilter _currentFilter = TramiteFilter.todos;
  bool _usarDeepSeek = false;
  bool _speechDisponible = false;
  bool _escuchandoVoz = false;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _inicializarVoz();
  }

  @override
  void dispose() {
    _speech.cancel();
    _necesidadController.dispose();
    super.dispose();
  }

  Future<void> _subirDocumento() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint('Error al seleccionar archivo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo seleccionar el archivo.')),
        );
      }
    }
  }

  String? _obtenerNombreDocumento() {
    if (_selectedFile == null) return null;
    final String name = _selectedFile!.name;
    final int lastDot = name.lastIndexOf('.');
    final String nameWithoutExt = lastDot == -1 ? name : name.substring(0, lastDot);
    return nameWithoutExt.replaceAll(RegExp(r'[-_]'), ' ').trim();
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
          });
        }
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _necesidadController.text = result.recognizedWords;
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de micrófono no concedido o no disponible.')),
          );
        }
      }
    }
  }

  bool _requierePagoValido(TramiteDisponibleItem tramite) {
    if (!tramite.requierePago) {
      return true;
    }

    final double? monto = tramite.montoPago;
    final String? moneda = tramite.monedaPago?.trim();
    return monto != null && monto > 0 && moneda != null && moneda.isNotEmpty;
  }

  String _formatearMonto(TramiteDisponibleItem tramite) {
    final double value = tramite.montoPago ?? 0;
    final String formattedAmount = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final String currency = tramite.monedaPago?.trim() ?? '';

    if (currency.isEmpty) {
      return formattedAmount;
    }

    return '$formattedAmount $currency';
  }

  String _descripcionPago(TramiteDisponibleItem tramite) {
    final String descripcion = tramite.descripcionPago?.trim() ?? '';
    return descripcion.isNotEmpty ? descripcion : 'Pago de trámite';
  }

  Future<void> _mostrarPagoModal({
    required TramiteDisponibleItem tramite,
    required String actorUserId,
    Map<String, dynamic>? respuestasRequisitosIniciales,
  }) async {
    if (!_requierePagoValido(tramite)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Precio no configurado para este trámite.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final PagoService pagoService = PagoService(
      ref.read(iniciarTramiteDioProvider),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return PagoBottomSheet(
          tramiteNombre: tramite.nombre,
          actorUserId: actorUserId,
          tramiteId: tramite.id,
          pagoService: pagoService,
          precioTexto: _formatearMonto(tramite),
          descripcionPago: _descripcionPago(tramite),
          respuestasRequisitosIniciales: respuestasRequisitosIniciales,
          onStripeSessionId: (_) {},
          onStripeCheckoutOpened: () {
            if (!mounted) {
              return;
            }

            Navigator.of(sheetContext).pop();
            ref.read(mobileShellViewModelProvider.notifier).selectTab(1);
          },
          onPaypalPagoId: (_) {},
          onPagoConfirmado: () async {
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
              context,
            );

            if (mounted) {
              Navigator.of(sheetContext).pop();
            }

            final String? error = await ref
                .read(iniciarTramiteViewModelProvider.notifier)
                .iniciarTramite(
                  actorUserId: actorUserId,
                  tramiteId: tramite.id,
                  respuestasRequisitosIniciales: respuestasRequisitosIniciales,
                );

            if (!mounted) {
              return;
            }

            final String message = error ?? 'Tramite iniciado correctamente.';
            final Color backgroundColor = error == null
                ? Colors.green.shade600
                : Colors.red.shade700;

            if (error == null) {
              await ref
                  .read(misTramitesViewModelProvider.notifier)
                  .cargarMisTramites(usuarioId: actorUserId);

              if (!mounted) {
                return;
              }

              ref.read(mobileShellViewModelProvider.notifier).selectTab(1);
            }

            messenger.showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: backgroundColor,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _iniciarTramiteSeleccionado({
    required TramiteDisponibleItem tramite,
    required String actorUserId,
  }) async {
    final viewModel = ref.read(iniciarTramiteViewModelProvider.notifier);
    Map<String, dynamic>? respuestasRequisitosIniciales;

    if (tramite.tieneRequisitosIniciales) {
      respuestasRequisitosIniciales = await RequisitosInicialesSheet.show(
        context,
        actorUserId: actorUserId,
        tramite: _toTramiteDisponible(tramite),
      );

      if (respuestasRequisitosIniciales == null) {
        return;
      }
    }

    if (tramite.requierePago && _requierePagoValido(tramite)) {
      await _mostrarPagoModal(
        tramite: tramite,
        actorUserId: actorUserId,
        respuestasRequisitosIniciales: respuestasRequisitosIniciales,
      );
      return;
    }

    final String? error = await viewModel.iniciarTramite(
      actorUserId: actorUserId,
      tramiteId: tramite.id,
      respuestasRequisitosIniciales: respuestasRequisitosIniciales,
    );

    if (!mounted) {
      return;
    }

    final String message = error ?? 'Tramite iniciado correctamente.';
    final Color backgroundColor = error == null
        ? Colors.green.shade600
        : Colors.red.shade700;

    if (error == null) {
      await ref
          .read(misTramitesViewModelProvider.notifier)
          .cargarMisTramites(usuarioId: actorUserId);

      if (!mounted) {
        return;
      }

      ref.read(mobileShellViewModelProvider.notifier).selectTab(1);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  TramiteDisponibleItem? _buscarTramitePorId(
    List<TramiteDisponibleItem> tramites,
    String politicaId,
  ) {
    for (final TramiteDisponibleItem tramite in tramites) {
      if (tramite.id == politicaId) {
        return tramite;
      }
    }
    return null;
  }

  TramiteDisponible _toTramiteDisponible(TramiteDisponibleItem item) {
    return TramiteDisponible(
      id: item.id,
      nombre: item.nombre,
      descripcion: item.descripcion,
      tipoPolitica: 'EXTERNA',
      departamentoInicioId: null,
      departamentoInicioNombre: null,
      requierePago: item.requierePago,
      tieneRequisitosIniciales: item.tieneRequisitosIniciales,
      montoPago: item.montoPago,
      monedaPago: item.monedaPago,
      descripcionPago: item.descripcionPago,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iniciarTramiteViewModelProvider);
    final viewModel = ref.read(iniciarTramiteViewModelProvider.notifier);
    final String actorUserId =
        ref.watch(authViewModelProvider).authenticatedUser?.id.trim() ?? '';

    if (actorUserId.isNotEmpty &&
        _requestedUserId != actorUserId &&
        !state.isLoading) {
      _requestedUserId = actorUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        viewModel.cargarTramites(actorUserId: actorUserId);
      });
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (actorUserId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.person_off_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'No se pudo identificar al usuario actual para consultar tramites.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 56),
              const SizedBox(height: 12),
              Text(state.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  _requestedUserId = actorUserId;
                  viewModel.cargarTramites(actorUserId: actorUserId);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.inbox_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'No hay tramites activos disponibles en este momento.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  _requestedUserId = actorUserId;
                  viewModel.cargarTramites(actorUserId: actorUserId);
                },
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    final tramitesFiltrados = state.tramites.where((t) {
      final bool matchesSearch = t.nombre.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final bool matchesFilter =
          _currentFilter == TramiteFilter.todos ||
          (_currentFilter == TramiteFilter.paga && t.requierePago) ||
          (_currentFilter == TramiteFilter.gratis && !t.requierePago);
      return matchesSearch && matchesFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: () {
        _requestedUserId = actorUserId;
        return viewModel.cargarTramites(actorUserId: actorUserId);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: tramitesFiltrados.length + 2,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Column(
              children: <Widget>[
                _NecesidadClasificacionPanel(
                  controller: _necesidadController,
                  escuchandoVoz: _escuchandoVoz,
                  onToggleVoz: _toggleEscucharVoz,
                  isClassifying: state.isClassifying,
                  classification: state.classification,
                  classificationError: state.classificationError,
                  usarDeepSeek: _usarDeepSeek,
                  onUsarDeepSeekChanged: (val) => setState(() => _usarDeepSeek = val),
                  tramiteRecomendado: state.classification == null
                      ? null
                      : _buscarTramitePorId(
                          state.tramites,
                          state.classification!.politicaId,
                        ),
                  isIniciandoRecomendado: state.classification == null
                      ? false
                      : state.isIniciando(state.classification!.politicaId),
                  selectedFile: _selectedFile,
                  onPickFile: _subirDocumento,
                  onRemoveFile: () => setState(() => _selectedFile = null),
                  onClassify: () {
                    viewModel.clasificarSolicitud(
                      actorUserId: actorUserId,
                      texto: _necesidadController.text,
                      usarDeepSeek: _usarDeepSeek,
                      nombreDocumento: _obtenerNombreDocumento(),
                    );
                  },
                  onClear: () {
                    _necesidadController.clear();
                    setState(() {
                      _selectedFile = null;
                    });
                    viewModel.limpiarClasificacion();
                  },
                  onIniciar: (TramiteDisponibleItem tramite) {
                    _iniciarTramiteSeleccionado(
                      tramite: tramite,
                      actorUserId: actorUserId,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TramitesSearchBar(
                  onQueryChanged: (query) =>
                      setState(() => _searchQuery = query),
                  onFilterChanged: (filter) =>
                      setState(() => _currentFilter = filter),
                ),
              ],
            );
          }
          if (index == 1) {
            return Text(
              'Selecciona un tramite activo para iniciar una nueva instancia.',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          }

          final tramite = tramitesFiltrados[index - 2];
          final bool isIniciando = state.isIniciando(tramite.id);

          return TramiteDisponibleCard(
            tramite: tramite,
            isIniciando: isIniciando,
            onIniciar: () async {
              await _iniciarTramiteSeleccionado(
                tramite: tramite,
                actorUserId: actorUserId,
              );
            },
          );
        },
      ),
    );
  }
}

class _NecesidadClasificacionPanel extends StatelessWidget {
  const _NecesidadClasificacionPanel({
    required this.controller,
    required this.isClassifying,
    required this.classification,
    required this.classificationError,
    required this.tramiteRecomendado,
    required this.isIniciandoRecomendado,
    required this.onClassify,
    required this.onClear,
    required this.onIniciar,
    required this.usarDeepSeek,
    required this.onUsarDeepSeekChanged,
    required this.escuchandoVoz,
    required this.onToggleVoz,
    required this.selectedFile,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  final TextEditingController controller;
  final bool isClassifying;
  final ClasificacionSolicitudResult? classification;
  final String? classificationError;
  final TramiteDisponibleItem? tramiteRecomendado;
  final bool isIniciandoRecomendado;
  final VoidCallback onClassify;
  final VoidCallback onClear;
  final ValueChanged<TramiteDisponibleItem> onIniciar;
  final bool usarDeepSeek;
  final ValueChanged<bool> onUsarDeepSeekChanged;
  final bool escuchandoVoz;
  final VoidCallback onToggleVoz;
  final PlatformFile? selectedFile;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Describe tu necesidad',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: escuchandoVoz 
                    ? 'Escuchando voz...' 
                    : 'Ej. mi internet esta muy lento desde ayer',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: escuchandoVoz
                      ? const _IconoMicrofonoAnimado()
                      : const Icon(Icons.mic_rounded),
                  onPressed: isClassifying ? null : onToggleVoz,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (selectedFile != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.description_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedFile!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: isClassifying ? null : onRemoveFile,
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: isClassifying ? null : onPickFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Sube tu documento'),
              ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Switch(
                  value: usarDeepSeek,
                  onChanged: onUsarDeepSeekChanged,
                ),
                const SizedBox(width: 8),
                Text(
                  'Usar análisis avanzado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isClassifying ? null : onClassify,
                    icon: isClassifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.manage_search_rounded),
                    label: Text(
                      isClassifying ? 'Buscando...' : 'Recomendar tramite',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Limpiar',
                  onPressed: isClassifying ? null : onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (classificationError != null &&
                classificationError!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                classificationError!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (classification != null) ...<Widget>[
              const SizedBox(height: 12),
              _ResultadoClasificacionCard(
                classification: classification!,
                tramiteRecomendado: tramiteRecomendado,
                isIniciando: isIniciandoRecomendado,
                onIniciar: onIniciar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultadoClasificacionCard extends StatelessWidget {
  const _ResultadoClasificacionCard({
    required this.classification,
    required this.tramiteRecomendado,
    required this.isIniciando,
    required this.onIniciar,
  });

  final ClasificacionSolicitudResult classification;
  final TramiteDisponibleItem? tramiteRecomendado;
  final bool isIniciando;
  final ValueChanged<TramiteDisponibleItem> onIniciar;

  String _getMetodoLabel(String? metodo) {
    if (metodo == null) return 'No especificado';
    final String m = metodo.toUpperCase();
    if (m == 'REQUISITOS') return 'Requisitos';
    if (m == 'MIXTO') return 'Mixto';
    if (m == 'INTENCION') return 'Intención';
    return metodo;
  }

  String _getMetodoExplicacion(String? metodo) {
    if (metodo == null) return '';
    final String m = metodo.toUpperCase();
    if (m == 'REQUISITOS') {
      return 'La recomendación fue realizada porque los datos ingresados coinciden con los requisitos iniciales de la política.';
    }
    if (m == 'MIXTO') {
      return 'La recomendación se basó tanto en la intención del usuario como en los requisitos detectados.';
    }
    if (m == 'INTENCION') {
      return 'La recomendación se basó principalmente en lo que el usuario pidió.';
    }
    return '';
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: <TextSpan>[
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool puedeIniciar = tramiteRecomendado != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildInfoRow(theme, 'Política recomendada: ', classification.nombrePolitica),
          if (classification.metodoRecomendacion != null) ...<Widget>[
            _buildInfoRow(theme, 'Método: ', _getMetodoLabel(classification.metodoRecomendacion)),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                _getMetodoExplicacion(classification.metodoRecomendacion),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          _buildInfoRow(theme, 'Confianza: ', '${(classification.confianza * 100).toStringAsFixed(0)}%'),
          _buildInfoRow(
            theme,
            'Requisitos detectados: ',
            classification.requisitosDetectados.isNotEmpty
                ? classification.requisitosDetectados.join(', ')
                : 'Ninguno',
          ),
          _buildInfoRow(
            theme,
            'Requisitos faltantes: ',
            classification.requisitosFaltantes.isNotEmpty
                ? classification.requisitosFaltantes.join(', ')
                : 'Ninguno',
          ),
          if (classification.requiereMasInformacion) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La IA recomienda esta política, pero se necesita completar o confirmar información adicional antes de iniciar el trámite.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (classification.mensaje.trim().isNotEmpty && !classification.requiereMasInformacion) ...<Widget>[
            const SizedBox(height: 8),
            Text(classification.mensaje, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: puedeIniciar && !isIniciando
                  ? () => onIniciar(tramiteRecomendado!)
                  : null,
              icon: isIniciando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(
                isIniciando
                    ? 'Iniciando...'
                    : classification.requiereMasInformacion
                    ? 'Completa mas informacion e iniciar'
                    : 'Iniciar este tramite',
              ),
            ),
          ),
          if (tramiteRecomendado == null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'La politica sugerida ya no esta disponible en la lista actual.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
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
