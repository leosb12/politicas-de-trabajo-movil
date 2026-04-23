class TramiteDisponible {
  const TramiteDisponible({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipoPolitica,
    required this.departamentoInicioId,
    required this.departamentoInicioNombre,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String tipoPolitica;
  final String? departamentoInicioId;
  final String? departamentoInicioNombre;
}
