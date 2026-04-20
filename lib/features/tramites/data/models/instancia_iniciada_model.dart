import '../../domain/entities/instancia_iniciada.dart';

class InstanciaIniciadaModel {
  const InstanciaIniciadaModel({
    required this.id,
    required this.politicaId,
    required this.codigoTramite,
    required this.estadoInstancia,
  });

  final String id;
  final String politicaId;
  final String codigoTramite;
  final String estadoInstancia;

  factory InstanciaIniciadaModel.fromJson(Map<String, dynamic> json) {
    return InstanciaIniciadaModel(
      id: json['id'] as String? ?? '',
      politicaId: json['politicaId'] as String? ?? '',
      codigoTramite: json['codigoTramite'] as String? ?? '',
      estadoInstancia: json['estadoInstancia'] as String? ?? '',
    );
  }

  InstanciaIniciada toEntity() {
    return InstanciaIniciada(
      id: id,
      politicaId: politicaId,
      codigoTramite: codigoTramite,
      estadoInstancia: estadoInstancia,
    );
  }
}
