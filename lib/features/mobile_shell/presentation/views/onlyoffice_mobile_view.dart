import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OnlyOfficeMobileView extends StatefulWidget {
  const OnlyOfficeMobileView({
    super.key,
    required this.url,
    required this.titulo,
    required this.usuarioId,
    this.puedeEditar = false,
  });

  final Uri url;
  final String titulo;
  final String usuarioId;

  /// Whether the current user has edit permission on this document.
  /// When true the AppBar shows an "Editar" badge; when false a "Solo lectura" badge.
  final bool puedeEditar;

  @override
  State<OnlyOfficeMobileView> createState() => _OnlyOfficeMobileViewState();
}

class _OnlyOfficeMobileViewState extends State<OnlyOfficeMobileView> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _hasError = false;
              _progress = 0;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _progress = 100);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() => _hasError = true);
          },
        ),
      )
      ..loadRequest(
        widget.url,
        headers: <String, String>{
          if (widget.usuarioId.trim().isNotEmpty)
            'X-User-Id': widget.usuarioId.trim(),
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLoading = _progress > 0 && _progress < 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titulo.trim().isEmpty ? 'OnlyOffice' : widget.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.puedeEditar
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.puedeEditar
                    ? Colors.green.shade400
                    : Colors.orange.shade400,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  widget.puedeEditar
                      ? Icons.edit_rounded
                      : Icons.lock_outline_rounded,
                  size: 14,
                  color: widget.puedeEditar
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.puedeEditar ? 'Editar' : 'Solo lectura',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.puedeEditar
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: isLoading
              ? LinearProgressIndicator(value: _progress / 100)
              : const SizedBox(height: 3),
        ),
      ),
      body: Stack(
        children: <Widget>[
          WebViewWidget(controller: _controller),
          if (_hasError)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No se pudo cargar el visor de documentos. '
                          'Verifica tu conexión y que el servidor esté activo.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        onPressed: () => _controller.reload(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
