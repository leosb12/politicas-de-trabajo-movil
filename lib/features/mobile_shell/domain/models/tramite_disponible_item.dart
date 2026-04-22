class TramiteDisponibleItem {
  const TramiteDisponibleItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    this.iniciado = false,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final bool iniciado;

  TramiteDisponibleItem copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? categoria,
    bool? iniciado,
  }) {
    return TramiteDisponibleItem(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      iniciado: iniciado ?? this.iniciado,
    );
  }
}